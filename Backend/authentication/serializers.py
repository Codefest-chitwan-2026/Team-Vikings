from rest_framework import serializers
from django.contrib.auth import authenticate
from rest_framework_simplejwt.tokens import RefreshToken
from users.models import User


class LoginSerializer(serializers.Serializer):
    phone_num = serializers.CharField()
    password = serializers.CharField(
        write_only=True
    )

    def validate(self, attrs):
        phone_num = attrs.get("phone_num")
        password = attrs.get("password")

        if not phone_num or not password:
            raise serializers.ValidationError(
                "Phone number and password are required."
            )

        user = authenticate(
            username=phone_num,
            password=password
        )

        if user is None:
            raise serializers.ValidationError(
                "Invalid phone number or password."
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