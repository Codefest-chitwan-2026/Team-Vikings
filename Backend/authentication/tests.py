from django.test import TestCase
from rest_framework.test import APIClient
from rest_framework import status
from users.models import User
from profiles.models import CustomerProfile, BusinessProfile, NGOProfile


class AuthenticationTests(TestCase):

    def setUp(self):
        self.client = APIClient()
        self.user_password = "password123"

        self.customer_user = User.objects.create_user(
            phone_num="9841000001",
            email="customer@example.com",
            password=self.user_password,
            role="CUSTOMER",
        )
        self.customer_profile = CustomerProfile.objects.create(
            user=self.customer_user,
            full_name="John Customer",
            address="Kathmandu",
        )

        self.business_user = User.objects.create_user(
            phone_num="9841000002",
            email="hotel@example.com",
            password=self.user_password,
            role="BUSINESS",
        )
        self.business_profile = BusinessProfile.objects.create(
            user=self.business_user,
            business_name="Grand Hotel",
            contact_name="Manager",
            address="Lalitpur",
        )

        self.ngo_user = User.objects.create_user(
            phone_num="9841000003",
            email="ngo@example.com",
            password=self.user_password,
            role="NGO",
        )
        self.ngo_profile = NGOProfile.objects.create(
            user=self.ngo_user,
            organization_name="Food For All NGO",
            contact_name="Director",
            address="Bhaktapur",
        )

    def test_login_with_phone_number_success(self):
        response = self.client.post(
            "/api/auth/login/",
            {"phone_num": "9841000001", "password": self.user_password},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("access", response.data)
        self.assertIn("refresh", response.data)
        self.assertEqual(response.data["user"]["phone_num"], "9841000001")
        self.assertEqual(response.data["user"]["role"], "CUSTOMER")
        self.assertIsNotNone(response.data["profile"])

    def test_login_with_email_in_phone_field_success(self):
        response = self.client.post(
            "/api/auth/login/",
            {"phone_num": "customer@example.com", "password": self.user_password},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("access", response.data)
        self.assertEqual(response.data["user"]["email"], "customer@example.com")

    def test_login_with_email_field_success(self):
        response = self.client.post(
            "/api/auth/login/",
            {"email": "hotel@example.com", "password": self.user_password},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("access", response.data)
        self.assertEqual(response.data["user"]["role"], "BUSINESS")

    def test_login_with_invalid_password_returns_error(self):
        response = self.client.post(
            "/api/auth/login/",
            {"phone_num": "9841000001", "password": "wrongpassword"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        error_text = str(response.data)
        self.assertIn("Invalid email or password", error_text)

    def test_login_with_nonexistent_email_returns_error(self):
        response = self.client.post(
            "/api/auth/login/",
            {"email": "nonexistent@example.com", "password": self.user_password},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        error_text = str(response.data)
        self.assertIn("Invalid email or password", error_text)

    def test_customer_registration_flow(self):
        response = self.client.post(
            "/api/auth/register/customer/",
            {
                "phone_num": "9841999991",
                "email": "newconsumer@example.com",
                "password": "strongpassword",
                "full_name": "New Consumer",
                "address": "Pokhara",
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn("access", response.data)
        self.assertEqual(response.data["user"]["email"], "newconsumer@example.com")

    def test_business_registration_flow(self):
        response = self.client.post(
            "/api/auth/register/business/",
            {
                "phone_num": "9841999992",
                "email": "newbusiness@example.com",
                "password": "strongpassword",
                "business_name": "Bakery Delight",
                "contact_name": "Baker Joe",
                "business_type": "Bakery",
                "registration_number": "PAN123456",
                "address": "Kathmandu",
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn("access", response.data)
        self.assertEqual(response.data["user"]["role"], "BUSINESS")

    def test_ngo_registration_flow(self):
        response = self.client.post(
            "/api/auth/register/ngo/",
            {
                "phone_num": "9841999993",
                "email": "newngo@example.com",
                "password": "strongpassword",
                "organization_name": "Help Trust",
                "organization_type": "NGO",
                "registration_number": "PAN987654",
                "contact_name": "Trustee",
                "address": "Lalitpur",
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn("access", response.data)
        self.assertEqual(response.data["user"]["role"], "NGO")

    def test_logout_blacklists_token(self):
        login_res = self.client.post(
            "/api/auth/login/",
            {"phone_num": "9841000001", "password": self.user_password},
            format="json",
        )
        access_token = login_res.data["access"]
        refresh_token = login_res.data["refresh"]

        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {access_token}")
        logout_res = self.client.post(
            "/api/auth/logout/",
            {"refresh": refresh_token},
            format="json",
        )
        self.assertEqual(logout_res.status_code, status.HTTP_200_OK)
