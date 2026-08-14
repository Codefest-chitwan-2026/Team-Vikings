from decimal import Decimal

from django.utils import timezone

from donations.models import Donation, DonationClaim, PickupTicket

from .models import (
    ListingDetail,
    ClaimHold,
    ClaimConfirmation,
    PickupQRMetadata,
    FlashSaleConversion,
)


def haversine_km(lat1, lon1, lat2, lon2):
    from math import radians, cos, sin, asin, sqrt

    lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    a = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlon / 2) ** 2
    return 2 * asin(sqrt(a)) * 6371


def get_or_create_listing_detail(donation):
    detail, _ = ListingDetail.objects.get_or_create(donation=donation)
    return detail


def priority_seconds_remaining(donation):
    if not donation.ngo_priority_expires_at:
        return 0
    return max(
        0,
        int((donation.ngo_priority_expires_at - timezone.now()).total_seconds()),
    )


def apply_auto_discount(donation, listing_detail):
    if not donation.price:
        return None

    discount = listing_detail.auto_discount_percent
    discounted = donation.price * (1 - discount / Decimal("100"))
    donation.flash_sale_price = discounted.quantize(Decimal("0.01"))
    donation.save(update_fields=["flash_sale_price", "updated_at"])
    return discount


def process_priority_expiry(donation):
    if donation.listing_type != "DONATION" or donation.status != "AVAILABLE":
        return FlashSaleConversion.objects.filter(donation=donation).first()

    if not donation.ngo_priority_expires_at:
        return None

    if timezone.now() < donation.ngo_priority_expires_at:
        return None

    listing_detail = get_or_create_listing_detail(donation)

    if donation.flash_sale_price or donation.price:
        if not donation.flash_sale_price and donation.price:
            apply_auto_discount(donation, listing_detail)
        donation.convert_to_flash_sale()
        return FlashSaleConversion.objects.create(
            donation=donation,
            conversion_type="AUTO",
            discount_percent=listing_detail.auto_discount_percent,
            estimated_recovery=listing_detail.estimated_recovery(),
            visibility_radius_km=listing_detail.visibility_radius_km,
        )

    donation.status = "EXPIRED"
    donation.save(update_fields=["status", "updated_at"])
    return FlashSaleConversion.objects.create(
        donation=donation,
        conversion_type="DONATION_ONLY",
        visibility_radius_km=listing_detail.visibility_radius_km,
    )


def create_claim_hold(donation, ngo):
    ClaimHold.objects.filter(
        donation=donation,
        status="ACTIVE",
    ).update(status="CANCELLED")

    return ClaimHold.objects.create(
        donation=donation,
        ngo=ngo,
    )


def confirm_claim_hold(hold, data, ngo):
    hold.expire_if_needed()

    if not hold.is_active():
        raise ValueError("Claim hold has expired. Please start again.")

    if hold.ngo != ngo:
        raise ValueError("This hold belongs to another NGO.")

    donation = hold.donation

    if donation.status != "AVAILABLE":
        raise ValueError("This donation is no longer available.")

    if DonationClaim.objects.filter(donation=donation).exists():
        raise ValueError("This donation has already been claimed.")

    pickup_method = data["pickup_method"]
    claim_method_map = {
        "OWN_VAN": "SELF",
        "VOLUNTEER": "VOLUNTEER",
        "DELIVERY_BETA": "VOLUNTEER",
    }

    claim = DonationClaim.objects.create(
        donation=donation,
        ngo=ngo,
        pickup_method=claim_method_map.get(pickup_method, "SELF"),
        status="CONFIRMED",
    )

    confirmation = ClaimConfirmation.objects.create(
        claim=claim,
        hold=hold,
        pickup_method=pickup_method,
        scheduled_pickup_start=data["scheduled_pickup_start"],
        scheduled_pickup_end=data["scheduled_pickup_end"],
        people_served_confirmed=data["people_served_confirmed"],
        donor_note=data.get("donor_note", ""),
        volunteer=data.get("volunteer"),
    )

    ticket = PickupTicket.objects.create(
        donation=donation,
        ticket_type="NGO_CLAIM",
        claim=claim,
    )

    listing_detail = get_or_create_listing_detail(donation)
    qr_expires = listing_detail.pickup_window_end or donation.best_before

    qr_metadata = PickupQRMetadata.objects.create(
        ticket=ticket,
        expires_at=qr_expires,
    )

    donation.status = "CLAIMED"
    donation.save(update_fields=["status", "updated_at"])

    hold.status = "COMPLETED"
    hold.save(update_fields=["status"])

    return claim, confirmation, ticket, qr_metadata


def verify_pickup_code(qr_code=None, manual_code=None, verified_by=None):
    if qr_code:
        ticket = PickupTicket.objects.select_related("donation").get(
            qr_code=qr_code
        )
    elif manual_code:
        metadata = PickupQRMetadata.objects.select_related(
            "ticket",
            "ticket__donation",
        ).get(manual_code=manual_code.upper())
        ticket = metadata.ticket
    else:
        raise ValueError("QR code or manual code is required.")

    if ticket.is_verified:
        raise ValueError("This pickup has already been verified.")

    metadata = getattr(ticket, "qr_metadata", None)
    if metadata and metadata.is_expired():
        raise ValueError("This pickup code has expired.")

    ticket.is_verified = True
    ticket.verified_at = timezone.now()
    ticket.verified_by = verified_by
    ticket.save(update_fields=["is_verified", "verified_at", "verified_by"])

    donation = ticket.donation
    donation.status = "PICKED_UP"
    donation.save(update_fields=["status", "updated_at"])

    if ticket.claim:
        ticket.claim.status = "PICKED_UP"
        ticket.claim.save(update_fields=["status"])

    if ticket.reservation:
        ticket.reservation.status = "PICKED_UP"
        ticket.reservation.save(update_fields=["status"])

    return ticket
