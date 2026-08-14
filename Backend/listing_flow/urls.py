from rest_framework.routers import DefaultRouter

from .views import (
    ListingFlowViewSet,
    ClaimHoldViewSet,
    PickupQRViewSet,
    VerifyPickupViewSet,
)


router = DefaultRouter()

router.register("listing-flow", ListingFlowViewSet, basename="listing-flow")
router.register("claim-holds", ClaimHoldViewSet, basename="claim-hold")
router.register("pickup-qr", PickupQRViewSet, basename="pickup-qr")
router.register("verify-pickup", VerifyPickupViewSet, basename="verify-pickup")

urlpatterns = router.urls
