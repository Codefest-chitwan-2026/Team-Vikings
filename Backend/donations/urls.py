from rest_framework.routers import DefaultRouter

from .views import (
    DonationViewSet,
    DonationClaimViewSet,
    ConsumerReservationViewSet,
)


router = DefaultRouter()

router.register("donations", DonationViewSet, basename="donation")
router.register("claims", DonationClaimViewSet, basename="donation-claim")
router.register(
    "reservations",
    ConsumerReservationViewSet,
    basename="consumer-reservation",
)

urlpatterns = router.urls
