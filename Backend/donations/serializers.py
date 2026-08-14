from datetime import timedelta
from decimal import Decimal
from django.utils import timezone
from rest_framework import serializers

from .models import (
    Donation,
    DonationClaim,
    ConsumerReservation,
    PickupTicket,
    default_ngo_priority_duration,
)

try:
    from listing_flow.models import ListingDetail
except ImportError:
    ListingDetail = None


class PickupTicketSerializer(serializers.ModelSerializer):

    class Meta:
        model = PickupTicket
        fields = [
            "id",
            "donation",
            "ticket_type",
            "qr_code",
            "is_verified",
            "verified_at",
            "verified_by",
            "created_at",
        ]
        read_only_fields = fields


class DonationClaimSerializer(serializers.ModelSerializer):

    pickup_ticket = PickupTicketSerializer(read_only=True)
    ngo_name = serializers.SerializerMethodField()

    class Meta:
        model = DonationClaim
        fields = [
            "id",
            "donation",
            "ngo",
            "ngo_name",
            "pickup_method",
            "status",
            "claimed_at",
            "pickup_ticket",
        ]
        read_only_fields = [
            "id",
            "donation",
            "ngo",
            "status",
            "claimed_at",
            "pickup_ticket",
        ]

    def get_ngo_name(self, obj):
        profile = getattr(obj.ngo, "ngo_profile", None)
        if profile:
            return profile.organization_name
        return None


class ConsumerReservationSerializer(serializers.ModelSerializer):

    pickup_ticket = PickupTicketSerializer(read_only=True)
    consumer_name = serializers.SerializerMethodField()

    class Meta:
        model = ConsumerReservation
        fields = [
            "id",
            "donation",
            "consumer",
            "consumer_name",
            "status",
            "reserved_at",
            "pickup_ticket",
        ]
        read_only_fields = [
            "id",
            "donation",
            "consumer",
            "status",
            "reserved_at",
            "pickup_ticket",
        ]

    def get_consumer_name(self, obj):
        profile = getattr(obj.consumer, "customer_profile", None)
        if profile:
            return profile.full_name
        return None


