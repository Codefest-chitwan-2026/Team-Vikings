from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from donations.models import Donation, PickupTicket
from users.models import User

from .models import ClaimHold, PickupQRMetadata, FlashSaleConversion
from .serializers import (
    DonationDetailSerializer,
    ClaimHoldSerializer,
    ClaimHoldCreateSerializer,
    ConfirmClaimSerializer,
    PickupQRSerializer,
    VerifyPickupSerializer,
    ListingUpdateSerializer,
    AdjustPriceSerializer,
    ListingDetailWriteSerializer,
    FlashSaleConversionSerializer,
)
from .services import (
    get_or_create_listing_detail,
    process_priority_expiry,
    create_claim_hold,
    confirm_claim_hold,
    verify_pickup_code,
    priority_seconds_remaining,
    apply_auto_discount,
)


class ListingFlowViewSet(viewsets.ViewSet):

    permission_classes = [IsAuthenticated]

    def _get_donation(self, pk):
        return get_object_or_404(Donation.objects.select_related("donor"), pk=pk)

    @action(detail=True, methods=["get"], url_path="detail")
    def donation_detail(self, request, pk=None):

        donation = self._get_donation(pk)
        get_or_create_listing_detail(donation)
        process_priority_expiry(donation)
        donation.refresh_from_db()

        serializer = DonationDetailSerializer(
            donation,
            context={"request": request},
        )
        return Response(serializer.data)

    @action(detail=True, methods=["get", "put", "patch"], url_path="listing-detail")
    def listing_detail(self, request, pk=None):

        donation = self._get_donation(pk)

        if request.user.role != "BUSINESS" or donation.donor != request.user:
            return Response(
                {"error": "Only the donor can update listing details"},
                status=status.HTTP_403_FORBIDDEN,
            )

        detail = get_or_create_listing_detail(donation)

        if request.method == "GET":
            serializer = ListingDetailWriteSerializer(detail)
            return Response(serializer.data)

        serializer = ListingDetailWriteSerializer(
            detail,
            data=request.data,
            partial=request.method == "PATCH",
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)

    @action(detail=True, methods=["get"], url_path="listing-update")
    def listing_update(self, request, pk=None):

        donation = self._get_donation(pk)
        conversion = process_priority_expiry(donation)
        donation.refresh_from_db()
        detail = get_or_create_listing_detail(donation)

        priority_closed = (
            donation.listing_type == "DONATION"
            and donation.ngo_priority_expires_at
            and timezone.now() >= donation.ngo_priority_expires_at
        ) or donation.listing_type == "FLASH_SALE"

        if not conversion and donation.listing_type == "FLASH_SALE":
            conversion = FlashSaleConversion.objects.filter(
                donation=donation
            ).first()

        data = {
            "priority_window_closed": priority_closed,
            "priority_seconds_remaining": priority_seconds_remaining(donation),
            "donation": DonationDetailSerializer(
                donation,
                context={"request": request},
            ).data,
            "flash_sale_conversion": (
                FlashSaleConversionSerializer(conversion).data
                if conversion
                else None
            ),
            "can_adjust_price": donation.donor == request.user,
            "can_keep_donation_only": donation.donor == request.user,
        }

        return Response(data)

    @action(detail=True, methods=["post"], url_path="adjust-price")
    def adjust_price(self, request, pk=None):

        donation = self._get_donation(pk)

        if donation.donor != request.user:
            return Response(
                {"error": "Only the donor can adjust price"},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = AdjustPriceSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        donation.flash_sale_price = serializer.validated_data["flash_sale_price"]

        if donation.listing_type == "DONATION" and donation.status == "AVAILABLE":
            donation.convert_to_flash_sale()

        donation.save(update_fields=["flash_sale_price", "updated_at"])

        detail = get_or_create_listing_detail(donation)
        conversion = FlashSaleConversion.objects.update_or_create(
            donation=donation,
            defaults={
                "conversion_type": "MANUAL",
                "estimated_recovery": detail.estimated_recovery(),
                "visibility_radius_km": detail.visibility_radius_km,
            },
        )[0]

        return Response(
            {
                "message": "Flash sale price updated",
                "donation": DonationDetailSerializer(
                    donation,
                    context={"request": request},
                ).data,
                "flash_sale_conversion": FlashSaleConversionSerializer(
                    conversion
                ).data,
            }
        )

    @action(detail=True, methods=["post"], url_path="keep-donation-only")
    def keep_donation_only(self, request, pk=None):

        donation = self._get_donation(pk)

        if donation.donor != request.user:
            return Response(
                {"error": "Only the donor can update this listing"},
                status=status.HTTP_403_FORBIDDEN,
            )

        donation.status = "EXPIRED"
        donation.save(update_fields=["status", "updated_at"])

        detail = get_or_create_listing_detail(donation)
        conversion = FlashSaleConversion.objects.create(
            donation=donation,
            conversion_type="DONATION_ONLY",
            visibility_radius_km=detail.visibility_radius_km,
        )

        return Response(
            {
                "message": "Listing kept as donation-only and closed",
                "flash_sale_conversion": FlashSaleConversionSerializer(
                    conversion
                ).data,
            }
        )

    @action(detail=True, methods=["post"], url_path="process-priority-expiry")
    def process_priority_expiry_action(self, request, pk=None):

        donation = self._get_donation(pk)
        conversion = process_priority_expiry(donation)
        donation.refresh_from_db()

        return Response(
            {
                "message": "Priority window processed",
                "donation_status": donation.status,
                "listing_type": donation.listing_type,
                "flash_sale_conversion": (
                    FlashSaleConversionSerializer(conversion).data
                    if conversion
                    else None
                ),
            }
        )


class ClaimHoldViewSet(viewsets.ViewSet):

    permission_classes = [IsAuthenticated]

    def list(self, request):

        if request.user.role != "NGO":
            return Response(
                {"error": "Only NGO users can view claim holds"},
                status=status.HTTP_403_FORBIDDEN,
            )

        holds = ClaimHold.objects.filter(ngo=request.user).select_related(
            "donation"
        )
        for hold in holds:
            hold.expire_if_needed()

        active = holds.filter(status="ACTIVE", expires_at__gt=timezone.now())
        serializer = ClaimHoldSerializer(active, many=True)
        return Response(serializer.data)

    def create(self, request):

        if request.user.role != "NGO":
            return Response(
                {"error": "Only NGO users can start a claim hold"},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = ClaimHoldCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        donation = get_object_or_404(
            Donation,
            pk=serializer.validated_data["donation_id"],
        )

        if not donation.is_ngo_priority_active():
            return Response(
                {"error": "NGO priority window has expired"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if donation.status != "AVAILABLE":
            return Response(
                {"error": "This donation is no longer available"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        hold = create_claim_hold(donation, request.user)
        return Response(
            {
                "message": "Claim held for you",
                "hold": ClaimHoldSerializer(hold).data,
            },
            status=status.HTTP_201_CREATED,
        )

    @action(detail=True, methods=["post"])
    def confirm(self, request, pk=None):

        if request.user.role != "NGO":
            return Response(
                {"error": "Only NGO users can confirm claims"},
                status=status.HTTP_403_FORBIDDEN,
            )

        hold = get_object_or_404(ClaimHold, pk=pk)
        serializer = ConfirmClaimSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        volunteer = None
        volunteer_id = serializer.validated_data.get("volunteer_id")
        if volunteer_id:
            volunteer = get_object_or_404(User, pk=volunteer_id)

        try:
            claim, confirmation, ticket, qr_metadata = confirm_claim_hold(
                hold,
                {
                    **serializer.validated_data,
                    "volunteer": volunteer,
                },
                request.user,
            )
        except ValueError as exc:
            return Response({"error": str(exc)}, status=status.HTTP_400_BAD_REQUEST)

        return Response(
            {
                "message": "Donation claimed successfully",
                "claim_id": claim.id,
                "claim_reference": qr_metadata.claim_reference,
                "qr_code": ticket.qr_code,
                "manual_code": qr_metadata.manual_code,
                "expires_at": qr_metadata.expires_at,
            },
            status=status.HTTP_201_CREATED,
        )

    @action(detail=True, methods=["post"])
    def cancel(self, request, pk=None):

        hold = get_object_or_404(ClaimHold, pk=pk)

        if hold.ngo != request.user:
            return Response(
                {"error": "You can only cancel your own holds"},
                status=status.HTTP_403_FORBIDDEN,
            )

        hold.status = "CANCELLED"
        hold.save(update_fields=["status"])

        return Response({"message": "Claim hold cancelled"})


class PickupQRViewSet(viewsets.ViewSet):

    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=["get"], url_path="by-claim/(?P<claim_id>[0-9]+)")
    def by_claim(self, request, claim_id=None):

        ticket = get_object_or_404(
            PickupTicket.objects.select_related(
                "donation",
                "claim",
                "claim__ngo",
            ),
            claim_id=claim_id,
        )

        if ticket.claim and ticket.claim.ngo != request.user:
            if request.user.role != "BUSINESS":
                return Response(
                    {"error": "Not allowed to view this QR"},
                    status=status.HTTP_403_FORBIDDEN,
                )
            if ticket.donation.donor != request.user:
                return Response(
                    {"error": "Not allowed to view this QR"},
                    status=status.HTTP_403_FORBIDDEN,
                )

        return Response(self._build_qr_payload(ticket))

    @action(detail=False, methods=["get"], url_path="by-ticket/(?P<ticket_id>[0-9]+)")
    def by_ticket(self, request, ticket_id=None):

        ticket = get_object_or_404(
            PickupTicket.objects.select_related(
                "donation",
                "claim",
                "claim__ngo",
            ),
            pk=ticket_id,
        )
        return Response(self._build_qr_payload(ticket))

    def _build_qr_payload(self, ticket):

        donation = ticket.donation
        detail = get_or_create_listing_detail(donation)
        metadata = getattr(ticket, "qr_metadata", None)

        if not metadata:
            metadata = PickupQRMetadata.objects.create(
                ticket=ticket,
                expires_at=detail.pickup_window_end or donation.best_before,
            )

        claimed_by = None
        if ticket.claim:
            profile = getattr(ticket.claim.ngo, "ngo_profile", None)
            claimed_by = (
                profile.organization_name if profile else ticket.claim.ngo.phone_num
            )

        contact = ""
        if detail.contact_name and detail.contact_phone:
            contact = f"{detail.contact_name} · {detail.contact_phone}"
        elif detail.contact_name:
            contact = detail.contact_name
        elif detail.contact_phone:
            contact = detail.contact_phone

        pickup_window = ""
        if detail.pickup_window_start and detail.pickup_window_end:
            pickup_window = (
                f"{detail.pickup_window_start.strftime('%I:%M %p')} – "
                f"{detail.pickup_window_end.strftime('%I:%M %p')}"
            )

        food_summary = (
            f"{donation.title} · {donation.people_served} servings"
        )

        data = {
            "claim_reference": metadata.claim_reference,
            "qr_code": ticket.qr_code,
            "manual_code": metadata.manual_code,
            "expires_at": metadata.expires_at,
            "is_expired": metadata.is_expired(),
            "ticket_type": ticket.ticket_type,
            "food_summary": food_summary,
            "claimed_by": claimed_by,
            "pickup_window": pickup_window,
            "address": donation.pickup_address,
            "contact": contact,
            "donation_id": donation.id,
        }

        return PickupQRSerializer(data).data


class VerifyPickupViewSet(viewsets.ViewSet):

    permission_classes = [IsAuthenticated]

    def create(self, request):

        if request.user.role != "BUSINESS":
            return Response(
                {"error": "Only business users can verify pickups"},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = VerifyPickupSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            ticket = verify_pickup_code(
                qr_code=serializer.validated_data.get("qr_code"),
                manual_code=serializer.validated_data.get("manual_code"),
                verified_by=request.user,
            )
        except PickupTicket.DoesNotExist:
            return Response(
                {"error": "Invalid QR code"},
                status=status.HTTP_404_NOT_FOUND,
            )
        except PickupQRMetadata.DoesNotExist:
            return Response(
                {"error": "Invalid manual code"},
                status=status.HTTP_404_NOT_FOUND,
            )
        except ValueError as exc:
            return Response({"error": str(exc)}, status=status.HTTP_400_BAD_REQUEST)

        donation = ticket.donation
        metadata = getattr(ticket, "qr_metadata", None)

        return Response(
            {
                "message": "Pickup verified successfully",
                "claim_reference": metadata.claim_reference if metadata else None,
                "donation": DonationDetailSerializer(
                    donation,
                    context={"request": request},
                ).data,
            }
        )

    @action(detail=False, methods=["get"], url_path="expected/(?P<code>[^/.]+)")
    def expected(self, request, code=None):

        if request.user.role != "BUSINESS":
            return Response(
                {"error": "Only business users can preview expected pickups"},
                status=status.HTTP_403_FORBIDDEN,
            )

        ticket = PickupTicket.objects.select_related(
            "donation",
            "claim",
            "claim__ngo",
        ).filter(qr_code=code).first()

        metadata = None
        if not ticket:
            metadata = PickupQRMetadata.objects.select_related(
                "ticket",
                "ticket__donation",
                "ticket__claim",
                "ticket__claim__ngo",
            ).filter(manual_code=code.upper()).first()
            ticket = metadata.ticket if metadata else None

        if not ticket:
            return Response(
                {"error": "Invalid code"},
                status=status.HTTP_404_NOT_FOUND,
            )

        if ticket.donation.donor != request.user:
            return Response(
                {"error": "This pickup is not for your listing"},
                status=status.HTTP_403_FORBIDDEN,
            )

        qr_view = PickupQRViewSet()
        return Response(qr_view._build_qr_payload(ticket))
