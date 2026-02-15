from django.contrib import admin

from .models import MenstrualHealthProfile


@admin.register(MenstrualHealthProfile)
class MenstrualHealthProfileAdmin(admin.ModelAdmin):
    list_display = (
        "user",
        "completed",
        "period_duration",
        "flow_intensity",
        "cycle_regular",
        "created_at",
    )
    list_filter = ("completed", "flow_intensity", "cycle_regular", "wants_health_alerts")
    search_fields = ("user__username", "user__email")
    readonly_fields = ("created_at",)
