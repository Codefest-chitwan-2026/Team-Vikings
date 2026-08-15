from math import radians, cos, sin, asin, sqrt
from decimal import Decimal

from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.response import Response

from .models import CustomerProfile, BusinessProfile, NGOProfile, VerificationDocument
from .serializers import (
    CustomerProfileSerializer,
    BusinessProfileSerializer,
    NGOProfileSerializer,
    VerificationDocumentSerializer,
)


def haversine_km(lat1, lon1, lat2, lon2):
    lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    a = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlon / 2) ** 2
    return 2 * asin(sqrt(a)) * 6371


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
                    "latitude": Decimal("27.7172"),
                    "longitude": Decimal("85.3240"),
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

    @action(detail=False, methods=["get", "post"])
    def documents(self, request):
        if request.method == "GET":
            docs = VerificationDocument.objects.filter(user=request.user)
            serializer = VerificationDocumentSerializer(docs, many=True, context={"request": request})
            return Response(serializer.data)

        serializer = VerificationDocumentSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        serializer.save(user=request.user)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=["get"], url_path="nearby-ngos", permission_classes=[AllowAny])
    def nearby_ngos(self, request):
        queryset = NGOProfile.objects.select_related("user").filter(user__is_active=True)

        user_lat = request.query_params.get("latitude")
        user_lng = request.query_params.get("longitude")
        radius_km = request.query_params.get("radius_km")

        results = []
        for ngo in queryset:
            data = NGOProfileSerializer(ngo, context={"request": request}).data
            data["phone_number"] = ngo.user.phone_num
            data["email"] = ngo.user.email
            data["distance_km"] = 1.0

            if user_lat and user_lng and ngo.latitude and ngo.longitude:
                try:
                    dist = haversine_km(
                        float(user_lat),
                        float(user_lng),
                        float(ngo.latitude),
                        float(ngo.longitude),
                    )
                    data["distance_km"] = round(dist, 1)
                    if radius_km and dist > float(radius_km):
                        continue
                except (ValueError, TypeError):
                    pass

            results.append(data)

        return Response(results)