class DonationSerializer(serializers.ModelSerializer):

    claim = DonationClaimSerializer(read_only=True)
    ngo_priority_active = serializers.SerializerMethodField()
    donor_business_name = serializers.SerializerMethodField()
    listing_detail = serializers.SerializerMethodField(read_only=True)

    pickup_address = serializers.CharField(required=False, allow_blank=True)
    latitude = serializers.DecimalField(
        max_digits=9,
        decimal_places=6,
        required=False,
        allow_null=True,
    )
    longitude = serializers.DecimalField(
        max_digits=9,
        decimal_places=6,
        required=False,
        allow_null=True,
    )
    food_type = serializers.CharField(required=True)
    listing_type = serializers.CharField(required=False, default="DONATION")
    quantity_unit = serializers.CharField(required=False, default="kg")
    best_before = serializers.DateTimeField(required=False)

    # Optional helper fields for easy POST payload construction
    ngo_priority_duration_minutes = serializers.IntegerField(
        required=False,
        write_only=True,
        min_value=1,
    )
    best_before_hours = serializers.FloatField(
        required=False,
        write_only=True,
        min_value=0.1,
    )

    # Optional listing detail fields accepted during POST
    fresh_at = serializers.DateTimeField(required=False, allow_null=True, write_only=True)
    pickup_window_start = serializers.DateTimeField(required=False, allow_null=True, write_only=True)
    pickup_window_end = serializers.DateTimeField(required=False, allow_null=True, write_only=True)
    pickup_instructions = serializers.CharField(required=False, allow_blank=True, write_only=True)
    contact_name = serializers.CharField(required=False, allow_blank=True, write_only=True)
    contact_phone = serializers.CharField(required=False, allow_blank=True, write_only=True)
    visibility_radius_km = serializers.DecimalField(
        max_digits=5,
        decimal_places=2,
        required=False,
        allow_null=True,
        write_only=True,
    )
    pack_size = serializers.IntegerField(required=False, min_value=1, write_only=True)
    auto_discount_percent = serializers.DecimalField(
        max_digits=5,
        decimal_places=2,
        required=False,
        allow_null=True,
        write_only=True,
    )

    class Meta:
        model = Donation
        fields = [
            "id",
            "donor",
            "donor_business_name",
            "listing_type",
            "title",
            "description",
            "food_type",
            "quantity",
            "quantity_unit",
            "people_served",
            "best_before",
            "best_before_hours",
            "ngo_priority_duration",
            "ngo_priority_duration_minutes",
            "ngo_priority_expires_at",
            "ngo_priority_active",
            "pickup_address",
            "latitude",
            "longitude",
            "price",
            "flash_sale_price",
            "status",
            "image",
            "claim",
            "listing_detail",
            "fresh_at",
            "pickup_window_start",
            "pickup_window_end",
            "pickup_instructions",
            "contact_name",
            "contact_phone",
            "visibility_radius_km",
            "pack_size",
            "auto_discount_percent",
            "created_at",
            "updated_at",
        ]
        read_only_fields = [
            "id",
            "donor",
            "ngo_priority_expires_at",
            "ngo_priority_active",
            "status",
            "claim",
            "created_at",
            "updated_at",
        ]

    def get_ngo_priority_active(self, obj):
        return obj.is_ngo_priority_active()

    def get_donor_business_name(self, obj):
        profile = getattr(obj.donor, "business_profile", None)
        if profile:
            return profile.business_name
        return getattr(obj.donor, "phone_num", str(obj.donor))

    def get_listing_detail(self, obj):
        try:
            from listing_flow.models import ListingDetail
            detail = getattr(obj, "listing_detail", None)
            if detail is None and obj.pk:
                detail = ListingDetail.objects.filter(donation=obj).first()
            if detail:
                return {
                    "fresh_at": detail.fresh_at,
                    "pickup_window_start": detail.pickup_window_start,
                    "pickup_window_end": detail.pickup_window_end,
                    "pickup_instructions": detail.pickup_instructions,
                    "contact_name": detail.contact_name,
                    "contact_phone": detail.contact_phone,
                    "visibility_radius_km": str(detail.visibility_radius_km),
                    "pack_size": detail.pack_size,
                    "auto_discount_percent": str(detail.auto_discount_percent),
                    "pack_count": detail.pack_count,
                }
        except Exception:
            pass
        return None

    def validate_food_type(self, value):
        if not value:
            return "VEG"
        v = str(value).strip().upper().replace("-", "").replace("_", "").replace(" ", "")
        if "NON" in v:
            return "NONVEG"
        elif "MIX" in v:
            return "MIXED"
        elif "VEG" in v:
            return "VEG"

        valid_choices = [c[0] for c in Donation.FOOD_TYPES]
        if str(value).upper() in valid_choices:
            return str(value).upper()
        raise serializers.ValidationError(
            f"Invalid food_type '{value}'. Valid choices are: VEG, NONVEG, MIXED."
        )

    def validate_listing_type(self, value):
        if not value:
            return "DONATION"
        v = str(value).strip().upper().replace("-", "_").replace(" ", "_")
        if "FLASH" in v or "SALE" in v:
            return "FLASH_SALE"
        elif "DONATION" in v or "FREE" in v:
            return "DONATION"

        valid_choices = [c[0] for c in Donation.LISTING_TYPE_CHOICES]
        if str(value).upper() in valid_choices:
            return str(value).upper()
        raise serializers.ValidationError(
            f"Invalid listing_type '{value}'. Valid choices are: DONATION, FLASH_SALE."
        )

    def validate(self, attrs):
        request = self.context.get("request")
        user = getattr(request, "user", None)

        # Handle ngo_priority_duration_minutes
        duration_minutes = attrs.pop("ngo_priority_duration_minutes", None)
        if duration_minutes is not None:
            attrs["ngo_priority_duration"] = timedelta(minutes=int(duration_minutes))

        # Handle duration if passed as int or float or string of digits
        raw_duration = attrs.get("ngo_priority_duration")
        if isinstance(raw_duration, (int, float)):
            attrs["ngo_priority_duration"] = timedelta(minutes=int(raw_duration))
        elif isinstance(raw_duration, str) and raw_duration.isdigit():
            attrs["ngo_priority_duration"] = timedelta(minutes=int(raw_duration))

        # Handle best_before_hours
        hours = attrs.pop("best_before_hours", None)
        if not attrs.get("best_before") and hours is not None:
            attrs["best_before"] = timezone.now() + timedelta(hours=float(hours))

        # Default best_before to 4 hours from now if creating and not provided
        if not self.instance and not attrs.get("best_before"):
            attrs["best_before"] = timezone.now() + timedelta(hours=4)

        # Fallback pickup_address from business profile if not provided
        if not attrs.get("pickup_address"):
            if self.instance and self.instance.pickup_address:
                attrs["pickup_address"] = self.instance.pickup_address
            elif user and hasattr(user, "business_profile") and user.business_profile.address:
                attrs["pickup_address"] = user.business_profile.address
            else:
                attrs["pickup_address"] = "Kathmandu"

        listing_type = attrs.get(
            "listing_type",
            getattr(self.instance, "listing_type", "DONATION"),
        )

        if listing_type == "FLASH_SALE":
            flash_sale_price = attrs.get(
                "flash_sale_price",
                getattr(self.instance, "flash_sale_price", None),
            )
            if not flash_sale_price:
                raise serializers.ValidationError(
                    {"flash_sale_price": "Required for flash sale listings"}
                )

        return attrs

    def create(self, validated_data):
        detail_fields = [
            "fresh_at",
            "pickup_window_start",
            "pickup_window_end",
            "pickup_instructions",
            "contact_name",
            "contact_phone",
            "visibility_radius_km",
            "pack_size",
            "auto_discount_percent",
        ]
        detail_data = {
            field: validated_data.pop(field)
            for field in detail_fields
            if field in validated_data and validated_data[field] is not None
        }

        donation = super().create(validated_data)

        if ListingDetail is not None:
            detail, _ = ListingDetail.objects.update_or_create(
                donation=donation,
                defaults=detail_data,
            )
            donation.listing_detail = detail

        return donation

    def update(self, instance, validated_data):
        detail_fields = [
            "fresh_at",
            "pickup_window_start",
            "pickup_window_end",
            "pickup_instructions",
            "contact_name",
            "contact_phone",
            "visibility_radius_km",
            "pack_size",
            "auto_discount_percent",
        ]
        detail_data = {
            field: validated_data.pop(field)
            for field in detail_fields
            if field in validated_data and validated_data[field] is not None
        }

        donation = super().update(instance, validated_data)

        if ListingDetail is not None and detail_data:
            ListingDetail.objects.update_or_create(
                donation=donation,
                defaults=detail_data,
            )

        return donation


