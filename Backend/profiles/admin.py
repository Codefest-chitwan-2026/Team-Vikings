from django.contrib import admin

from .models import CustomerProfile, BusinessProfile, NGOProfile


@admin.register(CustomerProfile)
class CustomerProfileAdmin(admin.ModelAdmin):
    list_display = ["full_name", "user", "user_email", "address"]
    list_filter = ["user__is_active"]
    search_fields = ["full_name", "user__phone_num", "user__email", "address"]
    autocomplete_fields = ["user"]
    readonly_fields = ["user"]

    @admin.display(description="Email", ordering="user__email")
    def user_email(self, obj):
        return obj.user.email


@admin.register(BusinessProfile)
class BusinessProfileAdmin(admin.ModelAdmin):
    list_display = [
        "business_name",
        "user",
        "registration_number",
        "latitude",
        "longitude",
        "has_document",
    ]
    list_filter = ["user__is_active"]
    search_fields = [
        "business_name",
        "registration_number",
        "user__phone_num",
        "user__email",
        "address",
    ]
    autocomplete_fields = ["user"]
    readonly_fields = ["user"]

    @admin.display(boolean=True, description="Document")
    def has_document(self, obj):
        return bool(obj.registration_document)


@admin.register(NGOProfile)
class NGOProfileAdmin(admin.ModelAdmin):
    list_display = [
        "organization_name",
        "organization_type",
        "user",
        "registration_number",
        "latitude",
        "longitude",
        "has_document",
    ]
    list_filter = ["organization_type", "user__is_active"]
    search_fields = [
        "organization_name",
        "registration_number",
        "user__phone_num",
        "user__email",
        "address",
    ]
    autocomplete_fields = ["user"]
    readonly_fields = ["user"]

    @admin.display(boolean=True, description="Document")
    def has_document(self, obj):
        return bool(obj.registration_document)
