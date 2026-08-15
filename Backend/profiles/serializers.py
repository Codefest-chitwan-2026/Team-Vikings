from rest_framework import serializers
from .models import CustomerProfile, BusinessProfile, NGOProfile, VerificationDocument


class CustomerProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomerProfile
        fields = [
            "id",
            "user",
            "full_name",
            "address",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "user", "created_at", "updated_at"]


class BusinessProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = BusinessProfile
        fields = [
            "id",
            "user",
            "business_name",
            "contact_name",
            "business_type",
            "registration_number",
            "registration_document",
            "address",
            "latitude",
            "longitude",
            "verification_status",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "user", "created_at", "updated_at"]


class NGOProfileSerializer(serializers.ModelSerializer):
    latitude = serializers.CharField(required=False, allow_null=True, allow_blank=True)
    longitude = serializers.CharField(required=False, allow_null=True, allow_blank=True)

    class Meta:
        model = NGOProfile
        fields = [
            "id",
            "user",
            "organization_name",
            "organization_type",
            "registration_number",
            "contact_name",
            "registration_document",
            "address",
            "latitude",
            "longitude",
            "verification_status",
            "total_meals_received",
            "people_supported",
            "description",
            "current_needs",
            "urgency_level",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "user", "created_at", "updated_at"]

    def validate_latitude(self, value):
        if value is None or str(value).strip() == "":
            return Decimal("27.717200")
        try:
            val = float(str(value).strip())
            return Decimal(str(round(val, 8)))
        except (ValueError, TypeError):
            raise serializers.ValidationError("Invalid latitude format.")

    def validate_longitude(self, value):
        if value is None or str(value).strip() == "":
            return Decimal("85.324000")
        try:
            val = float(str(value).strip())
            return Decimal(str(round(val, 8)))
        except (ValueError, TypeError):
            raise serializers.ValidationError("Invalid longitude format.")


class VerificationDocumentSerializer(serializers.ModelSerializer):
    class Meta:
        model = VerificationDocument
        fields = [
            "id",
            "user",
            "title",
            "file_name",
            "document_file",
            "document_type",
            "status",
            "submitted_on",
            "issued_id_number",
            "review_note",
            "issuer_authority",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "user", "created_at", "updated_at"]
