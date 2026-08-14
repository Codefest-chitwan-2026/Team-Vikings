from rest_framework import serializers
from .models import CustomerProfile, BusinessProfile, NGOProfile


class CustomerProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomerProfile
        fields = [
            "id",
            "user",
            "full_name",
            "address",
        ]
        read_only_fields = ["user"]

class BusinessProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = BusinessProfile
        fields = [
            "id",
            "user",
            "business_name",
            "registration_number",
            "registration_document",
            "address",
            "latitude",
            "longitude",
        ]
        read_only_fields = ["user"]


class NGOProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = NGOProfile
        fields = [
            "id",
            "user",
            "organization_name",
            "organization_type",
            "registration_number",
            "registration_document",
            "address",
            "latitude",
            "longitude",
        ]
        read_only_fields = ["user"]

