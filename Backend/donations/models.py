import uuid
import random
import string
from datetime import timedelta
from decimal import Decimal
from django.conf import settings
from django.db import models
from django.utils import timezone


def default_ngo_priority_duration():
    return timedelta(minutes=45)


def generate_order_code():
    return f"ORD-{random.randint(1000, 9999)}"


def generate_receipt_number():
    return f"SP-REC-2026-{random.randint(1000, 9999)}"


def generate_sponsorship_id():
    return f"SPN-{random.randint(1000, 9999)}"


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
        default="VEG",
    )

    quantity = models.DecimalField(
        max_digits=10,
        decimal_places=2,
    )

    quantity_unit = models.CharField(
        max_length=20,
        default="Plates",
        help_text="e.g. Plates, Boxes, kg, Trays, Pots, Packs, Units, Loaves",
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

    food_photo = models.ImageField(
        upload_to="donations/food_photos/",
        blank=True,
        null=True,
        help_text="Photo of the surplus food item",
    )

    image = models.ImageField(
        upload_to="donations/",
        blank=True,
        null=True,
        help_text="Listing image or photo of food",
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return self.title

    def save(self, *args, **kwargs):
        if self.food_photo and not self.image:
            self.image = self.food_photo
        elif self.image and not self.food_photo:
            self.food_photo = self.image

        if not self.pk and self.listing_type == "DONATION":
            if not self.ngo_priority_expires_at:
                duration = self.ngo_priority_duration or default_ngo_priority_duration()
                self.ngo_priority_expires_at = timezone.now() + duration
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
        ("OWN_VAN", "Organization Van"),
        ("DELIVERY_BETA", "Request Delivery (Beta)"),
    ]

    STATUS_CHOICES = [
        ("PENDING", "Pending"),
        ("CONFIRMED", "Confirmed"),
        ("IN_PROGRESS", "In Progress"),
        ("PICKED_UP", "Picked Up"),
        ("COMPLETED", "Completed"),
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

    scheduled_pickup_start = models.DateTimeField(blank=True, null=True)
    scheduled_pickup_end = models.DateTimeField(blank=True, null=True)
    volunteer_name = models.CharField(max_length=150, blank=True, default="")
    volunteer_phone = models.CharField(max_length=30, blank=True, default="")
    donor_note = models.TextField(blank=True, default="")
    people_served_confirmed = models.PositiveIntegerField(blank=True, null=True)
    claimed_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        ordering = ["-claimed_at"]

    def __str__(self):
        return f"{self.ngo} claimed {self.donation.title}"


class ConsumerReservation(models.Model):

    STATUS_CHOICES = [
        ("PENDING", "Pending"),
        ("CONFIRMED", "Confirmed"),
        ("PICKED_UP", "Picked Up"),
        ("COMPLETED", "Completed"),
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

    quantity = models.PositiveIntegerField(default=1)

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


class ConsumerOrder(models.Model):

    STATUS_CHOICES = [
        ("READY_FOR_PICKUP", "Ready for Pickup"),
        ("COMPLETED", "Completed"),
        ("CANCELLED", "Cancelled"),
        ("EXPIRED", "Expired"),
    ]

    FOOD_CATEGORIES = [
        ("VEG", "Veg"),
        ("NONVEG", "Non-veg"),
        ("MIXED", "Mixed"),
    ]

    order_code = models.CharField(
        max_length=30,
        unique=True,
        default=generate_order_code,
    )

    consumer = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="consumer_orders",
        limit_choices_to={"role": "CUSTOMER"},
    )

    donation = models.ForeignKey(
        Donation,
        on_delete=models.SET_NULL,
        related_name="consumer_orders",
        blank=True,
        null=True,
    )

    title = models.CharField(max_length=200)
    store_name = models.CharField(max_length=200)
    store_phone = models.CharField(max_length=30, blank=True, default="")
    pickup_address = models.TextField()
    distance_km = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal("0.8"),
    )
    original_price = models.DecimalField(max_digits=10, decimal_places=2)
    discounted_price = models.DecimalField(max_digits=10, decimal_places=2)
    category = models.CharField(
        max_length=20,
        choices=FOOD_CATEGORIES,
        default="VEG",
    )
    pickup_window_minutes = models.PositiveIntegerField(default=40)
    instructions = models.TextField(
        blank=True,
        default="Show your order code at the cash counter to collect your fresh box.",
    )
    status = models.CharField(
        max_length=30,
        choices=STATUS_CHOICES,
        default="READY_FOR_PICKUP",
    )
    order_time = models.DateTimeField(default=timezone.now)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-order_time"]

    def __str__(self):
        return f"{self.order_code} - {self.title}"

    @property
    def saved_amount(self):
        return max(Decimal("0.00"), self.original_price - self.discounted_price)


class PickupTicket(models.Model):

    TICKET_TYPE_CHOICES = [
        ("NGO_CLAIM", "NGO Claim"),
        ("CONSUMER_RESERVATION", "Consumer Reservation"),
        ("CONSUMER_ORDER", "Consumer Order"),
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

    order = models.OneToOneField(
        ConsumerOrder,
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


class SurplusSponsorItem(models.Model):

    FOOD_CATEGORIES = [
        ("VEG", "Veg"),
        ("NONVEG", "Non-veg"),
        ("MIXED", "Mixed"),
    ]

    donor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        related_name="surplus_sponsor_items",
        limit_choices_to={"role": "BUSINESS"},
        blank=True,
        null=True,
    )
    donor_name = models.CharField(max_length=200)
    donor_type = models.CharField(
        max_length=100,
        default="Restaurant",
        help_text="e.g. 5-Star Hotel & Buffet, Artisan Bakery & Cafe, Traditional Restaurant",
    )
    donor_address = models.TextField()
    donor_phone = models.CharField(max_length=30, blank=True, default="")
    distance_km = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal("1.0"),
    )
    food_title = models.CharField(max_length=255)
    category = models.CharField(
        max_length=20,
        choices=FOOD_CATEGORIES,
        default="VEG",
    )
    total_meals = models.PositiveIntegerField(default=20)
    remaining_meals = models.PositiveIntegerField(default=20)
    quantity_unit = models.CharField(max_length=30, default="Meals")
    serves_approx = models.CharField(max_length=100, default="20-25 People")
    sponsor_price_per_meal = models.DecimalField(max_digits=10, decimal_places=2)
    original_price_per_meal = models.DecimalField(max_digits=10, decimal_places=2)
    minutes_left = models.PositiveIntegerField(default=120)
    cooked_ago = models.CharField(max_length=100, blank=True, default="45 mins ago")
    cooked_at = models.DateTimeField(default=timezone.now)
    destination_ngo = models.CharField(max_length=200)
    destination_ngo_category = models.CharField(
        max_length=100,
        default="Orphanage",
        help_text="e.g. Orphanage (65 Children), Child Shelter (45 Kids), Elderly Home (48 Seniors)",
    )
    destination_address = models.TextField()
    description = models.TextField()
    items_included = models.JSONField(
        default=list,
        blank=True,
        help_text="List of meal items included in the package",
    )
    packaging_info = models.CharField(
        max_length=255,
        default="Sealed thermal containers & tamper-proof meal boxes",
    )
    hygiene_rating = models.CharField(
        max_length=100,
        default="⭐️ 4.9 Food Safety & Hygiene Certified",
    )
    image = models.ImageField(
        upload_to="sponsorships/",
        blank=True,
        null=True,
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.food_title} ({self.donor_name})"

    @property
    def total_sponsor_price(self):
        return Decimal(self.remaining_meals) * self.sponsor_price_per_meal

    @property
    def total_original_price(self):
        return Decimal(self.remaining_meals) * self.original_price_per_meal

    @property
    def total_savings(self):
        return self.total_original_price - self.total_sponsor_price

    @property
    def discount_percent(self):
        if self.original_price_per_meal <= 0:
            return 0
        diff = self.original_price_per_meal - self.sponsor_price_per_meal
        return round((diff / self.original_price_per_meal) * 100)


class CharitySponsorship(models.Model):

    STATUS_CHOICES = [
        ("CONFIRMED", "Sponsorship Confirmed"),
        ("DELIVERED", "Delivered"),
        ("CANCELLED", "Cancelled"),
    ]

    sponsorship_id = models.CharField(
        max_length=30,
        unique=True,
        default=generate_sponsorship_id,
    )

    sponsor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="charity_sponsorships",
        limit_choices_to={"role": "CUSTOMER"},
    )

    surplus_item = models.ForeignKey(
        SurplusSponsorItem,
        on_delete=models.SET_NULL,
        related_name="sponsorships",
        blank=True,
        null=True,
    )

    food_title = models.CharField(max_length=255)
    donor_name = models.CharField(max_length=200)
    meals_count = models.PositiveIntegerField(default=1)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    original_value = models.DecimalField(max_digits=10, decimal_places=2)
    savings = models.DecimalField(max_digits=10, decimal_places=2)
    dedication = models.CharField(
        max_length=255,
        blank=True,
        default="",
        help_text="e.g. Dedicated by Rojina Shrestha / In loving memory of...",
    )
    status = models.CharField(
        max_length=30,
        choices=STATUS_CHOICES,
        default="CONFIRMED",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.sponsorship_id} - {self.food_title} ({self.sponsor})"


