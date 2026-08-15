from datetime import timedelta
from decimal import Decimal
from django.utils import timezone
from rest_framework import serializers

from .models import (
    Donation,
    DonationClaim,
    ConsumerReservation,
    ConsumerOrder,
    PickupTicket,
    SurplusSponsorItem,
    CharitySponsorship,
    ContributionItem,
    Notification,
    NotificationPreference,
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
            "claim",
            "reservation",
            "order",
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
    ngo_details = serializers.SerializerMethodField()

    class Meta:
        model = DonationClaim
        fields = [
            "id",
            "donation",
            "ngo",
            "ngo_name",
            "ngo_details",
            "pickup_method",
            "status",
            "scheduled_pickup_start",
            "scheduled_pickup_end",
            "volunteer_name",
            "volunteer_phone",
            "donor_note",
            "people_served_confirmed",
            "claimed_at",
            "completed_at",
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
        return getattr(obj.ngo, "phone_num", str(obj.ngo))

    def get_ngo_details(self, obj):
        profile = getattr(obj.ngo, "ngo_profile", None)
        if profile:
            return {
                "organization_name": profile.organization_name,
                "organization_type": profile.organization_type,
                "address": profile.address,
                "contact_name": profile.contact_name,
                "phone": obj.ngo.phone_num,
                "email": obj.ngo.email,
            }
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
            "quantity",
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
        return getattr(obj.consumer, "phone_num", str(obj.consumer))


class ConsumerOrderSerializer(serializers.ModelSerializer):

    pickup_ticket = PickupTicketSerializer(read_only=True)
    saved_amount = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)

    class Meta:
        model = ConsumerOrder
        fields = [
            "id",
            "order_code",
            "consumer",
            "donation",
            "title",
            "store_name",
            "store_phone",
            "pickup_address",
            "distance_km",
            "original_price",
            "discounted_price",
            "saved_amount",
            "category",
            "pickup_window_minutes",
            "instructions",
            "status",
            "order_time",
            "created_at",
            "pickup_ticket",
        ]
        read_only_fields = [
            "id",
            "order_code",
            "consumer",
            "saved_amount",
            "created_at",
            "pickup_ticket",
        ]


class DonationSerializer(serializers.ModelSerializer):

    claim = DonationClaimSerializer(read_only=True)
    ngo_priority_active = serializers.SerializerMethodField()
    donor_business_name = serializers.SerializerMethodField()
    listing_detail = serializers.SerializerMethodField(read_only=True)

    pickup_address = serializers.CharField(required=False, allow_blank=True)
    latitude = serializers.CharField(required=False, allow_null=True, allow_blank=True)
    longitude = serializers.CharField(required=False, allow_null=True, allow_blank=True)
    food_type = serializers.CharField(required=True)
    listing_type = serializers.CharField(required=False, default="DONATION")
    quantity_unit = serializers.CharField(required=False, default="Plates")
    best_before = serializers.DateTimeField(required=False)

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

    food_photo = serializers.ImageField(required=False, allow_null=True)
    photo = serializers.ImageField(required=False, allow_null=True, write_only=True)

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
            "food_photo",
            "photo",
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
        if profile and profile.business_name:
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

    def validate_latitude(self, value):
        if value is None or str(value).strip() == "":
            return None
        try:
            val = float(str(value).strip())
            if val < -90.0 or val > 90.0:
                raise serializers.ValidationError("Latitude must be between -90 and 90.")
            return Decimal(str(round(val, 8)))
        except (ValueError, TypeError):
            raise serializers.ValidationError("Invalid latitude format.")

    def validate_longitude(self, value):
        if value is None or str(value).strip() == "":
            return None
        try:
            val = float(str(value).strip())
            if val < -180.0 or val > 180.0:
                raise serializers.ValidationError("Longitude must be between -180 and 180.")
            return Decimal(str(round(val, 8)))
        except (ValueError, TypeError):
            raise serializers.ValidationError("Invalid longitude format.")

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

        photo = attrs.pop("photo", None)
        if photo and not attrs.get("food_photo"):
            attrs["food_photo"] = photo

        duration_minutes = attrs.pop("ngo_priority_duration_minutes", None)
        if duration_minutes is not None:
            attrs["ngo_priority_duration"] = timedelta(minutes=int(duration_minutes))

        raw_duration = attrs.get("ngo_priority_duration")
        if isinstance(raw_duration, (int, float)):
            attrs["ngo_priority_duration"] = timedelta(minutes=int(raw_duration))
        elif isinstance(raw_duration, str) and raw_duration.isdigit():
            attrs["ngo_priority_duration"] = timedelta(minutes=int(raw_duration))

        hours = attrs.pop("best_before_hours", None)
        if not attrs.get("best_before") and hours is not None:
            attrs["best_before"] = timezone.now() + timedelta(hours=float(hours))

        if not self.instance and not attrs.get("best_before"):
            attrs["best_before"] = timezone.now() + timedelta(hours=4)

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


class SurplusSponsorItemSerializer(serializers.ModelSerializer):

    total_sponsor_price = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    total_original_price = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    total_savings = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)
    discount_percent = serializers.IntegerField(read_only=True)

    class Meta:
        model = SurplusSponsorItem
        fields = [
            "id",
            "donor",
            "donor_name",
            "donor_type",
            "donor_address",
            "donor_phone",
            "distance_km",
            "food_title",
            "category",
            "total_meals",
            "remaining_meals",
            "quantity_unit",
            "serves_approx",
            "sponsor_price_per_meal",
            "original_price_per_meal",
            "total_sponsor_price",
            "total_original_price",
            "total_savings",
            "discount_percent",
            "minutes_left",
            "cooked_ago",
            "cooked_at",
            "destination_ngo",
            "destination_ngo_category",
            "destination_address",
            "description",
            "items_included",
            "packaging_info",
            "hygiene_rating",
            "image",
            "is_active",
            "created_at",
        ]
        read_only_fields = [
            "id",
            "total_sponsor_price",
            "total_original_price",
            "total_savings",
            "discount_percent",
            "created_at",
        ]


