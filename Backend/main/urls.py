from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static


urlpatterns = [
    path("admin/", admin.site.urls),

    path("api/auth/", include("authentication.urls")),
    path("api/", include("donations.urls")),
    path("api/", include("listing_flow.urls")),
    # path("api/profiles/", include("profiles.urls")),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