class DonationClaimCreateSerializer(serializers.Serializer):

    donation = serializers.PrimaryKeyRelatedField(
        queryset=Donation.objects.all(),
        required=False,
        allow_null=True,
    )
    donation_id = serializers.IntegerField(
        required=False,
        allow_null=True,
    )
    pickup_method = serializers.ChoiceField(
        choices=DonationClaim.PICKUP_METHOD_CHOICES,
        default="SELF",
    )

    def validate(self, attrs):
        donation = attrs.get("donation")
        donation_id = attrs.get("donation_id")
        if not donation and donation_id:
            try:
                attrs["donation"] = Donation.objects.get(pk=donation_id)
            except Donation.DoesNotExist:
                raise serializers.ValidationError(
                    {"donation_id": f"Donation with id {donation_id} does not exist."}
                )
        return attrs


class ConsumerReservationCreateSerializer(serializers.Serializer):

    donation = serializers.PrimaryKeyRelatedField(
        queryset=Donation.objects.all(),
        required=False,
        allow_null=True,
    )
    donation_id = serializers.IntegerField(
        required=False,
        allow_null=True,
    )

    def validate(self, attrs):
        donation = attrs.get("donation")
        donation_id = attrs.get("donation_id")
        if not donation and donation_id:
            try:
                attrs["donation"] = Donation.objects.get(pk=donation_id)
            except Donation.DoesNotExist:
                raise serializers.ValidationError(
                    {"donation_id": f"Donation with id {donation_id} does not exist."}
                )
        return attrs


class VerifyPickupSerializer(serializers.Serializer):

    qr_code = serializers.CharField(required=False, allow_blank=True)
    manual_code = serializers.CharField(required=False, allow_blank=True)

    def validate(self, attrs):
        qr_code = attrs.get("qr_code")
        manual_code = attrs.get("manual_code")
        if not qr_code and not manual_code:
            raise serializers.ValidationError(
                "Provide qr_code or manual_code."
            )
        return attrs


class ConvertToFlashSaleSerializer(serializers.Serializer):

    flash_sale_price = serializers.DecimalField(
        max_digits=10,
        decimal_places=2,
        required=False,
    )
