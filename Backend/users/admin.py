from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = [
        "phone_num",
        "email",
        "role",
        "is_active",
        "is_staff",
        "date_joined",
    ]
    list_filter = ["role", "is_active", "is_staff", "date_joined"]
    search_fields = ["phone_num", "email"]
    ordering = ["-date_joined"]
    list_editable = ["is_active"]
    readonly_fields = ["last_login", "date_joined"]

    fieldsets = (
        (None, {"fields": ("phone_num", "password")}),
        ("Account info", {"fields": ("email", "role")}),
        (
            "Permissions",
            {
                "fields": (
                    "is_active",
                    "is_staff",
                    "is_superuser",
                    "groups",
                    "user_permissions",
                ),
            },
        ),
        ("Activity", {"fields": ("last_login", "date_joined")}),
    )

    add_fieldsets = (
        (
            None,
            {
                "classes": ("wide",),
                "fields": (
                    "phone_num",
                    "email",
                    "role",
                    "password1",
                    "password2",
                    "is_staff",
                    "is_active",
                ),
            },
        ),
    )
