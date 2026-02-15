from django.db import models
from django.contrib.auth.models import User

class MenstrualHealthProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)

    # Flow
    flow_intensity = models.IntegerField()      # 1–5
    pad_change_frequency = models.IntegerField()# 1–5
    flooding = models.IntegerField()            # 0–2
    clot_size = models.IntegerField()           # 0–2

    # Duration & consistency
    period_duration = models.IntegerField()     # days
    flow_pattern = models.IntegerField()        # 1–4
    spotting_between = models.IntegerField()    # 0–2

    # Cycle regularity
    cycle_regular = models.IntegerField()       # 1–4
    avg_cycle_group = models.IntegerField()     # 1–4

    # Pain
    pain_level = models.IntegerField()           # 0–3
    pain_interference = models.IntegerField()   # 0–3

    # Symptoms
    fatigue = models.BooleanField(default=False)
    dizziness = models.BooleanField(default=False)
    nausea = models.BooleanField(default=False)
    headaches = models.BooleanField(default=False)

    # Emotional
    mood_changes = models.IntegerField()         # 0–3
    mood_impact = models.IntegerField()          # 0–2

    # History
    pcos = models.BooleanField(default=False)
    endometriosis = models.BooleanField(default=False)
    thyroid = models.BooleanField(default=False)
    anemia_history = models.IntegerField()       # 0–2

    wants_health_alerts = models.BooleanField(default=True)
    completed = models.BooleanField(default=False)

    created_at = models.DateTimeField(auto_now_add=True)
