from rest_framework import serializers
from .models import DailyLog


class DailyLogSerializer(serializers.ModelSerializer):
    """
    Serializer for DailyLog model.
    """

    class Meta:
        model = DailyLog
        fields = [
            'id',
            'date',
            'mood',
            'flow',
            'energy',
            'symptoms',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

    def validate_symptoms(self, value):
        """
        Ensure symptoms is a list of strings.
        """
        if not isinstance(value, list):
            raise serializers.ValidationError("Symptoms must be a list.")
        if not all(isinstance(item, str) for item in value):
            raise serializers.ValidationError("All symptoms must be strings.")
        return value

    def validate(self, data):
        """
        Validate that at least one field is provided.
        """
        if not any([data.get('mood'), data.get('flow'), data.get('energy'), data.get('symptoms')]):
            raise serializers.ValidationError(
                "At least one field (mood, flow, energy, or symptoms) must be provided."
            )
        return data