class ContributionItem(models.Model):

    STATUS_CHOICES = [
        ("AWAITING_CLAIM", "Awaiting Claim"),
        ("NGO_EN_ROUTE", "In Progress"),
        ("COMPLETED", "Completed"),
        ("CANCELLED", "Cancelled"),
    ]

    FOOD_CATEGORIES = [
        ("VEG", "Vegetarian"),
        ("NONVEG", "Non-Vegetarian"),
        ("MIXED", "Mixed Platter"),
    ]

    receipt_number = models.CharField(
        max_length=50,
        unique=True,
        default=generate_receipt_number,
    )

    donation = models.ForeignKey(
        Donation,
        on_delete=models.SET_NULL,
        related_name="contributions",
        blank=True,
        null=True,
    )

    donor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="donor_contributions",
        limit_choices_to={"role": "BUSINESS"},
    )

    recipient_ngo = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        related_name="ngo_received_contributions",
        limit_choices_to={"role": "NGO"},
        blank=True,
        null=True,
    )

    title = models.CharField(max_length=200)
    recipient_name = models.CharField(max_length=200)
    recipient_category = models.CharField(max_length=100, default="NGO")
    recipient_address = models.TextField(blank=True, default="")
    recipient_phone = models.CharField(max_length=30, blank=True, default="")

    category = models.CharField(
        max_length=20,
        choices=FOOD_CATEGORIES,
        default="VEG",
    )
    plates = models.PositiveIntegerField(default=10)
    serves_approx = models.CharField(max_length=100, default="15 people")

    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default="COMPLETED",
    )

    pickup_address = models.TextField()
    pickup_time = models.CharField(max_length=100, blank=True, default="7:45 PM")
    delivered_time = models.CharField(max_length=100, blank=True, default="8:15 PM")
    driver_volunteer = models.CharField(
        max_length=150,
        blank=True,
        default="Bikash Adhikari (SharePlate Volunteer)",
    )

    co2_saved_kg = models.DecimalField(
        max_digits=6,
        decimal_places=2,
        default=Decimal("4.80"),
    )
    beneficiaries_count = models.PositiveIntegerField(default=15)
    description = models.TextField(blank=True, default="")
    image = models.ImageField(upload_to="contributions/", blank=True, null=True)

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.receipt_number} - {self.title}"


class Notification(models.Model):

    TYPE_CHOICES = [
        ("SUCCESS", "Success"),
        ("ALERT", "Alert"),
        ("INFO", "Info"),
        ("PICKUP", "Pickup"),
        ("SUMMARY", "Summary"),
    ]

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="notifications",
    )
    title = models.CharField(max_length=200)
    message = models.TextField()
    notification_type = models.CharField(
        max_length=20,
        choices=TYPE_CHOICES,
        default="INFO",
    )
    is_read = models.BooleanField(default=False)
    target_id = models.CharField(max_length=100, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.title} ({self.user.phone_num})"


class NotificationPreference(models.Model):

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="notification_preference",
    )
    email_notifications = models.BooleanField(default=True)
    push_notifications = models.BooleanField(default=True)
    sms_alerts = models.BooleanField(default=True)
    expiry_reminders = models.BooleanField(default=True)
    claim_alerts = models.BooleanField(default=True)
    marketing_updates = models.BooleanField(default=False)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Preferences for {self.user.phone_num}"
