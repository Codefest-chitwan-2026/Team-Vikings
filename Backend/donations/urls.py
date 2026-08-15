from rest_framework.routers import DefaultRouter

from .views import (
    DonationViewSet,
    DonationClaimViewSet,
    ConsumerReservationViewSet,
    ConsumerOrderViewSet,
    SurplusSponsorItemViewSet,
    CharitySponsorshipViewSet,
    ContributionItemViewSet,
    NotificationViewSet,
    NotificationPreferenceViewSet,
)

router = DefaultRouter()

router.register("donations", DonationViewSet, basename="donation")
router.register("claims", DonationClaimViewSet, basename="donation-claim")
router.register("reservations", ConsumerReservationViewSet, basename="consumer-reservation")
router.register("orders", ConsumerOrderViewSet, basename="consumer-order")
router.register("sponsorship-items", SurplusSponsorItemViewSet, basename="surplus-sponsor-item")
router.register("sponsorships", CharitySponsorshipViewSet, basename="charity-sponsorship")
router.register("contributions", ContributionItemViewSet, basename="contribution-item")
router.register("notifications", NotificationViewSet, basename="notification")
router.register("notification-settings", NotificationPreferenceViewSet, basename="notification-preference")

urlpatterns = router.urls
