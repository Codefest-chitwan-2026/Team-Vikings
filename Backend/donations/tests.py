from datetime import timedelta
from decimal import Decimal

from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework import status

from users.models import User
from profiles.models import BusinessProfile, NGOProfile, CustomerProfile
from donations.models import Donation, DonationClaim, PickupTicket


class DonationEndpointTests(TestCase):

    def setUp(self):
        self.client = APIClient()

        self.business_user = User.objects.create_user(
            phone_num="9800000001",
            email="business@test.com",
            password="testpass123",
            role="BUSINESS",
        )
        BusinessProfile.objects.create(
            user=self.business_user,
            business_name="Test Restaurant",
            registration_number="REG001",
            address="Kathmandu",
            latitude="27.7172",
            longitude="85.3240",
        )

        self.ngo_user = User.objects.create_user(
            phone_num="9800000002",
            email="ngo@test.com",
            password="testpass123",
            role="NGO",
        )
        NGOProfile.objects.create(
            user=self.ngo_user,
            organization_name="Test NGO",
            organization_type="NGO",
            registration_number="NGO001",
            address="Kathmandu",
            latitude=Decimal("27.7172"),
            longitude=Decimal("85.3240"),
        )

        self.customer_user = User.objects.create_user(
            phone_num="9800000003",
            email="customer@test.com",
            password="testpass123",
            role="CUSTOMER",
        )
        CustomerProfile.objects.create(
            user=self.customer_user,
            full_name="Test Customer",
            address="Kathmandu",
        )

        self.other_business = User.objects.create_user(
            phone_num="9800000004",
            email="other@test.com",
            password="testpass123",
            role="BUSINESS",
        )
        BusinessProfile.objects.create(
            user=self.other_business,
            business_name="Other Restaurant",
            registration_number="REG002",
            address="Pokhara",
            latitude="28.2096",
            longitude="83.9856",
        )

    def _login(self, user):
        response = self.client.post(
            "/api/auth/login/",
            {"phone_num": user.phone_num, "password": "testpass123"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {response.data['access']}"
        )

    def _create_donation(self, listing_type="DONATION", flash_sale_price=None):
        data = {
            "listing_type": listing_type,
            "title": "Surplus Rice",
            "description": "Fresh surplus rice",
            "food_type": "VEG",
            "quantity": "10.00",
            "quantity_unit": "kg",
            "people_served": 20,
            "best_before": (timezone.now() + timedelta(hours=4)).isoformat(),
            "pickup_address": "Kathmandu",
            "latitude": "27.7172",
            "longitude": "85.3240",
        }
        if flash_sale_price:
            data["flash_sale_price"] = str(flash_sale_price)
            data["price"] = "500.00"

        response = self.client.post("/api/donations/", data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        return response.data

    def test_list_donations_requires_auth(self):
        response = self.client.get("/api/donations/")
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_business_create_donation(self):
        self._login(self.business_user)
        donation = self._create_donation()
        self.assertEqual(donation["listing_type"], "DONATION")
        self.assertEqual(donation["status"], "AVAILABLE")
        self.assertIsNotNone(donation["ngo_priority_expires_at"])
        self.assertTrue(donation["ngo_priority_active"])

    def test_customer_cannot_create_donation(self):
        self._login(self.customer_user)
        response = self.client.post(
            "/api/donations/",
            {
                "title": "Test",
                "description": "Test",
                "food_type": "VEG",
                "quantity": "5",
                "people_served": 10,
                "best_before": (timezone.now() + timedelta(hours=2)).isoformat(),
                "pickup_address": "Kathmandu",
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_ngo_priority_list(self):
        self._login(self.business_user)
        self._create_donation()

        self._login(self.ngo_user)
        response = self.client.get("/api/donations/ngo_priority/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)

    def test_ngo_claim_donation_flow(self):
        self._login(self.business_user)
        donation = self._create_donation()
        donation_id = donation["id"]

        self._login(self.ngo_user)
        response = self.client.post(
            f"/api/donations/{donation_id}/claim/",
            {"pickup_method": "SELF"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn("qr_code", response.data["claim"]["pickup_ticket"])

        claims_response = self.client.get("/api/claims/")
        self.assertEqual(claims_response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(claims_response.data), 1)

    def test_flash_sale_reserve_and_verify_flow(self):
        self._login(self.business_user)
        donation = self._create_donation(
            listing_type="FLASH_SALE",
            flash_sale_price=Decimal("150.00"),
        )
        donation_id = donation["id"]

        flash_response = self.client.get("/api/donations/flash_sales/")
        self.assertEqual(flash_response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(flash_response.data), 1)

        self._login(self.customer_user)
        reserve_response = self.client.post(
            f"/api/donations/{donation_id}/reserve/",
            format="json",
        )
        self.assertEqual(reserve_response.status_code, status.HTTP_201_CREATED)
        qr_code = reserve_response.data["reservation"]["pickup_ticket"]["qr_code"]

        reservations_response = self.client.get("/api/reservations/")
        self.assertEqual(reservations_response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(reservations_response.data), 1)

        self._login(self.business_user)
        verify_response = self.client.post(
            "/api/donations/verify_pickup/",
            {"qr_code": qr_code},
            format="json",
        )
        self.assertEqual(verify_response.status_code, status.HTTP_200_OK)
        self.assertEqual(verify_response.data["donation"]["status"], "PICKED_UP")

    def test_convert_to_flash_sale(self):
        self._login(self.business_user)
        donation = self._create_donation()
        donation_id = donation["id"]

        Donation.objects.filter(id=donation_id).update(
            flash_sale_price=Decimal("100.00")
        )

        response = self.client.post(
            f"/api/donations/{donation_id}/convert_to_flash_sale/",
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(
            response.data["donation"]["listing_type"],
            "FLASH_SALE",
        )

    def test_cancel_donation(self):
        self._login(self.business_user)
        donation = self._create_donation()
        donation_id = donation["id"]

        response = self.client.post(
            f"/api/donations/{donation_id}/cancel/",
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["donation"]["status"], "CANCELLED")

    def test_claim_ngo_pickup_verification(self):
        self._login(self.business_user)
        donation = self._create_donation()
        donation_id = donation["id"]

        self._login(self.ngo_user)
        claim_response = self.client.post(
            f"/api/donations/{donation_id}/claim/",
            {"pickup_method": "SELF"},
            format="json",
        )
        qr_code = claim_response.data["claim"]["pickup_ticket"]["qr_code"]

        self._login(self.business_user)
        verify_response = self.client.post(
            "/api/donations/verify_pickup/",
            {"qr_code": qr_code},
            format="json",
        )
        self.assertEqual(verify_response.status_code, status.HTTP_200_OK)
        self.assertEqual(verify_response.data["donation"]["status"], "PICKED_UP")

    def test_post_donation_with_minutes_and_lowercase_choices(self):
        self._login(self.business_user)
        response = self.client.post(
            "/api/donations/",
            {
                "title": "Fresh Veggie Curry",
                "description": "Cooked 1 hour ago",
                "food_type": "veg",
                "listing_type": "donation",
                "quantity": "8.5",
                "people_served": 15,
                "ngo_priority_duration_minutes": 45,
                "best_before_hours": 3.5,
                "pickup_address": "Kathmandu",
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["food_type"], "VEG")
        self.assertEqual(response.data["listing_type"], "DONATION")
        self.assertIsNotNone(response.data["ngo_priority_expires_at"])

    def test_post_donation_with_listing_details(self):
        self._login(self.business_user)
        response = self.client.post(
            "/api/donations/",
            {
                "title": "Surplus Pastries",
                "description": "Fresh morning pastries",
                "food_type": "veg",
                "quantity": "5",
                "people_served": 10,
                "pickup_instructions": "Ask for kitchen manager at back door",
                "contact_name": "Suman",
                "contact_phone": "9800000001",
                "pack_size": 2,
                "auto_discount_percent": "60.00",
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn("listing_detail", response.data)
        if response.data["listing_detail"]:
            self.assertEqual(
                response.data["listing_detail"]["pickup_instructions"],
                "Ask for kitchen manager at back door",
            )
            self.assertEqual(
                response.data["listing_detail"]["contact_name"],
                "Suman",
            )

    def test_direct_claims_post_endpoint(self):
        self._login(self.business_user)
        donation = self._create_donation()

        self._login(self.ngo_user)
        response = self.client.post(
            "/api/claims/",
            {
                "donation_id": donation["id"],
                "pickup_method": "SELF",
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn("pickup_ticket", response.data["claim"])

    def test_direct_reservations_post_endpoint(self):
        self._login(self.business_user)
        donation = self._create_donation(
            listing_type="FLASH_SALE",
            flash_sale_price=Decimal("120.00"),
        )

        self._login(self.customer_user)
        response = self.client.post(
            "/api/reservations/",
            {
                "donation_id": donation["id"],
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn("pickup_ticket", response.data["reservation"])

    def test_staff_can_create_donation(self):
        staff_user = User.objects.create_superuser(
            phone_num="9899999999",
            email="admin@test.com",
            password="testpass123",
            role="BUSINESS",
        )
        self._login(staff_user)
        response = self.client.post(
            "/api/donations/",
            {
                "title": "Staff Posted Donation",
                "description": "Test donation by staff",
                "food_type": "MIXED",
                "quantity": "12.00",
                "people_served": 24,
                "pickup_address": "Kathmandu",
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    def test_upload_donation_food_photo(self):
        from io import BytesIO
        from PIL import Image
        from django.core.files.uploadedfile import SimpleUploadedFile

        self._login(self.business_user)

        img_byte_arr = BytesIO()
        img = Image.new("RGB", (10, 10), color="green")
        img.save(img_byte_arr, format="JPEG")
        photo = SimpleUploadedFile(
            "curry.jpg",
            img_byte_arr.getvalue(),
            content_type="image/jpeg",
        )

        response = self.client.post(
            "/api/donations/",
            {
                "title": "Paneer Butter Masala",
                "description": "Delicious curry with rice",
                "food_type": "VEG",
                "quantity": "4",
                "people_served": 8,
                "pickup_address": "Kathmandu",
                "food_photo": photo,
            },
            format="multipart",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIsNotNone(response.data["food_photo"])




