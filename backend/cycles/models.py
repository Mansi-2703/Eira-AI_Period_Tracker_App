from django.db import models
from django.contrib.auth.models import User

class Cycle(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    start_date = models.DateField()
    cycle_length = models.IntegerField()
    period_length = models.IntegerField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return (
            f"{self.user.username} | "
            f"Start: {self.start_date} | "
            f"Cycle: {self.cycle_length}d | "
            f"Period: {self.period_length}d"
        )
    class Meta:
        unique_together = ('user', 'start_date')