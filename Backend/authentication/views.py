from django.shortcuts import render
from rest_framework import viewsets, status
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAdminUser, IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework_simplejwt.tokens import RefreshToken

from users.models import User
from profiles.models import (
    CustomerProfile,
    BusinessProfile,
    NGOProfile,
    VerificationDocument,
)
from profiles.serializers import (
    CustomerProfileSerializer,
    BusinessProfileSerializer,
    NGOProfileSerializer,
)
from users.serializers import UserSerializer
from .serializers import LoginSerializer, LogoutSerializer


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

        if not phone_num or not email or not password:
            return Response(
                {"error": "Phone number, email, and password are required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if User.objects.filter(phone_num=phone_num).exists():
            return Response(
                {"error": "Phone number already exists"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if User.objects.filter(email=email).exists():
            return Response(
                {"error": "Email already exists"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = User.objects.create_user(
            phone_num=phone_num,
            email=email,
            password=password,
            role="CUSTOMER",
        )

        profile = CustomerProfile.objects.create(
            user=user,
            full_name=request.data.get("full_name", "") or "",
            address=request.data.get("address", "") or "",
        )

        refresh = RefreshToken.for_user(user)
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
                "access": str(refresh.access_token),
                "refresh": str(refresh),
            },
            status=status.HTTP_201_CREATED,
        )


class BusinessProfileViewSet(viewsets.ModelViewSet):

    queryset = BusinessProfile.objects.all()
    serializer_class = BusinessProfileSerializer
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get_permissions(self):
        if self.action == "create":
            return [AllowAny()]
        return [IsAdminUser()]

    def create(self, request, *args, **kwargs):

        phone_num = request.data.get("phone_num")
        email = request.data.get("email")
        password = request.data.get("password")

        if not phone_num or not email or not password:
            return Response(
                {"error": "Phone number, email, and password are required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if User.objects.filter(phone_num=phone_num).exists():
            return Response(
                {"error": "Phone number already exists"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if User.objects.filter(email=email).exists():
            return Response(
                {"error": "Email already exists"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = User.objects.create_user(
            phone_num=phone_num,
            email=email,
            password=password,
            role="BUSINESS",
        )

        doc = request.data.get("registration_document")
        reg_num = request.data.get("registration_number", "") or ""

        profile = BusinessProfile.objects.create(
            user=user,
            business_name=request.data.get("business_name", "") or "",
            contact_name=request.data.get("contact_name", "") or "",
            business_type=request.data.get("business_type", "Restaurant") or "Restaurant",
            registration_number=reg_num,
            registration_document=doc,
            address=request.data.get("address", "") or "",
            latitude=request.data.get("latitude", "27.7172") or "27.7172",
            longitude=request.data.get("longitude", "85.3240") or "85.3240",
            verification_status="VERIFIED",
        )

        if doc:
            file_name = getattr(doc, "name", "business_document.pdf")
            is_pdf = str(file_name).lower().endswith(".pdf")
            VerificationDocument.objects.create(
                user=user,
                title="Business Registration Document",
                file_name=file_name,
                document_file=doc,
                document_type="PDF" if is_pdf else "IMAGE",
                status="PENDING",
                issued_id_number=reg_num,
                issuer_authority="Submitted during Registration",
            )

        refresh = RefreshToken.for_user(user)
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
                "access": str(refresh.access_token),
                "refresh": str(refresh),
            },
            status=status.HTTP_201_CREATED,
        )


class NGOProfileViewSet(viewsets.ModelViewSet):

    queryset = NGOProfile.objects.all()
    serializer_class = NGOProfileSerializer
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get_permissions(self):
        if self.action == "create":
            return [AllowAny()]
        return [IsAdminUser()]

    def create(self, request, *args, **kwargs):

        phone_num = request.data.get("phone_num")
        email = request.data.get("email")
        password = request.data.get("password")

        if not phone_num or not email or not password:
            return Response(
                {"error": "Phone number, email, and password are required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if User.objects.filter(phone_num=phone_num).exists():
            return Response(
                {"error": "Phone number already exists"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if User.objects.filter(email=email).exists():
            return Response(
                {"error": "Email already exists"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = User.objects.create_user(
            phone_num=phone_num,
            email=email,
            password=password,
            role="NGO",
        )

        doc = request.data.get("registration_document")
        pan_num = request.data.get("registration_number", "") or ""
        org_type = request.data.get("organization_type", "NGO") or "NGO"
        if org_type == "Orphange":
            org_type = "Orphanage"

        profile = NGOProfile.objects.create(
            user=user,
            organization_name=request.data.get("organization_name", "") or "",
            organization_type=org_type,
            registration_number=pan_num,
            contact_name=request.data.get("contact_name", "") or "",
            registration_document=doc,
            address=request.data.get("address", "") or "",
            latitude=request.data.get("latitude", 27.7172) or 27.7172,
            longitude=request.data.get("longitude", 85.3240) or 85.3240,
            verification_status="VERIFIED",
        )

        if doc:
            file_name = getattr(doc, "name", "ngo_document.pdf")
            is_pdf = str(file_name).lower().endswith(".pdf")
            VerificationDocument.objects.create(
                user=user,
                title="NGO Verification Certificate",
                file_name=file_name,
                document_file=doc,
                document_type="PDF" if is_pdf else "IMAGE",
                status="PENDING",
                issued_id_number=pan_num,
                issuer_authority="Submitted during Registration",
            )

        refresh = RefreshToken.for_user(user)
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
                "access": str(refresh.access_token),
                "refresh": str(refresh),
            },
            status=status.HTTP_201_CREATED,
        )


class UserRegisterViewSet(viewsets.ModelViewSet):

    queryset = User.objects.all()
    serializer_class = UserSerializer

    def get_permissions(self):
        if self.action == "create":
            return [AllowAny()]
        return [IsAdminUser()]


class LoginViewSet(viewsets.ViewSet):

    permission_classes = [AllowAny]

    def create(self, request):

        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = serializer.validated_data["user"]
        refresh = RefreshToken.for_user(user)

        profile_data = None
        if user.role == "BUSINESS" and hasattr(user, "business_profile"):
            profile_data = BusinessProfileSerializer(user.business_profile).data
        elif user.role == "NGO" and hasattr(user, "ngo_profile"):
            profile_data = NGOProfileSerializer(user.ngo_profile).data
        elif user.role == "CUSTOMER" and hasattr(user, "customer_profile"):
            profile_data = CustomerProfileSerializer(user.customer_profile).data

        return Response(
            {
                "message": "Login successful",
                "user": {
                    "id": user.id,
                    "phone_num": user.phone_num,
                    "email": user.email,
                    "role": user.role,
                },
                "profile": profile_data,
                "access": str(refresh.access_token),
                "refresh": str(refresh),
            },
            status=status.HTTP_200_OK,
        )


class LogoutViewSet(viewsets.ViewSet):

    permission_classes = [IsAuthenticated]

    def create(self, request):

        serializer = LogoutSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        return Response(
            {
                "message": "Logout successful"
            },
            status=status.HTTP_200_OK,
        )