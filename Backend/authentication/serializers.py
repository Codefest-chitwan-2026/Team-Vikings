from rest_framework import serializers
from django.contrib.auth import authenticate
from rest_framework_simplejwt.tokens import RefreshToken
from users.models import User


class LoginSerializer(serializers.Serializer):
    phone_num = serializers.CharField(required=False, allow_blank=True)
    email = serializers.CharField(required=False, allow_blank=True)
    username = serializers.CharField(required=False, allow_blank=True)
    password = serializers.CharField(
        write_only=True
    )

    def validate(self, attrs):
        phone_num = (attrs.get("phone_num") or "").strip()
        email = (attrs.get("email") or "").strip()
        username = (attrs.get("username") or "").strip()
        password = attrs.get("password") or ""

        identifier = phone_num or email or username
        if not identifier or not password:
            raise serializers.ValidationError(
                "Phone number or email, and password are required."
            )

        user = None
        if "@" in identifier:
            user = User.objects.filter(email__iexact=identifier).first()
        else:
            user = User.objects.filter(phone_num=identifier).first()
            if user is None:
                user = User.objects.filter(email__iexact=identifier).first()

        if user is None or not user.check_password(password):
            raise serializers.ValidationError(
                "Invalid email or password."
            )

        if not user.is_active:
            raise serializers.ValidationError(
                "This account is inactive."
            )

        attrs["user"] = user

        return attrs


class LogoutSerializer(serializers.Serializer):
    refresh = serializers.CharField()

    def validate(self, attrs):
        refresh_token = attrs["refresh"]

        try:
            token = RefreshToken(refresh_token)
            token.blacklist()

        except Exception:
            raise serializers.ValidationError(
                "Invalid or expired refresh token."
            )

        return attrs