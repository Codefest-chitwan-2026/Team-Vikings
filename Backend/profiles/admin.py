from django.contrib import admin
from .models import CustomerProfile, BusinessProfile, NGOProfile, VerificationDocument


@admin.register(CustomerProfile)
class CustomerProfileAdmin(admin.ModelAdmin):
    list_display = ["full_name", "user", "user_email", "address", "created_at"]
    list_filter = ["user__is_active"]
    search_fields = ["full_name", "user__phone_num", "user__email", "address"]
    autocomplete_fields = ["user"]
    readonly_fields = ["user", "created_at", "updated_at"]

    @admin.display(description="Email", ordering="user__email")
    def user_email(self, obj):
        return obj.user.email


@admin.register(BusinessProfile)
class BusinessProfileAdmin(admin.ModelAdmin):
    list_display = [
        "business_name",
        "business_type",
        "contact_name",
        "user",
        "registration_number",
        "verification_status",
        "has_document",
        "created_at",
    ]
    list_filter = ["verification_status", "business_type", "user__is_active"]
    search_fields = [
        "business_name",
        "contact_name",
        "registration_number",
        "user__phone_num",
        "user__email",
        "address",
    ]
    autocomplete_fields = ["user"]
    readonly_fields = ["user", "created_at", "updated_at"]

    @admin.display(boolean=True, description="Document")
    def has_document(self, obj):
        return bool(obj.registration_document)


@admin.register(NGOProfile)
class NGOProfileAdmin(admin.ModelAdmin):
    list_display = [
        "organization_name",
        "organization_type",
        "contact_name",
        "user",
        "verification_status",
        "urgency_level",
        "total_meals_received",
        "people_supported",
        "has_document",
        "created_at",
    ]
    list_filter = [
        "organization_type",
        "verification_status",
        "urgency_level",
        "user__is_active",
    ]
    search_fields = [
        "organization_name",
        "contact_name",
        "registration_number",
        "user__phone_num",
        "user__email",
        "address",
    ]
    autocomplete_fields = ["user"]
    readonly_fields = ["user", "created_at", "updated_at"]

    @admin.display(boolean=True, description="Document")
    def has_document(self, obj):
        return bool(obj.registration_document)


@admin.register(VerificationDocument)
class VerificationDocumentAdmin(admin.ModelAdmin):
    list_display = [
        "title",
        "user",
        "document_type",
        "status",
        "issued_id_number",
        "submitted_on",
    ]
    list_filter = ["status", "document_type", "submitted_on"]
    search_fields = [
        "title",
        "file_name",
        "issued_id_number",
        "user__phone_num",
        "user__email",
    ]
    autocomplete_fields = ["user"]
    readonly_fields = ["submitted_on", "created_at", "updated_at"]
