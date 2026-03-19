from django.db import models
from django.contrib.auth.models import User


class DailyLog(models.Model):
    """
    Daily log for tracking mood, flow, energy, and symptoms.
    """

    MOOD_CHOICES = [
        ('happy', 'Happy'),
        ('calm', 'Calm'),
        ('sad', 'Sad'),
        ('anxious', 'Anxious'),
        ('irritable', 'Irritable'),
        ('tired', 'Tired'),
    ]

    FLOW_CHOICES = [
        ('light', 'Light'),
        ('medium', 'Medium'),
        ('heavy', 'Heavy'),
        ('none', 'None'),
    ]

    ENERGY_CHOICES = [
        ('high', 'High'),
        ('medium', 'Medium'),
        ('low', 'Low'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='daily_logs')
    date = models.DateField(db_index=True)

    # Log fields
    mood = models.CharField(max_length=20, choices=MOOD_CHOICES, null=True, blank=True)
    flow = models.CharField(max_length=20, choices=FLOW_CHOICES, null=True, blank=True)
    energy = models.CharField(max_length=20, choices=ENERGY_CHOICES, null=True, blank=True)

    # Symptoms stored as JSON array
    symptoms = models.JSONField(default=list, blank=True)

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-date']
        unique_together = ['user', 'date']  # One log per user per day
        verbose_name = 'Daily Log'
        verbose_name_plural = 'Daily Logs'

    def __str__(self):
        return f"{self.user.username} - {self.date}"
