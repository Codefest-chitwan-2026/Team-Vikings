import uuid
from datetime import timedelta
from django.conf import settings
from django.db import models
from django.utils import timezone


def default_ngo_priority_duration():
    return timedelta(minutes=45)


class Donation(models.Model):

    LISTING_TYPE_CHOICES = [
        ("DONATION", "Donation"),
        ("FLASH_SALE", "Flash Sale"),
    ]

    STATUS_CHOICES = [
        ("AVAILABLE", "Available"),
        ("CLAIMED", "Claimed"),
        ("RESERVED", "Reserved"),
        ("PICKED_UP", "Picked Up"),
        ("COMPLETED", "Completed"),
        ("EXPIRED", "Expired"),
        ("CANCELLED", "Cancelled"),
    ]

    FOOD_TYPES = [
        ("VEG", "veg"),
        ("NONVEG", "non veg"),
        ("MIXED", "mixed"),
    ]

    donor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="donations",
        limit_choices_to={"role": "BUSINESS"},
    )

    listing_type = models.CharField(
        max_length=20,
        choices=LISTING_TYPE_CHOICES,
        default="DONATION",
    )

    title = models.CharField(max_length=200)
    description = models.TextField()

    food_type = models.CharField(
        max_length=20,
        choices=FOOD_TYPES,
    )

    quantity = models.DecimalField(
        max_digits=10,
        decimal_places=2,
    )

    quantity_unit = models.CharField(
        max_length=20,
        default="kg",
    )

    people_served = models.PositiveIntegerField(
        help_text="Number of people that can be served",
    )

    best_before = models.DateTimeField(
        help_text="When the food expires or should be consumed",
    )

    ngo_priority_duration = models.DurationField(
        default=default_ngo_priority_duration,
        help_text="NGO priority window before flash sale conversion",
    )

    ngo_priority_expires_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text="When the NGO priority window ends",
    )

    pickup_address = models.TextField()

    latitude = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        blank=True,
        null=True,
    )

    longitude = models.DecimalField(
        max_digits=9,
        decimal_places=6,
        blank=True,
        null=True,
    )

    price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        blank=True,
        null=True,
        help_text="Original price for flash sale listings",
    )

    flash_sale_price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        blank=True,
        null=True,
        help_text="Discounted flash sale price",
    )

    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default="AVAILABLE",
    )

    image = models.ImageField(
        upload_to="donations/",
        blank=True,
        null=True,
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return self.title

    def save(self, *args, **kwargs):
        if not self.pk and self.listing_type == "DONATION":
            if not self.ngo_priority_expires_at:
                duration = self.ngo_priority_duration or default_ngo_priority_duration()
                self.ngo_priority_expires_at = (
                    timezone.now() + duration
                )
        super().save(*args, **kwargs)

    def is_ngo_priority_active(self):
        return (
            self.listing_type == "DONATION"
            and self.status == "AVAILABLE"
            and self.ngo_priority_expires_at is not None
            and timezone.now() < self.ngo_priority_expires_at
        )

    def convert_to_flash_sale(self):
        if self.status != "AVAILABLE":
            raise ValueError("Only available listings can convert to flash sale")

        if not self.flash_sale_price:
            raise ValueError("Flash sale price is required before conversion")

        self.listing_type = "FLASH_SALE"
        self.ngo_priority_expires_at = None
        self.save(
            update_fields=[
                "listing_type",
                "ngo_priority_expires_at",
                "updated_at",
            ]
        )

    def check_priority_expired(self):
        if (
            self.listing_type == "DONATION"
            and self.status == "AVAILABLE"
            and self.ngo_priority_expires_at
            and timezone.now() >= self.ngo_priority_expires_at
        ):
            if self.flash_sale_price:
                self.convert_to_flash_sale()
            else:
                self.status = "EXPIRED"
                self.save(update_fields=["status", "updated_at"])
            return True
        return False


class DonationClaim(models.Model):

    PICKUP_METHOD_CHOICES = [
        ("SELF", "Self Pickup"),
        ("VOLUNTEER", "Volunteer Pickup"),
    ]

    STATUS_CHOICES = [
        ("PENDING", "Pending"),
        ("CONFIRMED", "Confirmed"),
        ("PICKED_UP", "Picked Up"),
        ("CANCELLED", "Cancelled"),
    ]

    donation = models.OneToOneField(
        Donation,
        on_delete=models.CASCADE,
        related_name="claim",
    )

    ngo = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="donation_claims",
        limit_choices_to={"role": "NGO"},
    )

    pickup_method = models.CharField(
        max_length=20,
        choices=PICKUP_METHOD_CHOICES,
        default="SELF",
    )

    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default="PENDING",
    )

    claimed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-claimed_at"]

    def __str__(self):
        return f"{self.ngo} claimed {self.donation.title}"


class ConsumerReservation(models.Model):

    STATUS_CHOICES = [
        ("PENDING", "Pending"),
        ("CONFIRMED", "Confirmed"),
        ("PICKED_UP", "Picked Up"),
        ("CANCELLED", "Cancelled"),
        ("EXPIRED", "Expired"),
    ]

    donation = models.ForeignKey(
        Donation,
        on_delete=models.CASCADE,
        related_name="reservations",
    )

    consumer = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="food_reservations",
        limit_choices_to={"role": "CUSTOMER"},
    )

    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default="PENDING",
    )

    reserved_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-reserved_at"]
        unique_together = ["donation", "consumer"]

    def __str__(self):
        return f"{self.consumer} reserved {self.donation.title}"


class PickupTicket(models.Model):

    TICKET_TYPE_CHOICES = [
        ("NGO_CLAIM", "NGO Claim"),
        ("CONSUMER_RESERVATION", "Consumer Reservation"),
    ]

    donation = models.ForeignKey(
        Donation,
        on_delete=models.CASCADE,
        related_name="pickup_tickets",
    )

    ticket_type = models.CharField(
        max_length=30,
        choices=TICKET_TYPE_CHOICES,
    )

    claim = models.OneToOneField(
        DonationClaim,
        on_delete=models.CASCADE,
        related_name="pickup_ticket",
        blank=True,
        null=True,
    )

    reservation = models.OneToOneField(
        ConsumerReservation,
        on_delete=models.CASCADE,
        related_name="pickup_ticket",
        blank=True,
        null=True,
    )

    qr_code = models.CharField(
        max_length=64,
        unique=True,
        editable=False,
    )

    is_verified = models.BooleanField(default=False)
    verified_at = models.DateTimeField(blank=True, null=True)

    verified_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        related_name="verified_pickups",
        blank=True,
        null=True,
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Pickup ticket {self.qr_code}"

    def save(self, *args, **kwargs):
        if not self.qr_code:
            self.qr_code = uuid.uuid4().hex
        super().save(*args, **kwargs)
