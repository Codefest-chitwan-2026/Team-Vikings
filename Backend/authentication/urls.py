from rest_framework.routers import DefaultRouter

from .views import (
    CustomerProfileViewSet,
    BusinessProfileViewSet,
    NGOProfileViewSet,
)

router = DefaultRouter()

router.register(
    "register/customer",
    CustomerProfileViewSet,
    basename="customer"
)

router.register(
    "register/business",
    BusinessProfileViewSet,
    basename="business"
)

router.register(
    "register/ngo",
    NGOProfileViewSet,
    basename="ngo"
)

urlpatterns = router.urls