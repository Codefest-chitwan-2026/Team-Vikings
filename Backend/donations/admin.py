from django.contrib import admin
from django.utils.html import format_html

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
)


class DonationClaimInline(admin.StackedInline):
    model = DonationClaim
    extra = 0
    can_delete = False
    readonly_fields = ["ngo", "pickup_method", "status", "claimed_at"]
    fk_name = "donation"


class ConsumerReservationInline(admin.TabularInline):
    model = ConsumerReservation
    extra = 0
    readonly_fields = ["consumer", "quantity", "status", "reserved_at"]


class PickupTicketInline(admin.TabularInline):
    model = PickupTicket
    extra = 0
    readonly_fields = [
        "ticket_type",
        "qr_code",
        "is_verified",
        "verified_at",
        "verified_by",
        "created_at",
    ]


@admin.register(Donation)
class DonationAdmin(admin.ModelAdmin):
    list_display = [
        "title",
        "donor_name",
        "listing_type",
        "status_badge",
        "food_type",
        "quantity_display",
        "people_served",
        "best_before",
        "ngo_priority_expires_at",
        "flash_sale_price",
        "created_at",
    ]
    list_filter = [
        "listing_type",
        "status",
        "food_type",
        "created_at",
        "best_before",
    ]
    search_fields = [
        "title",
        "description",
        "pickup_address",
        "donor__phone_num",
        "donor__email",
        "donor__business_profile__business_name",
    ]
    date_hierarchy = "created_at"
    ordering = ["-created_at"]
    list_select_related = ["donor"]
    autocomplete_fields = ["donor"]
    readonly_fields = ["created_at", "updated_at", "ngo_priority_expires_at"]
    inlines = [DonationClaimInline, ConsumerReservationInline, PickupTicketInline]

    @admin.display(description="Donor", ordering="donor__business_profile__business_name")
    def donor_name(self, obj):
        profile = getattr(obj.donor, "business_profile", None)
        if profile and profile.business_name:
            return profile.business_name
        return obj.donor.phone_num

    @admin.display(description="Quantity", ordering="quantity")
    def quantity_display(self, obj):
        return f"{obj.quantity} {obj.quantity_unit}"

    @admin.display(description="Status", ordering="status")
    def status_badge(self, obj):
        colors = {
            "AVAILABLE": "#198754",
            "CLAIMED": "#0d6efd",
            "RESERVED": "#fd7e14",
            "PICKED_UP": "#6f42c1",
            "COMPLETED": "#20c997",
            "EXPIRED": "#6c757d",
            "CANCELLED": "#dc3545",
        }
        color = colors.get(obj.status, "#333333")
        return format_html(
            '<span style="color: {}; font-weight: 600;">{}</span>',
            color,
            obj.get_status_display(),
        )


@admin.register(DonationClaim)
class DonationClaimAdmin(admin.ModelAdmin):
    list_display = [
        "donation",
        "ngo_name",
        "pickup_method",
        "status_badge",
        "claimed_at",
        "has_pickup_ticket",
    ]
    list_filter = ["status", "pickup_method", "claimed_at"]
    search_fields = [
        "donation__title",
        "ngo__phone_num",
        "ngo__email",
        "ngo__ngo_profile__organization_name",
    ]
    date_hierarchy = "claimed_at"
    ordering = ["-claimed_at"]
    list_select_related = ["donation", "ngo"]
    autocomplete_fields = ["donation", "ngo"]
    readonly_fields = ["claimed_at"]

    @admin.display(description="NGO", ordering="ngo__ngo_profile__organization_name")
    def ngo_name(self, obj):
        profile = getattr(obj.ngo, "ngo_profile", None)
        if profile and profile.organization_name:
            return profile.organization_name
        return obj.ngo.phone_num

    @admin.display(description="Status", ordering="status")
    def status_badge(self, obj):
        colors = {
            "PENDING": "#fd7e14",
            "CONFIRMED": "#0d6efd",
            "IN_PROGRESS": "#0dcaf0",
            "PICKED_UP": "#198754",
            "COMPLETED": "#20c997",
            "CANCELLED": "#dc3545",
        }
        color = colors.get(obj.status, "#333333")
        return format_html(
            '<span style="color: {}; font-weight: 600;">{}</span>',
            color,
            obj.get_status_display(),
        )

    @admin.display(boolean=True, description="QR ticket")
    def has_pickup_ticket(self, obj):
        return PickupTicket.objects.filter(claim=obj).exists()


