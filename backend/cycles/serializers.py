from rest_framework import serializers
from .models import Cycle

class CycleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Cycle
        fields = ['id', 'start_date', 'cycle_length', 'period_length']
        
    def create(self, validated_data):
        user = self.context['request'].user
        return Cycle.objects.create(user=user, **validated_data)

    def validate_cycle_length(self, value):
        if value < 20 or value > 45:
            raise serializers.ValidationError(
                "Cycle length must be between 20 and 45 days."
            )
        return value

    def validate_period_length(self, value):
        if value < 2 or value > 10:
            raise serializers.ValidationError(
                "Period length must be between 2 and 10 days."
            )
        return value
