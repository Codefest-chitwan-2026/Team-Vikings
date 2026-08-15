from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.response import Response

from .models import CustomerProfile, BusinessProfile, NGOProfile
from .serializers import (
    CustomerProfileSerializer,
    BusinessProfileSerializer,
    NGOProfileSerializer,
)


class ProfileViewSet(viewsets.ViewSet):
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    @action(detail=False, methods=["get", "patch", "put"])
    def me(self, request):
        user = request.user
        role = getattr(user, "role", "CUSTOMER")

        if role == "BUSINESS":
            profile, _ = BusinessProfile.objects.get_or_create(
                user=user,
                defaults={
                    "business_name": user.email.split("@")[0] if user.email else "Business",
                    "address": "",
                    "latitude": "27.7172",
                    "longitude": "85.3240",
                    "registration_number": "",
                },
            )
            if request.method == "GET":
                serializer = BusinessProfileSerializer(profile, context={"request": request})
                data = serializer.data
                data["email"] = user.email
                data["phone_num"] = user.phone_num
                data["role"] = user.role
                return Response(data)

            if "phone_num" in request.data:
                user.phone_num = request.data["phone_num"]
            if "email" in request.data:
                user.email = request.data["email"]
            user.save()

            serializer = BusinessProfileSerializer(
                profile,
                data=request.data,
                partial=True,
                context={"request": request},
            )
            serializer.is_valid(raise_exception=True)
            serializer.save()
            data = serializer.data
            data["email"] = user.email
            data["phone_num"] = user.phone_num
            data["role"] = user.role
            return Response(data)

        elif role == "NGO":
            profile, _ = NGOProfile.objects.get_or_create(
                user=user,
                defaults={
                    "organization_name": user.email.split("@")[0] if user.email else "NGO",
                    "organization_type": "NGO",
                    "address": "",
                    "latitude": 27.7172,
                    "longitude": 85.3240,
                    "registration_number": "",
                },
            )
            if request.method == "GET":
                serializer = NGOProfileSerializer(profile, context={"request": request})
                data = serializer.data
                data["email"] = user.email
                data["phone_num"] = user.phone_num
                data["role"] = user.role
                return Response(data)

            if "phone_num" in request.data:
                user.phone_num = request.data["phone_num"]
            if "email" in request.data:
                user.email = request.data["email"]
            user.save()

            serializer = NGOProfileSerializer(
                profile,
                data=request.data,
                partial=True,
                context={"request": request},
            )
            serializer.is_valid(raise_exception=True)
            serializer.save()
            data = serializer.data
            data["email"] = user.email
            data["phone_num"] = user.phone_num
            data["role"] = user.role
            return Response(data)

        else:  # CUSTOMER
            profile, _ = CustomerProfile.objects.get_or_create(
                user=user,
                defaults={
                    "full_name": user.email.split("@")[0] if user.email else "Customer",
                    "address": "",
                },
            )
            if request.method == "GET":
                serializer = CustomerProfileSerializer(profile, context={"request": request})
                data = serializer.data
                data["email"] = user.email
                data["phone_num"] = user.phone_num
                data["role"] = user.role
                return Response(data)

            if "phone_num" in request.data:
                user.phone_num = request.data["phone_num"]
            if "email" in request.data:
                user.email = request.data["email"]
            user.save()

            serializer = CustomerProfileSerializer(
                profile,
                data=request.data,
                partial=True,
                context={"request": request},
            )
            serializer.is_valid(raise_exception=True)
            serializer.save()
            data = serializer.data
            data["email"] = user.email
            data["phone_num"] = user.phone_num
            data["role"] = user.role
            return Response(data)
