from rest_framework import serializers
from users.models import User

from rest_framework import serializers
from users.models import User


class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(
        write_only=True,
        min_length=8
    )

    class Meta:
        model = User
        fields = [
            "id",
            "email",
            "phone_num",
            "password",
            "role",
        ]
        read_only_fields = ["id", "role"]

    def create(self, validated_data):
        user = User.objects.create_user(
            phone_num=validated_data["phone_num"],
            email=validated_data["email"],
            password=validated_data["password"],
            role="CUSTOMER",
        )

        return user