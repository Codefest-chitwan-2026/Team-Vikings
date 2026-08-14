from decimal import Decimal
from math import radians, cos, sin, asin, sqrt

from django.utils import timezone
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.response import Response

from .models import (
    Donation,
    DonationClaim,
    ConsumerReservation,
    PickupTicket,
)
from .serializers import (
    DonationSerializer,
    DonationClaimSerializer,
    ConsumerReservationSerializer,
    DonationClaimCreateSerializer,
    ConsumerReservationCreateSerializer,
    VerifyPickupSerializer,
    ConvertToFlashSaleSerializer,
)


def haversine_km(lat1, lon1, lat2, lon2):
    lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    a = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlon / 2) ** 2
    return 2 * asin(sqrt(a)) * 6371


def _create_qr_metadata_if_possible(ticket, donation):
    try:
        from listing_flow.models import PickupQRMetadata
        from listing_flow.services import get_or_create_listing_detail
        detail = get_or_create_listing_detail(donation)
        qr_expires = detail.pickup_window_end or donation.best_before
        PickupQRMetadata.objects.get_or_create(
            ticket=ticket,
            defaults={"expires_at": qr_expires},
        )
    except Exception:
        pass


class DonationViewSet(viewsets.ModelViewSet):

    queryset = Donation.objects.all()
    serializer_class = DonationSerializer
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        queryset = Donation.objects.select_related(
            "donor",
            "claim",
            "claim__ngo",
        )

        if user.is_staff:
            base_qs = queryset
        elif user.role and user.role.upper() == "BUSINESS":
            base_qs = queryset.filter(donor=user)
        elif user.role and user.role.upper() == "NGO":
            base_qs = queryset.filter(
                listing_type="DONATION",
                status="AVAILABLE",
                ngo_priority_expires_at__gt=timezone.now(),
            )
        else:
            base_qs = queryset.filter(
                listing_type="FLASH_SALE",
                status="AVAILABLE",
            )

        food_type = self.request.query_params.get("food_type")
        if food_type:
            base_qs = base_qs.filter(food_type=food_type.upper())

        listing_type = self.request.query_params.get("listing_type")
        if listing_type:
            base_qs = base_qs.filter(listing_type=listing_type.upper())

        status_param = self.request.query_params.get("status")
        if status_param:
            base_qs = base_qs.filter(status=status_param.upper())

        lat = self.request.query_params.get("latitude")
        lng = self.request.query_params.get("longitude")
        radius = self.request.query_params.get("radius_km")

        if lat and lng and radius:
            try:
                lat_f = float(lat)
                lng_f = float(lng)
                radius_f = float(radius)
                filtered_ids = []

                for donation in base_qs:
                    if donation.latitude is None or donation.longitude is None:
                        continue
                    distance = haversine_km(
                        lat_f,
                        lng_f,
                        float(donation.latitude),
                        float(donation.longitude),
                    )
                    if distance <= radius_f:
                        filtered_ids.append(donation.id)

                return base_qs.filter(id__in=filtered_ids)
            except (ValueError, TypeError):
                pass

        return base_qs

    def create(self, request, *args, **kwargs):
        is_business = request.user.role and request.user.role.upper() == "BUSINESS"
        if not (request.user.is_staff or is_business):
            return Response(
                {"error": "Only business users can create donations"},
                status=status.HTTP_403_FORBIDDEN,
            )

        return super().create(request, *args, **kwargs)

    def perform_create(self, serializer):
        user = self.request.user
        business_profile = getattr(user, "business_profile", None)

        latitude = serializer.validated_data.get("latitude")
        longitude = serializer.validated_data.get("longitude")

        if latitude is None and business_profile and business_profile.latitude:
            try:
                latitude = Decimal(str(business_profile.latitude).strip())
            except Exception:
                latitude = None

        if longitude is None and business_profile and business_profile.longitude:
            try:
                longitude = Decimal(str(business_profile.longitude).strip())
            except Exception:
                longitude = None

        pickup_address = serializer.validated_data.get("pickup_address")
        if not pickup_address and business_profile and business_profile.address:
            pickup_address = business_profile.address
        elif not pickup_address:
            pickup_address = "Kathmandu"

        donor = user
        if user.is_staff and "donor" in serializer.validated_data:
            donor = serializer.validated_data["donor"]

        serializer.save(
            donor=donor,
            latitude=latitude,
            longitude=longitude,
            pickup_address=pickup_address,
        )

    def check_object_permissions(self, request, obj):
        super().check_object_permissions(request, obj)

        if self.action in ["update", "partial_update", "destroy", "cancel"]:
            if obj.donor != request.user and not request.user.is_staff:
                self.permission_denied(
                    request,
                    message="You can only modify your own donations",
                )

    @action(detail=False, methods=["get"])
    def ngo_priority(self, request):
        is_ngo = request.user.role and request.user.role.upper() == "NGO"
        if not (request.user.is_staff or is_ngo):
            return Response(
                {"error": "Only NGO users can access priority listings"},
                status=status.HTTP_403_FORBIDDEN,
            )

        donations = Donation.objects.filter(
            listing_type="DONATION",
            status="AVAILABLE",
            ngo_priority_expires_at__gt=timezone.now(),
        )

        for donation in donations:
            donation.check_priority_expired()

        donations = Donation.objects.filter(
            listing_type="DONATION",
            status="AVAILABLE",
            ngo_priority_expires_at__gt=timezone.now(),
        )

        serializer = self.get_serializer(donations, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=["get"])
    def flash_sales(self, request):
        donations = Donation.objects.filter(
            listing_type="FLASH_SALE",
            status="AVAILABLE",
        )

        serializer = self.get_serializer(donations, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=["post"])
    def claim(self, request, pk=None):
        is_ngo = request.user.role and request.user.role.upper() == "NGO"
        if not (request.user.is_staff or is_ngo):
            return Response(
                {"error": "Only NGO users can claim donations"},
                status=status.HTTP_403_FORBIDDEN,
            )

        donation = self.get_object()
        donation.check_priority_expired()

        if donation.listing_type != "DONATION":
            return Response(
                {"error": "Only donation listings can be claimed by NGOs"},
                status=status.HTTP_400_BAD_REQUEST,
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

        if DonationClaim.objects.filter(donation=donation).exists():
            return Response(
                {"error": "This donation has already been claimed"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        serializer = DonationClaimCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        claim = DonationClaim.objects.create(
            donation=donation,
            ngo=request.user,
            pickup_method=serializer.validated_data["pickup_method"],
            status="CONFIRMED",
        )

        donation.status = "CLAIMED"
        donation.save(update_fields=["status", "updated_at"])

        pickup_ticket = PickupTicket.objects.create(
            donation=donation,
            ticket_type="NGO_CLAIM",
            claim=claim,
        )

        _create_qr_metadata_if_possible(pickup_ticket, donation)

        claim_data = DonationClaimSerializer(claim).data
        claim_data["pickup_ticket"] = {
            "qr_code": pickup_ticket.qr_code,
            "id": pickup_ticket.id,
        }

        return Response(
            {
                "message": "Donation claimed successfully",
                "claim": claim_data,
            },
            status=status.HTTP_201_CREATED,
        )

    @action(detail=True, methods=["post"])
    def reserve(self, request, pk=None):
        is_customer = request.user.role and request.user.role.upper() == "CUSTOMER"
        if not (request.user.is_staff or is_customer):
            return Response(
                {"error": "Only consumers can reserve flash sales"},
                status=status.HTTP_403_FORBIDDEN,
            )

        donation = self.get_object()

        if donation.listing_type != "FLASH_SALE":
            return Response(
                {"error": "Only flash sale listings can be reserved"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if donation.status != "AVAILABLE":
            return Response(
                {"error": "This listing is no longer available"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if ConsumerReservation.objects.filter(
            donation=donation,
            consumer=request.user,
        ).exists():
            return Response(
                {"error": "You have already reserved this listing"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        reservation = ConsumerReservation.objects.create(
            donation=donation,
            consumer=request.user,
            status="CONFIRMED",
        )

        donation.status = "RESERVED"
        donation.save(update_fields=["status", "updated_at"])

        pickup_ticket = PickupTicket.objects.create(
            donation=donation,
            ticket_type="CONSUMER_RESERVATION",
            reservation=reservation,
        )

        _create_qr_metadata_if_possible(pickup_ticket, donation)

        reservation_data = ConsumerReservationSerializer(reservation).data
        reservation_data["pickup_ticket"] = {
            "qr_code": pickup_ticket.qr_code,
            "id": pickup_ticket.id,
        }

        return Response(
            {
                "message": "Flash sale reserved successfully",
                "reservation": reservation_data,
            },
            status=status.HTTP_201_CREATED,
        )

    @action(detail=True, methods=["post"])
    def convert_to_flash_sale(self, request, pk=None):
        donation = self.get_object()

        if donation.donor != request.user and not request.user.is_staff:
            return Response(
                {"error": "Only the donor can convert this listing"},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = ConvertToFlashSaleSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        flash_sale_price = serializer.validated_data.get("flash_sale_price")
        if flash_sale_price:
            donation.flash_sale_price = flash_sale_price

        try:
            donation.convert_to_flash_sale()
        except ValueError as exc:
            return Response(
                {"error": str(exc)},
                status=status.HTTP_400_BAD_REQUEST,
            )

        return Response(
            {
                "message": "Listing converted to flash sale",
                "donation": DonationSerializer(donation).data,
            },
            status=status.HTTP_200_OK,
        )

    @action(detail=True, methods=["post"])
    def cancel(self, request, pk=None):
        donation = self.get_object()

        if donation.status in ["COMPLETED", "PICKED_UP", "CANCELLED"]:
            return Response(
                {"error": "This donation cannot be cancelled"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        donation.status = "CANCELLED"
        donation.save(update_fields=["status", "updated_at"])

        claim = DonationClaim.objects.filter(donation=donation).first()
        if claim:
            claim.status = "CANCELLED"
            claim.save(update_fields=["status"])

        donation.reservations.update(status="CANCELLED")

        return Response(
            {
                "message": "Donation cancelled successfully",
                "donation": DonationSerializer(donation).data,
            },
            status=status.HTTP_200_OK,
        )

    @action(detail=False, methods=["post"])
    def verify_pickup(self, request):
        is_business = request.user.role and request.user.role.upper() == "BUSINESS"
        if not (request.user.is_staff or is_business):
            return Response(
                {"error": "Only business users can verify pickups"},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = VerifyPickupSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        qr_code = serializer.validated_data.get("qr_code")
        manual_code = serializer.validated_data.get("manual_code")

        ticket = None
        if qr_code:
            ticket = PickupTicket.objects.select_related(
                "donation",
                "claim",
                "reservation",
            ).filter(qr_code=qr_code).first()

        if not ticket and manual_code:
            try:
                from listing_flow.models import PickupQRMetadata
                meta = PickupQRMetadata.objects.select_related(
                    "ticket",
                    "ticket__donation",
                    "ticket__claim",
                    "ticket__reservation",
                ).filter(manual_code=manual_code.upper()).first()
                if meta:
                    ticket = meta.ticket
            except ImportError:
                pass

        if not ticket:
            return Response(
                {"error": "Invalid QR code or manual code"},
                status=status.HTTP_404_NOT_FOUND,
            )

        if ticket.donation.donor != request.user and not request.user.is_staff:
            return Response(
                {"error": "You can only verify pickups for your own donations"},
                status=status.HTTP_403_FORBIDDEN,
            )

        if ticket.is_verified:
            return Response(
                {"error": "This pickup has already been verified"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        ticket.is_verified = True
        ticket.verified_at = timezone.now()
        ticket.verified_by = request.user
        ticket.save(
            update_fields=["is_verified", "verified_at", "verified_by"]
        )

        donation = ticket.donation
        donation.status = "PICKED_UP"
        donation.save(update_fields=["status", "updated_at"])

        if ticket.claim:
            ticket.claim.status = "PICKED_UP"
            ticket.claim.save(update_fields=["status"])

        if ticket.reservation:
            ticket.reservation.status = "PICKED_UP"
            ticket.reservation.save(update_fields=["status"])

        return Response(
            {
                "message": "Pickup verified successfully",
                "ticket": {
                    "qr_code": ticket.qr_code,
                    "ticket_type": ticket.ticket_type,
                    "verified_at": ticket.verified_at,
                },
                "donation": DonationSerializer(donation).data,
            },
            status=status.HTTP_200_OK,
        )


class DonationClaimViewSet(viewsets.ModelViewSet):

    queryset = DonationClaim.objects.all()
    serializer_class = DonationClaimSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user

        if user.is_staff:
            return DonationClaim.objects.select_related(
                "donation",
                "ngo",
                "pickup_ticket",
            )

        if user.role and user.role.upper() == "NGO":
            return DonationClaim.objects.filter(ngo=user).select_related(
                "donation",
                "ngo",
                "pickup_ticket",
            )

        if user.role and user.role.upper() == "BUSINESS":
            return DonationClaim.objects.filter(
                donation__donor=user
            ).select_related(
                "donation",
                "ngo",
                "pickup_ticket",
            )

        return DonationClaim.objects.none()

    def create(self, request, *args, **kwargs):
        is_ngo = request.user.role and request.user.role.upper() == "NGO"
        if not (request.user.is_staff or is_ngo):
            return Response(
                {"error": "Only NGO users can claim donations"},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = DonationClaimCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        donation = serializer.validated_data.get("donation")
        if not donation:
            return Response(
                {"error": "donation or donation_id is required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        donation.check_priority_expired()

        if donation.listing_type != "DONATION":
            return Response(
                {"error": "Only donation listings can be claimed by NGOs"},
                status=status.HTTP_400_BAD_REQUEST,
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

        if DonationClaim.objects.filter(donation=donation).exists():
            return Response(
                {"error": "This donation has already been claimed"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        pickup_method = serializer.validated_data.get("pickup_method", "SELF")
        claim = DonationClaim.objects.create(
            donation=donation,
            ngo=request.user,
            pickup_method=pickup_method,
            status="CONFIRMED",
        )

        donation.status = "CLAIMED"
        donation.save(update_fields=["status", "updated_at"])

        pickup_ticket = PickupTicket.objects.create(
            donation=donation,
            ticket_type="NGO_CLAIM",
            claim=claim,
        )

        _create_qr_metadata_if_possible(pickup_ticket, donation)

        claim_data = DonationClaimSerializer(claim).data
        claim_data["pickup_ticket"] = {
            "qr_code": pickup_ticket.qr_code,
            "id": pickup_ticket.id,
        }

        return Response(
            {
                "message": "Donation claimed successfully",
                "claim": claim_data,
            },
            status=status.HTTP_201_CREATED,
        )


class ConsumerReservationViewSet(viewsets.ModelViewSet):

    queryset = ConsumerReservation.objects.all()
    serializer_class = ConsumerReservationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user

        if user.is_staff:
            return ConsumerReservation.objects.select_related(
                "donation",
                "consumer",
                "pickup_ticket",
            )

        if user.role and user.role.upper() == "CUSTOMER":
            return ConsumerReservation.objects.filter(
                consumer=user
            ).select_related(
                "donation",
                "consumer",
                "pickup_ticket",
            )

        if user.role and user.role.upper() == "BUSINESS":
            return ConsumerReservation.objects.filter(
                donation__donor=user
            ).select_related(
                "donation",
                "consumer",
                "pickup_ticket",
            )

        return ConsumerReservation.objects.none()

    def create(self, request, *args, **kwargs):
        is_customer = request.user.role and request.user.role.upper() == "CUSTOMER"
        if not (request.user.is_staff or is_customer):
            return Response(
                {"error": "Only consumers can reserve flash sales"},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = ConsumerReservationCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        donation = serializer.validated_data.get("donation")
        if not donation:
            return Response(
                {"error": "donation or donation_id is required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if donation.listing_type != "FLASH_SALE":
            return Response(
                {"error": "Only flash sale listings can be reserved"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if donation.status != "AVAILABLE":
            return Response(
                {"error": "This listing is no longer available"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if ConsumerReservation.objects.filter(
            donation=donation,
            consumer=request.user,
        ).exists():
            return Response(
                {"error": "You have already reserved this listing"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        reservation = ConsumerReservation.objects.create(
            donation=donation,
            consumer=request.user,
            status="CONFIRMED",
        )

        donation.status = "RESERVED"
        donation.save(update_fields=["status", "updated_at"])

        pickup_ticket = PickupTicket.objects.create(
            donation=donation,
            ticket_type="CONSUMER_RESERVATION",
            reservation=reservation,
        )

        _create_qr_metadata_if_possible(pickup_ticket, donation)

        reservation_data = ConsumerReservationSerializer(reservation).data
        reservation_data["pickup_ticket"] = {
            "qr_code": pickup_ticket.qr_code,
            "id": pickup_ticket.id,
        }

        return Response(
            {
                "message": "Flash sale reserved successfully",
                "reservation": reservation_data,
            },
            status=status.HTTP_201_CREATED,
        )

