from django.db import models
from django.utils import timezone
from users.models import User


class CustomerProfile(models.Model):
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name="customer_profile",
    )
    full_name = models.CharField(max_length=100)
    address = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.full_name or f"Customer: {self.user.phone_num}"


class BusinessProfile(models.Model):
    VERIFICATION_STATUS_CHOICES = [
        ("PENDING", "Pending"),
        ("VERIFIED", "Verified"),
        ("REJECTED", "Rejected"),
    ]

    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name="business_profile",
    )
    business_name = models.CharField(max_length=200)
    contact_name = models.CharField(max_length=150, blank=True, default="")
    business_type = models.CharField(
        max_length=100,
        blank=True,
        default="Restaurant",
        help_text="e.g. Hotel & Buffet, Artisan Bakery & Cafe, Restaurant, Banquet & Catering",
    )
    registration_number = models.CharField(max_length=100, blank=True, default="")
    address = models.TextField(blank=True, default="")
    latitude = models.CharField(max_length=50, blank=True, default="27.7172")
    longitude = models.CharField(max_length=50, blank=True, default="85.3240")
    registration_document = models.FileField(
        upload_to="business_documents/",
        blank=True,
        null=True,
    )
    verification_status = models.CharField(
        max_length=20,
        choices=VERIFICATION_STATUS_CHOICES,
        default="VERIFIED",
    )
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.business_name or f"Business: {self.user.phone_num}"


class NGOProfile(models.Model):
    ORGANIZATION_TYPES = [
        ("NGO", "NGO"),
        ("Orphanage", "Orphanage"),
        ("Orphange", "Orphange"),
        ("Elderly Home", "Elderly Home"),
        ("Community Kitchen", "Community Kitchen"),
        ("Others", "Others"),
    ]

    VERIFICATION_STATUS_CHOICES = [
        ("PENDING", "Pending"),
        ("VERIFIED", "Verified"),
        ("REJECTED", "Rejected"),
    ]

    URGENCY_LEVEL_CHOICES = [
        ("High", "High"),
        ("Moderate", "Moderate"),
        ("Standard", "Standard"),
    ]

    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name="ngo_profile",
    )
    organization_name = models.CharField(max_length=200)
    organization_type = models.CharField(
        max_length=50,
        choices=ORGANIZATION_TYPES,
        default="NGO",
    )
    registration_number = models.CharField(max_length=100, blank=True, default="")
    contact_name = models.CharField(max_length=150, blank=True, default="")
    address = models.TextField(blank=True, default="")
    latitude = models.DecimalField(
        max_digits=12,
        decimal_places=8,
        default=27.7172,
    )
    longitude = models.DecimalField(
        max_digits=12,
        decimal_places=8,
        default=85.3240,
    )
    registration_document = models.FileField(
        upload_to="ngo_documents/",
        blank=True,
        null=True,
    )
    verification_status = models.CharField(
        max_length=20,
        choices=VERIFICATION_STATUS_CHOICES,
        default="VERIFIED",
    )
    total_meals_received = models.PositiveIntegerField(
        default=0,
        help_text="Total number of meals received through the platform",
    )
    people_supported = models.PositiveIntegerField(
        default=0,
        help_text="Number of people/beneficiaries supported",
    )
    description = models.TextField(blank=True, default="")
    current_needs = models.TextField(
        blank=True,
        default="",
        help_text="Current food/supply needs, separated by newlines or commas",
    )
    urgency_level = models.CharField(
        max_length=20,
        choices=URGENCY_LEVEL_CHOICES,
        default="Standard",
    )
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.organization_name or f"NGO: {self.user.phone_num}"


class VerificationDocument(models.Model):
    DOCUMENT_TYPES = [
        ("PDF", "PDF"),
        ("IMAGE", "Image"),
    ]

    STATUS_CHOICES = [
        ("PENDING", "Pending review"),
        ("VERIFIED", "Verified"),
        ("REJECTED", "Needs re-upload"),
    ]

    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="verification_documents",
    )
    title = models.CharField(
        max_length=200,
        default="Verification Document",
    )
    file_name = models.CharField(max_length=255, blank=True, default="")
    document_file = models.FileField(
        upload_to="verification_documents/",
        blank=True,
        null=True,
    )
    document_type = models.CharField(
        max_length=20,
        choices=DOCUMENT_TYPES,
        default="PDF",
    )
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default="VERIFIED",
    )
    submitted_on = models.DateTimeField(default=timezone.now)
    issued_id_number = models.CharField(max_length=100, blank=True, null=True)
    review_note = models.TextField(blank=True, null=True)
    issuer_authority = models.CharField(
        max_length=200,
        blank=True,
        null=True,
        help_text="e.g. Office of the Company Registrar / Social Welfare Council",
    )
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-submitted_on"]

    def __str__(self):
        return f"{self.title} ({self.user.phone_num})"