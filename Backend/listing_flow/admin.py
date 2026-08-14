from django.contrib import admin
from django.utils.html import format_html

from .models import (
    ListingDetail,
    ClaimHold,
    ClaimConfirmation,
    PickupQRMetadata,
    FlashSaleConversion,
)


@admin.register(ListingDetail)
class ListingDetailAdmin(admin.ModelAdmin):
    list_display = [
        "donation",
        "fresh_at",
        "pickup_window_start",
        "pickup_window_end",
        "pack_size",
        "visibility_radius_km",
        "auto_discount_percent",
    ]
    search_fields = ["donation__title", "contact_name", "contact_phone"]
    list_filter = ["pack_size"]


@admin.register(ClaimHold)
class ClaimHoldAdmin(admin.ModelAdmin):
    list_display = [
        "donation",
        "ngo",
        "status_badge",
        "expires_at",
        "seconds_left",
        "created_at",
    ]
    list_filter = ["status", "created_at"]
    search_fields = ["donation__title", "ngo__phone_num", "ngo__email"]
    readonly_fields = ["created_at"]

    @admin.display(description="Status", ordering="status")
    def status_badge(self, obj):
        colors = {
            "ACTIVE": "#198754",
            "COMPLETED": "#0d6efd",
            "EXPIRED": "#6c757d",
            "CANCELLED": "#dc3545",
        }
        return format_html(
            '<span style="color: {}; font-weight: 600;">{}</span>',
            colors.get(obj.status, "#333"),
            obj.get_status_display(),
        )

    @admin.display(description="Seconds left")
    def seconds_left(self, obj):
        return obj.seconds_remaining()


@admin.register(ClaimConfirmation)
class ClaimConfirmationAdmin(admin.ModelAdmin):
    list_display = [
        "claim",
        "pickup_method",
        "scheduled_pickup_start",
        "scheduled_pickup_end",
        "people_served_confirmed",
        "volunteer",
        "confirmed_at",
    ]
    list_filter = ["pickup_method", "confirmed_at"]
    search_fields = ["claim__donation__title", "donor_note"]


@admin.register(PickupQRMetadata)
class PickupQRMetadataAdmin(admin.ModelAdmin):
    list_display = [
        "claim_reference",
        "manual_code",
        "ticket",
        "expires_at",
        "expired_badge",
    ]
    search_fields = ["claim_reference", "manual_code", "ticket__qr_code"]
    readonly_fields = ["claim_reference", "manual_code"]

    @admin.display(description="Expired", boolean=True)
    def expired_badge(self, obj):
        return obj.is_expired()


@admin.register(FlashSaleConversion)
class FlashSaleConversionAdmin(admin.ModelAdmin):
    list_display = [
        "donation",
        "conversion_type",
        "discount_percent",
        "estimated_recovery",
        "visibility_radius_km",
        "converted_at",
    ]
    list_filter = ["conversion_type", "converted_at"]
    search_fields = ["donation__title"]
