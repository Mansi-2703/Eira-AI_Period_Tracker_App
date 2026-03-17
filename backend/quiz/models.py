from django.db import models
from django.contrib.auth.models import User

class MenstrualHealthProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)

    # =====================
    # FLOW & BLEEDING PATTERN (Menorrhagia detection)
    # =====================
    flow_intensity = models.IntegerField()      # 1–5 (1=light, 5=very heavy)
    pad_change_frequency = models.IntegerField()# 1–5 (1=few times, 5=hourly)
    flooding = models.IntegerField()            # 0–2 (0=none, 2=frequent)
    clot_size = models.IntegerField()           # 0–2 (0=none, 2=large)

    # Duration & consistency
    period_duration = models.IntegerField()     # days
    flow_pattern = models.IntegerField()        # 1–4 (1=stable, 4=very variable)
    spotting_between = models.IntegerField()    # 0–2 (Intermenstrual bleeding)

    # =====================
    # CYCLE REGULARITY (Irregular/Missed periods detection)
    # =====================
    cycle_regular = models.IntegerField()       # 1–4 (1=very regular, 4=very irregular)
    avg_cycle_group = models.IntegerField()     # 1–4 (1=short <24, 2=normal 24-38, 3=long 38+, 4=highly variable)
    missed_periods = models.IntegerField(default=0)  # 0–2 (0=never, 2=frequently)

    # =====================
    # PAIN (Dysmenorrhea detection)
    # =====================
    pain_level = models.IntegerField()          # 0–3 (0=none, 3=severe)
    pain_interference = models.IntegerField()   # 0–3 (0=none, 3=daily activities affected)
    pain_location = models.CharField(           # lower_abdomen, lower_back, thighs, all_of_above
        max_length=20, default="lower_abdomen"
    )
    pain_type = models.CharField(               # cramping, throbbing, aching, sharp
        max_length=20, default="cramping"
    )

    # =====================
    # PRE-MENSTRUAL SYMPTOMS (PMS/PMDD detection)
    # =====================
    pms_mood_swings = models.IntegerField(default=0)  # 0–3
    pms_irritability = models.IntegerField(default=0) # 0–3
    pms_depression_anxiety = models.IntegerField(default=0)  # 0–3 (PMDD indicator)
    pms_breast_tenderness = models.BooleanField(default=False)
    pms_bloating = models.BooleanField(default=False)
    pms_joint_muscle_pain = models.BooleanField(default=False)
    pms_acne_breakouts = models.BooleanField(default=False)

    # =====================
    # GENERAL SYMPTOMS
    # =====================
    fatigue = models.BooleanField(default=False)
    dizziness = models.BooleanField(default=False)
    nausea = models.BooleanField(default=False)
    headaches = models.BooleanField(default=False)
    brain_fog = models.BooleanField(default=False)

    # Emotional
    mood_changes = models.IntegerField()        # 0–3
    mood_impact = models.IntegerField()         # 0–2

    # =====================
    # MEDICAL CONDITIONS (Underlying causes)
    # =====================
    pcos = models.BooleanField(default=False)
    endometriosis = models.BooleanField(default=False)
    uterine_fibroids = models.BooleanField(default=False)
    thyroid = models.BooleanField(default=False)
    anemia_history = models.IntegerField(default=0)  # 0–2

    # =====================
    # LIFESTYLE FACTORS
    # =====================
    stress_level = models.IntegerField(default=2)  # 1–5 (1=low, 5=very high)
    exercise_frequency = models.IntegerField(default=2)  # 1–4 (1=none, 4=daily)
    sleep_quality = models.IntegerField(default=2)  # 1–4 (1=poor, 4=excellent)
    weight_changes = models.CharField(  # stable, recent_weight_loss, recent_weight_gain
        max_length=20, default="stable"
    )

    # =====================
    # GENERAL SETTINGS
    # =====================
    wants_health_alerts = models.BooleanField(default=True)
    completed = models.BooleanField(default=False)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
