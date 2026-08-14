from django.db.models.signals import post_save
from django.dispatch import receiver

from donations.models import Donation

from .services import get_or_create_listing_detail


@receiver(post_save, sender=Donation)
def create_listing_detail_on_donation(sender, instance, created, **kwargs):
    if created:
        get_or_create_listing_detail(instance)
