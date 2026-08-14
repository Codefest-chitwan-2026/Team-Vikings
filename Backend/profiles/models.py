from django.db import models
from users.models import User

# Create your models here.
# customerprofile model 
class CustomerProfile(models.Model):
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name="customer_profile"
    )

    full_name = models.CharField(max_length=100)
    address = models.TextField()


# bussiness model profile 
class BusinessProfile(models.Model):
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name="business_profile"
    )

    business_name = models.CharField(max_length=200)
    registration_number = models.CharField(max_length=100)
    address = models.TextField()
    latitude = models.CharField(max_length=50)
    longitude = models.CharField(max_length=50)

    registration_document = models.FileField(
    upload_to="bussiness_documents/",
    blank=True,
    null=True)


# NGO model profiles 
class NGOProfile(models.Model):

    ORGANIZATION_TYPES = [
        ("Elderly Home", "Elderly Home"),
        ("Orphange", "Orphange"),
        ("NGO", "NGO"),
    ]

    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name="ngo_profile"
    )

    organization_name = models.CharField(max_length=200)
    organization_type = models.CharField(
        max_length=20,
        choices=ORGANIZATION_TYPES
    )
    registration_number = models.CharField(max_length=100)
    address = models.TextField()

    latitude = models.DecimalField(
    max_digits=9,
    decimal_places=6
)

    longitude = models.DecimalField(
        max_digits=9,
        decimal_places=6
    )

    registration_document = models.FileField(
    upload_to="ngo_documents/",
    blank=True,
    null=True
)