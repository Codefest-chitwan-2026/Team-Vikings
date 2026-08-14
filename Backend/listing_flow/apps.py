from django.apps import AppConfig


class ListingFlowConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "listing_flow"
    verbose_name = "Listing Flow"

    def ready(self):
        import listing_flow.signals  # noqa: F401
