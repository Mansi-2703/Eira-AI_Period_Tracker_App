from rest_framework import serializers
from .models import MenstrualHealthProfile


class MenstrualHealthProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = MenstrualHealthProfile
        exclude = ["user", "created_at"]
