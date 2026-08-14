from django.shortcuts import render
from rest_framework import viewsets, status
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAdminUser
from rest_framework.parsers import MultiPartParser, FormParser

from users.models import User
from profiles.models import (
    CustomerProfile,
    BusinessProfile,
    NGOProfile,
)
from profiles.serializers import (
    CustomerProfileSerializer,
    BusinessProfileSerializer,
    NGOProfileSerializer,
)


class CustomerProfileViewSet(viewsets.ModelViewSet):

    queryset = CustomerProfile.objects.all()
    serializer_class = CustomerProfileSerializer

    def get_permissions(self):
        if self.action == "create":
            return [AllowAny()]

        return [IsAdminUser()]

    def create(self, request, *args, **kwargs):

        phone_num = request.data.get("phone_num")
        email = request.data.get("email")
        password = request.data.get("password")

        if User.objects.filter(phone_num=phone_num).exists():
            return Response(
                {"error": "Phone number already exists"},
                status=status.HTTP_400_BAD_REQUEST
            )

        if User.objects.filter(email=email).exists():
            return Response(
                {"error": "Email already exists"},
                status=status.HTTP_400_BAD_REQUEST
            )

        user = User.objects.create_user(
            phone_num=phone_num,
            email=email,
            password=password,
            role="CUSTOMER"
        )

        profile = CustomerProfile.objects.create(
            user=user,
            full_name=request.data.get("full_name"),
            address=request.data.get("address")
        )

        serializer = self.get_serializer(profile)

        return Response(
            {
                "message": "Customer registered successfully",
                "user": {
                    "id": user.id,
                    "phone_num": user.phone_num,
                    "email": user.email,
                    "role": user.role,
                },
                "profile": serializer.data,
            },
            status=status.HTTP_201_CREATED
        )


class BusinessProfileViewSet(viewsets.ModelViewSet):

    queryset = BusinessProfile.objects.all()
    serializer_class = BusinessProfileSerializer

    parser_classes = [MultiPartParser, FormParser]

    def get_permissions(self):
        if self.action == "create":
            return [AllowAny()]

        return [IsAdminUser()]

    def create(self, request, *args, **kwargs):

        phone_num = request.data.get("phone_num")
        email = request.data.get("email")
        password = request.data.get("password")

        if User.objects.filter(phone_num=phone_num).exists():
            return Response(
                {"error": "Phone number already exists"},
                status=status.HTTP_400_BAD_REQUEST
            )

        if User.objects.filter(email=email).exists():
            return Response(
                {"error": "Email already exists"},
                status=status.HTTP_400_BAD_REQUEST
            )

        user = User.objects.create_user(
            phone_num=phone_num,
            email=email,
            password=password,
            role="BUSINESS"
        )

        profile = BusinessProfile.objects.create(
            user=user,
            business_name=request.data.get("business_name"),
            registration_number=request.data.get(
                "registration_number"
            ),
            registration_document=request.data.get(
                "registration_document"
            ),
            address=request.data.get("address"),
            latitude=request.data.get("latitude"),
            longitude=request.data.get("longitude"),
        )

        serializer = self.get_serializer(profile)

        return Response(
            {
                "message": "Business registered successfully",
                "user": {
                    "id": user.id,
                    "phone_num": user.phone_num,
                    "email": user.email,
                    "role": user.role,
                },
                "profile": serializer.data,
            },
            status=status.HTTP_201_CREATED
        )


class NGOProfileViewSet(viewsets.ModelViewSet):

    queryset = NGOProfile.objects.all()
    serializer_class = NGOProfileSerializer

    parser_classes = [MultiPartParser, FormParser]

    def get_permissions(self):
        if self.action == "create":
            return [AllowAny()]

        return [IsAdminUser()]

    def create(self, request, *args, **kwargs):

        phone_num = request.data.get("phone_num")
        email = request.data.get("email")
        password = request.data.get("password")

        if User.objects.filter(phone_num=phone_num).exists():
            return Response(
                {"error": "Phone number already exists"},
                status=status.HTTP_400_BAD_REQUEST
            )

        if User.objects.filter(email=email).exists():
            return Response(
                {"error": "Email already exists"},
                status=status.HTTP_400_BAD_REQUEST
            )

        user = User.objects.create_user(
            phone_num=phone_num,
            email=email,
            password=password,
            role="NGO"
        )

        profile = NGOProfile.objects.create(
            user=user,
            organization_name=request.data.get(
                "organization_name"
            ),
            organization_type=request.data.get(
                "organization_type"
            ),
            registration_number=request.data.get(
                "registration_number"
            ),
            registration_document=request.data.get(
                "registration_document"
            ),
            address=request.data.get("address"),
            latitude=request.data.get("latitude"),
            longitude=request.data.get("longitude"),
        )

        serializer = self.get_serializer(profile)

        return Response(
            {
                "message": "NGO registered successfully",
                "user": {
                    "id": user.id,
                    "phone_num": user.phone_num,
                    "email": user.email,
                    "role": user.role,
                },
                "profile": serializer.data,
            },
            status=status.HTTP_201_CREATED
        )


# user models register 

from rest_framework.permissions import AllowAny, IsAdminUser
from users.models import User
from users.serializers import UserSerializer


class UserRegisterViewSet(viewsets.ModelViewSet):

    queryset = User.objects.all()
    serializer_class = UserSerializer

    def get_permissions(self):
        if self.action == "create":
            return [AllowAny()]

        return [IsAdminUser()]