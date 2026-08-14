from datetime import timedelta
from decimal import Decimal

from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework import status

from users.models import User
from profiles.models import BusinessProfile, NGOProfile
from donations.models import Donation
from listing_flow.models import ClaimHold, PickupQRMetadata


class ListingFlowTests(TestCase):

    def setUp(self):
        self.client = APIClient()

        self.business = User.objects.create_user(
            phone_num="9810000001",
            email="biz@flow.com",
            password="testpass123",
            role="BUSINESS",
        )
        BusinessProfile.objects.create(
            user=self.business,
            business_name="Hotel Annapurna",
            registration_number="H001",
            address="Lazimpat, Kathmandu",
            latitude="27.7172",
            longitude="85.3240",
        )

        self.ngo = User.objects.create_user(
            phone_num="9810000002",
            email="ngo@flow.com",
            password="testpass123",
            role="NGO",
        )
        NGOProfile.objects.create(
            user=self.ngo,
            organization_name="Aasha Foundation",
            organization_type="NGO",
            registration_number="N001",
            address="Kathmandu",
            latitude=Decimal("27.7172"),
            longitude=Decimal("85.3240"),
        )

        self.donation = Donation.objects.create(
            donor=self.business,
            title="Dal Bhat trays (veg)",
            description="Fresh surplus",
            food_type="VEG",
            quantity=Decimal("9.00"),
            quantity_unit="kg",
            people_served=18,
            best_before=timezone.now() + timedelta(hours=2),
            pickup_address="Lazimpat, Kathmandu",
            latitude=Decimal("27.717200"),
            longitude=Decimal("85.324000"),
            price=Decimal("260.00"),
        )

    def _login(self, user):
        response = self.client.post(
            "/api/auth/login/",
            {"phone_num": user.phone_num, "password": "testpass123"},
            format="json",
        )
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {response.data['access']}"
        )

    def test_donation_detail_with_priority_timer(self):
        self._login(self.ngo)
        response = self.client.get(
            f"/api/listing-flow/{self.donation.id}/detail/",
            {"latitude": "27.71", "longitude": "85.32"},
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("priority_seconds_remaining", response.data)
        self.assertIn("listing_detail", response.data)
        self.assertIsNotNone(response.data["distance_km"])

    def test_claim_hold_and_confirm_flow(self):
        self._login(self.ngo)

        hold_response = self.client.post(
            "/api/claim-holds/",
            {"donation_id": self.donation.id},
            format="json",
        )
        self.assertEqual(hold_response.status_code, status.HTTP_201_CREATED)
        hold_id = hold_response.data["hold"]["id"]
        self.assertIn("seconds_remaining", hold_response.data["hold"])

        start = timezone.now() + timedelta(minutes=30)
        end = start + timedelta(minutes=30)

        confirm_response = self.client.post(
            f"/api/claim-holds/{hold_id}/confirm/",
            {
                "pickup_method": "OWN_VAN",
                "scheduled_pickup_start": start.isoformat(),
                "scheduled_pickup_end": end.isoformat(),
                "people_served_confirmed": 18,
                "donor_note": "Our van is white",
            },
            format="json",
        )
        self.assertEqual(confirm_response.status_code, status.HTTP_201_CREATED)
        self.assertIn("claim_reference", confirm_response.data)
        self.assertIn("qr_code", confirm_response.data)

        claim_id = confirm_response.data["claim_id"]
        qr_response = self.client.get(f"/api/pickup-qr/by-claim/{claim_id}/")
        self.assertEqual(qr_response.status_code, status.HTTP_200_OK)
        self.assertEqual(qr_response.data["claimed_by"], "Aasha Foundation")

    def test_verify_pickup_with_manual_code(self):
        self._login(self.ngo)
        hold = ClaimHold.objects.create(
            donation=self.donation,
            ngo=self.ngo,
            expires_at=timezone.now() + timedelta(minutes=10),
        )
        start = timezone.now() + timedelta(minutes=20)
        end = start + timedelta(minutes=30)

        self.client.post(
            f"/api/claim-holds/{hold.id}/confirm/",
            {
                "pickup_method": "OWN_VAN",
                "scheduled_pickup_start": start.isoformat(),
                "scheduled_pickup_end": end.isoformat(),
                "people_served_confirmed": 18,
            },
            format="json",
        )

        metadata = PickupQRMetadata.objects.first()
        self._login(self.business)

        expected = self.client.get(
            f"/api/verify-pickup/expected/{metadata.manual_code}/"
        )
        self.assertEqual(expected.status_code, status.HTTP_200_OK)

        verify = self.client.post(
            "/api/verify-pickup/",
            {"manual_code": metadata.manual_code},
            format="json",
        )
        self.assertEqual(verify.status_code, status.HTTP_200_OK)

    def test_auto_flash_sale_conversion(self):
        self.donation.ngo_priority_expires_at = timezone.now() - timedelta(
            minutes=1
        )
        self.donation.save()

        self._login(self.business)
        response = self.client.get(
            f"/api/listing-flow/{self.donation.id}/listing-update/"
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data["priority_window_closed"])
        self.assertIsNotNone(response.data["flash_sale_conversion"])

        self.donation.refresh_from_db()
        self.assertEqual(self.donation.listing_type, "FLASH_SALE")
