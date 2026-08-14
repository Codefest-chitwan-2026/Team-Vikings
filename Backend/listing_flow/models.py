import random
import string
from datetime import timedelta
from decimal import Decimal

from django.conf import settings
from django.db import models
from django.utils import timezone

from donations.models import Donation, DonationClaim, PickupTicket


def default_claim_hold_duration():
    return timedelta(minutes=10)


def generate_claim_reference():
  prefix = "AL"
  suffix = "".join(random.choices(string.digits, k=4))
  return f"{prefix}-{suffix}"


def generate_manual_code():
    return "".join(random.choices(string.ascii_uppercase + string.digits, k=8))


class ListingDetail(models.Model):

    donation = models.OneToOneField(
        Donation,
        on_delete=models.CASCADE,
        related_name="listing_detail",
    )

    fresh_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text="When the food was prepared / marked fresh",
    )

    pickup_window_start = models.DateTimeField(
        blank=True,
        null=True,
    )

    pickup_window_end = models.DateTimeField(
        blank=True,
        null=True,
    )

    pickup_instructions = models.TextField(
        blank=True,
        help_text="e.g. Back gate, ask for Suman (kitchen manager)",
    )

    contact_name = models.CharField(max_length=100, blank=True)
    contact_phone = models.CharField(max_length=20, blank=True)

    visibility_radius_km = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal("5.00"),
        help_text="Visible to consumers within this radius",
    )

    pack_size = models.PositiveIntegerField(
        default=1,
        help_text="Sold in packs of N servings",
    )

    auto_discount_percent = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal("65.00"),
        help_text="Auto discount when converting to flash sale",
    )

    class Meta:
        verbose_name = "Listing detail"
        verbose_name_plural = "Listing details"

    def __str__(self):
        return f"Details for {self.donation.title}"

    @property
    def pack_count(self):
        if self.pack_size <= 0:
            return 0
        return (self.donation.people_served + self.pack_size - 1) // self.pack_size

    def estimated_recovery(self):
        if not self.donation.flash_sale_price:
            return Decimal("0.00")
        return Decimal(self.pack_count) * self.donation.flash_sale_price


class ClaimHold(models.Model):

    STATUS_CHOICES = [
        ("ACTIVE", "Active"),
        ("COMPLETED", "Completed"),
        ("EXPIRED", "Expired"),
        ("CANCELLED", "Cancelled"),
    ]

    donation = models.ForeignKey(
        Donation,
        on_delete=models.CASCADE,
        related_name="claim_holds",
    )

    ngo = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="claim_holds",
        limit_choices_to={"role": "NGO"},
    )

    hold_duration = models.DurationField(default=default_claim_hold_duration)
    expires_at = models.DateTimeField()

    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default="ACTIVE",
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Hold {self.donation.title} for {self.ngo}"

    def save(self, *args, **kwargs):
        if not self.expires_at:
            self.expires_at = timezone.now() + self.hold_duration
        super().save(*args, **kwargs)

    def is_active(self):
        return self.status == "ACTIVE" and timezone.now() < self.expires_at

    def seconds_remaining(self):
        if not self.is_active():
            return 0
        return max(0, int((self.expires_at - timezone.now()).total_seconds()))

    def expire_if_needed(self):
        if self.status == "ACTIVE" and timezone.now() >= self.expires_at:
            self.status = "EXPIRED"
            self.save(update_fields=["status"])
            return True
        return False


class ClaimConfirmation(models.Model):

    PICKUP_METHOD_CHOICES = [
        ("OWN_VAN", "We'll pick it up"),
        ("VOLUNTEER", "Assign a volunteer"),
        ("DELIVERY_BETA", "Request delivery (beta)"),
    ]

    claim = models.OneToOneField(
        DonationClaim,
        on_delete=models.CASCADE,
        related_name="confirmation",
    )

    hold = models.ForeignKey(
        ClaimHold,
        on_delete=models.SET_NULL,
        related_name="confirmations",
        blank=True,
        null=True,
    )

    pickup_method = models.CharField(
        max_length=20,
        choices=PICKUP_METHOD_CHOICES,
    )

    scheduled_pickup_start = models.DateTimeField()
    scheduled_pickup_end = models.DateTimeField()

    people_served_confirmed = models.PositiveIntegerField()
    donor_note = models.TextField(blank=True)

    volunteer = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        related_name="volunteer_pickups",
        blank=True,
        null=True,
    )

    confirmed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-confirmed_at"]

    def __str__(self):
        return f"Confirmation for {self.claim}"


class PickupQRMetadata(models.Model):

    ticket = models.OneToOneField(
        PickupTicket,
        on_delete=models.CASCADE,
        related_name="qr_metadata",
    )

    claim_reference = models.CharField(
        max_length=20,
        unique=True,
        editable=False,
    )

    manual_code = models.CharField(
        max_length=12,
        unique=True,
        editable=False,
    )

    expires_at = models.DateTimeField()

    class Meta:
        verbose_name = "Pickup QR metadata"
        verbose_name_plural = "Pickup QR metadata"

    def __str__(self):
        return self.claim_reference

    def save(self, *args, **kwargs):
        if not self.claim_reference:
            self.claim_reference = generate_claim_reference()
        if not self.manual_code:
            self.manual_code = generate_manual_code()
        super().save(*args, **kwargs)

    def is_expired(self):
        return timezone.now() >= self.expires_at


class FlashSaleConversion(models.Model):

    CONVERSION_TYPE_CHOICES = [
        ("AUTO", "Automatic"),
        ("MANUAL", "Manual adjust price"),
        ("DONATION_ONLY", "Keep donation-only"),
    ]

    donation = models.OneToOneField(
        Donation,
        on_delete=models.CASCADE,
        related_name="flash_sale_conversion",
    )

    conversion_type = models.CharField(
        max_length=20,
        choices=CONVERSION_TYPE_CHOICES,
    )

    discount_percent = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        blank=True,
        null=True,
    )

    estimated_recovery = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal("0.00"),
    )

    visibility_radius_km = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal("5.00"),
    )

    converted_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-converted_at"]

    def __str__(self):
        return f"Conversion for {self.donation.title}"
