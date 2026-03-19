from django.contrib import admin
from .models import DailyLog


@admin.register(DailyLog)
class DailyLogAdmin(admin.ModelAdmin):
    list_display = ['user', 'date', 'mood', 'flow', 'energy', 'created_at']
    list_filter = ['date', 'mood', 'flow', 'energy']
    search_fields = ['user__username', 'date']
    ordering = ['-date']
    readonly_fields = ['created_at', 'updated_at']

    fieldsets = (
        ('User & Date', {
            'fields': ('user', 'date')
        }),
        ('Daily Data', {
            'fields': ('mood', 'flow', 'energy', 'symptoms')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
