from rest_framework import serializers

from .models import (
    Donation,
    DonationClaim,
    ConsumerReservation,
    PickupTicket,
)


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
            "ngo_priority_duration",
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
        return None

    def validate(self, attrs):
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


class DonationClaimCreateSerializer(serializers.Serializer):

    pickup_method = serializers.ChoiceField(
        choices=DonationClaim.PICKUP_METHOD_CHOICES,
        default="SELF",
    )


class VerifyPickupSerializer(serializers.Serializer):

    qr_code = serializers.CharField()


class ConvertToFlashSaleSerializer(serializers.Serializer):

    flash_sale_price = serializers.DecimalField(
        max_digits=10,
        decimal_places=2,
        required=False,
    )