@admin.register(ConsumerReservation)
class ConsumerReservationAdmin(admin.ModelAdmin):
    list_display = [
        "donation",
        "consumer_name",
        "quantity",
        "status_badge",
        "reserved_at",
        "has_pickup_ticket",
    ]
    list_filter = ["status", "reserved_at"]
    search_fields = [
        "donation__title",
        "consumer__phone_num",
        "consumer__email",
        "consumer__customer_profile__full_name",
    ]
    date_hierarchy = "reserved_at"
    ordering = ["-reserved_at"]
    list_select_related = ["donation", "consumer"]
    autocomplete_fields = ["donation", "consumer"]
    readonly_fields = ["reserved_at"]

    @admin.display(description="Consumer", ordering="consumer__customer_profile__full_name")
    def consumer_name(self, obj):
        profile = getattr(obj.consumer, "customer_profile", None)
        if profile and profile.full_name:
            return profile.full_name
        return obj.consumer.phone_num

    @admin.display(description="Status", ordering="status")
    def status_badge(self, obj):
        colors = {
            "PENDING": "#fd7e14",
            "CONFIRMED": "#0d6efd",
            "PICKED_UP": "#198754",
            "COMPLETED": "#20c997",
            "CANCELLED": "#dc3545",
            "EXPIRED": "#6c757d",
        }
        color = colors.get(obj.status, "#333333")
        return format_html(
            '<span style="color: {}; font-weight: 600;">{}</span>',
            color,
            obj.get_status_display(),
        )

    @admin.display(boolean=True, description="QR ticket")
    def has_pickup_ticket(self, obj):
        return PickupTicket.objects.filter(reservation=obj).exists()


@admin.register(ConsumerOrder)
class ConsumerOrderAdmin(admin.ModelAdmin):
    list_display = [
        "order_code",
        "title",
        "store_name",
        "consumer",
        "discounted_price",
        "status",
        "order_time",
    ]
    list_filter = ["status", "category", "order_time"]
    search_fields = ["order_code", "title", "store_name", "consumer__phone_num"]
    date_hierarchy = "order_time"
    readonly_fields = ["created_at"]


@admin.register(PickupTicket)
class PickupTicketAdmin(admin.ModelAdmin):
    list_display = [
        "short_qr_code",
        "donation",
        "ticket_type",
        "verification_badge",
        "verified_by",
        "verified_at",
        "created_at",
    ]
    list_filter = ["ticket_type", "is_verified", "created_at"]
    search_fields = [
        "qr_code",
        "donation__title",
        "verified_by__phone_num",
    ]
    date_hierarchy = "created_at"
    ordering = ["-created_at"]
    list_select_related = ["donation", "verified_by", "claim", "reservation"]
    readonly_fields = ["qr_code", "created_at"]

    @admin.display(description="QR code", ordering="qr_code")
    def short_qr_code(self, obj):
        return f"{obj.qr_code[:12]}..."

    @admin.display(description="Verified", ordering="is_verified")
    def verification_badge(self, obj):
        if obj.is_verified:
            return format_html(
                '<span style="color: #198754; font-weight: 600;">Verified</span>'
            )
        return format_html(
            '<span style="color: #fd7e14; font-weight: 600;">Pending</span>'
        )


@admin.register(SurplusSponsorItem)
class SurplusSponsorItemAdmin(admin.ModelAdmin):
    list_display = [
        "food_title",
        "donor_name",
        "destination_ngo",
        "remaining_meals",
        "sponsor_price_per_meal",
        "is_active",
        "created_at",
    ]
    list_filter = ["category", "is_active", "created_at"]
    search_fields = ["food_title", "donor_name", "destination_ngo"]


@admin.register(CharitySponsorship)
class CharitySponsorshipAdmin(admin.ModelAdmin):
    list_display = [
        "sponsorship_id",
        "food_title",
        "donor_name",
        "sponsor",
        "meals_count",
        "amount",
        "status",
        "created_at",
    ]
    list_filter = ["status", "created_at"]
    search_fields = ["sponsorship_id", "food_title", "donor_name", "sponsor__phone_num"]


@admin.register(ContributionItem)
class ContributionItemAdmin(admin.ModelAdmin):
    list_display = [
        "receipt_number",
        "title",
        "donor",
        "recipient_name",
        "category",
        "plates",
        "co2_saved_kg",
        "status",
        "created_at",
    ]
    list_filter = ["category", "status", "created_at"]
    search_fields = ["receipt_number", "title", "recipient_name", "donor__phone_num"]


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ["title", "user", "notification_type", "is_read", "created_at"]
    list_filter = ["notification_type", "is_read", "created_at"]
    search_fields = ["title", "message", "user__phone_num"]


@admin.register(NotificationPreference)
class NotificationPreferenceAdmin(admin.ModelAdmin):
    list_display = ["user", "email_notifications", "push_notifications", "sms_alerts", "updated_at"]
