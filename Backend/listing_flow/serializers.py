from rest_framework import serializers

from donations.models import Donation

from .models import (
    ListingDetail,
    ClaimHold,
    ClaimConfirmation,
    PickupQRMetadata,
    FlashSaleConversion,
)
from .services import priority_seconds_remaining, haversine_km, get_or_create_listing_detail


class ListingDetailSerializer(serializers.ModelSerializer):

    pack_count = serializers.IntegerField(read_only=True)
    estimated_recovery = serializers.SerializerMethodField()

    class Meta:
        model = ListingDetail
        fields = [
            "fresh_at",
            "pickup_window_start",
            "pickup_window_end",
            "pickup_instructions",
            "contact_name",
            "contact_phone",
            "visibility_radius_km",
            "pack_size",
            "auto_discount_percent",
            "pack_count",
            "estimated_recovery",
        ]

    def get_estimated_recovery(self, obj):
        return str(obj.estimated_recovery())


class DonationDetailSerializer(serializers.ModelSerializer):

    listing_detail = ListingDetailSerializer(read_only=True)
    donor_business_name = serializers.SerializerMethodField()
    ngo_priority_active = serializers.SerializerMethodField()
    priority_seconds_remaining = serializers.SerializerMethodField()
    distance_km = serializers.SerializerMethodField()
    quantity_display = serializers.SerializerMethodField()

    class Meta:
        model = Donation
        fields = [
            "id",
            "title",
            "description",
            "food_type",
            "listing_type",
            "status",
            "quantity",
            "quantity_unit",
            "quantity_display",
            "people_served",
            "best_before",
            "pickup_address",
            "latitude",
            "longitude",
            "price",
            "flash_sale_price",
            "ngo_priority_expires_at",
            "ngo_priority_active",
            "priority_seconds_remaining",
            "donor_business_name",
            "distance_km",
            "image",
            "listing_detail",
            "created_at",
        ]

    def get_donor_business_name(self, obj):
        profile = getattr(obj.donor, "business_profile", None)
        return profile.business_name if profile else obj.donor.phone_num

    def get_ngo_priority_active(self, obj):
        return obj.is_ngo_priority_active()

    def get_priority_seconds_remaining(self, obj):
        return priority_seconds_remaining(obj)

    def get_distance_km(self, obj):
        request = self.context.get("request")
        if not request:
            return None

        lat = request.query_params.get("latitude")
        lng = request.query_params.get("longitude")

        if not lat or not lng or obj.latitude is None or obj.longitude is None:
            return None

        distance = haversine_km(
            float(lat),
            float(lng),
            float(obj.latitude),
            float(obj.longitude),
        )
        return round(distance, 1)

    def get_quantity_display(self, obj):
        return f"{obj.quantity} {obj.quantity_unit}"


class ClaimHoldSerializer(serializers.ModelSerializer):

    seconds_remaining = serializers.SerializerMethodField()

    class Meta:
        model = ClaimHold
        fields = [
            "id",
            "donation",
            "ngo",
            "status",
            "expires_at",
            "seconds_remaining",
            "created_at",
        ]
        read_only_fields = fields

    def get_seconds_remaining(self, obj):
        obj.expire_if_needed()
        return obj.seconds_remaining()


class ClaimHoldCreateSerializer(serializers.Serializer):

    donation_id = serializers.IntegerField()


class ConfirmClaimSerializer(serializers.Serializer):

    pickup_method = serializers.ChoiceField(
        choices=ClaimConfirmation.PICKUP_METHOD_CHOICES,
    )
    scheduled_pickup_start = serializers.DateTimeField()
    scheduled_pickup_end = serializers.DateTimeField()
    people_served_confirmed = serializers.IntegerField(min_value=1)
    donor_note = serializers.CharField(required=False, allow_blank=True)
    volunteer_id = serializers.IntegerField(required=False, allow_null=True)

    def validate(self, attrs):
        if attrs["scheduled_pickup_end"] <= attrs["scheduled_pickup_start"]:
            raise serializers.ValidationError(
                "Pickup end time must be after start time."
            )

        if attrs["pickup_method"] == "VOLUNTEER" and not attrs.get(
            "volunteer_id"
        ):
            raise serializers.ValidationError(
                {"volunteer_id": "Required when assigning a volunteer."}
            )

        return attrs


class PickupQRSerializer(serializers.Serializer):

    claim_reference = serializers.CharField()
    qr_code = serializers.CharField()
    manual_code = serializers.CharField()
    expires_at = serializers.DateTimeField()
    is_expired = serializers.BooleanField()
    ticket_type = serializers.CharField()
    food_summary = serializers.CharField()
    claimed_by = serializers.CharField()
    pickup_window = serializers.CharField()
    address = serializers.CharField()
    contact = serializers.CharField()
    donation_id = serializers.IntegerField()


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


class FlashSaleConversionSerializer(serializers.ModelSerializer):

    discount_label = serializers.SerializerMethodField()
    packs_available = serializers.SerializerMethodField()

    class Meta:
        model = FlashSaleConversion
        fields = [
            "conversion_type",
            "discount_percent",
            "discount_label",
            "estimated_recovery",
            "visibility_radius_km",
            "packs_available",
            "converted_at",
        ]

    def get_discount_label(self, obj):
        if obj.discount_percent:
            return f"{obj.discount_percent}% OFF"
        return None

    def get_packs_available(self, obj):
        detail = get_or_create_listing_detail(obj.donation)
        return detail.pack_count


class ListingUpdateSerializer(serializers.Serializer):

    priority_window_closed = serializers.BooleanField()
    priority_seconds_remaining = serializers.IntegerField()
    donation = DonationDetailSerializer()
    flash_sale_conversion = FlashSaleConversionSerializer(allow_null=True)
    can_adjust_price = serializers.BooleanField()
    can_keep_donation_only = serializers.BooleanField()


class AdjustPriceSerializer(serializers.Serializer):

    flash_sale_price = serializers.DecimalField(
        max_digits=10,
        decimal_places=2,
    )


class ListingDetailWriteSerializer(serializers.ModelSerializer):

    class Meta:
        model = ListingDetail
        fields = [
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