class CharitySponsorshipSerializer(serializers.ModelSerializer):

    sponsor_name = serializers.SerializerMethodField()

    class Meta:
        model = CharitySponsorship
        fields = [
            "id",
            "sponsorship_id",
            "sponsor",
            "sponsor_name",
            "surplus_item",
            "food_title",
            "donor_name",
            "meals_count",
            "amount",
            "original_value",
            "savings",
            "dedication",
            "status",
            "created_at",
        ]
        read_only_fields = [
            "id",
            "sponsorship_id",
            "sponsor",
            "created_at",
        ]

    def get_sponsor_name(self, obj):
        profile = getattr(obj.sponsor, "customer_profile", None)
        if profile and profile.full_name:
            return profile.full_name
        return getattr(obj.sponsor, "phone_num", str(obj.sponsor))


class ContributionItemSerializer(serializers.ModelSerializer):

    class Meta:
        model = ContributionItem
        fields = [
            "id",
            "receipt_number",
            "donation",
            "donor",
            "recipient_ngo",
            "title",
            "recipient_name",
            "recipient_category",
            "recipient_address",
            "recipient_phone",
            "category",
            "plates",
            "serves_approx",
            "status",
            "pickup_address",
            "pickup_time",
            "delivered_time",
            "driver_volunteer",
            "co2_saved_kg",
            "beneficiaries_count",
            "description",
            "image",
            "created_at",
        ]
        read_only_fields = [
            "id",
            "receipt_number",
            "created_at",
        ]


class NotificationSerializer(serializers.ModelSerializer):

    class Meta:
        model = Notification
        fields = [
            "id",
            "user",
            "title",
            "message",
            "notification_type",
            "is_read",
            "target_id",
            "created_at",
        ]
        read_only_fields = ["id", "user", "created_at"]


class NotificationPreferenceSerializer(serializers.ModelSerializer):

    class Meta:
        model = NotificationPreference
        fields = [
            "id",
            "user",
            "email_notifications",
            "push_notifications",
            "sms_alerts",
            "expiry_reminders",
            "claim_alerts",
            "marketing_updates",
            "updated_at",
        ]
        read_only_fields = ["id", "user", "updated_at"]


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
    scheduled_pickup_start = serializers.DateTimeField(required=False, allow_null=True)
    scheduled_pickup_end = serializers.DateTimeField(required=False, allow_null=True)
    volunteer_name = serializers.CharField(required=False, allow_blank=True)
    volunteer_phone = serializers.CharField(required=False, allow_blank=True)
    donor_note = serializers.CharField(required=False, allow_blank=True)
    people_served_confirmed = serializers.IntegerField(required=False, min_value=1)

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
    quantity = serializers.IntegerField(required=False, default=1, min_value=1)

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
            raise serializers.ValidationError("Provide qr_code or manual_code.")
        return attrs


class ConvertToFlashSaleSerializer(serializers.Serializer):

    flash_sale_price = serializers.DecimalField(
        max_digits=10,
        decimal_places=2,
        required=False,
    )


class CharitySponsorCreateSerializer(serializers.Serializer):

    surplus_item_id = serializers.IntegerField(required=False, allow_null=True)
    food_title = serializers.CharField(required=False, allow_blank=True)
    donor_name = serializers.CharField(required=False, allow_blank=True)
    meals_count = serializers.IntegerField(default=1, min_value=1)
    amount = serializers.DecimalField(max_digits=10, decimal_places=2, required=False)
    original_value = serializers.DecimalField(max_digits=10, decimal_places=2, required=False)
    savings = serializers.DecimalField(max_digits=10, decimal_places=2, required=False)
    dedication = serializers.CharField(required=False, allow_blank=True)
