from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status

from .models import MenstrualHealthProfile
from .serializers import MenstrualHealthProfileSerializer


DEFAULT_QUIZ_VALUES = {
    # Flow & bleeding pattern
    "flow_intensity": 3,
    "pad_change_frequency": 3,
    "flooding": 0,
    "clot_size": 0,
    
    # Duration & consistency
    "period_duration": 5,
    "flow_pattern": 2,
    "spotting_between": 0,
    
    # Cycle regularity
    "cycle_regular": 2,
    "avg_cycle_group": 2,
    "missed_periods": 0,
    
    # Pain
    "pain_level": 1,
    "pain_interference": 1,
    "pain_location": "lower_abdomen",
    "pain_type": "cramping",
    
    # PMS/PMDD symptoms
    "pms_mood_swings": 0,
    "pms_irritability": 0,
    "pms_depression_anxiety": 0,
    "pms_breast_tenderness": False,
    "pms_bloating": False,
    "pms_joint_muscle_pain": False,
    "pms_acne_breakouts": False,
    
    # General symptoms
    "fatigue": False,
    "dizziness": False,
    "nausea": False,
    "headaches": False,
    "brain_fog": False,
    
    # Emotional
    "mood_changes": 1,
    "mood_impact": 1,
    
    # Medical conditions
    "pcos": False,
    "endometriosis": False,
    "uterine_fibroids": False,
    "thyroid": False,
    "anemia_history": 0,
    
    # Lifestyle factors
    "stress_level": 2,
    "exercise_frequency": 2,
    "sleep_quality": 2,
    "weight_changes": "stable",
    
    # Settings
    "wants_health_alerts": True,
}


class QuizSubmitView(APIView):
    permission_classes = [IsAuthenticated]

    def _prepare_payload(self, data):
        payload = DEFAULT_QUIZ_VALUES.copy()
        payload.update(data or {})
        return payload

    def post(self, request):
        payload = self._prepare_payload(request.data)
        # Try to fetch existing profile
        try:
            profile = MenstrualHealthProfile.objects.get(user=request.user)
            serializer = MenstrualHealthProfileSerializer(
                profile,
                data=payload,
                partial=True
            )
        except MenstrualHealthProfile.DoesNotExist:
            serializer = MenstrualHealthProfileSerializer(
                data=payload
            )

        if serializer.is_valid():
            serializer.save(
                user=request.user,
                completed=True
            )
            return Response(
                {"message": "Quiz saved successfully"},
                status=status.HTTP_200_OK
            )

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class QuizProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            profile = MenstrualHealthProfile.objects.get(user=request.user)
            serializer = MenstrualHealthProfileSerializer(profile)
            return Response(
                {
                    "completed": profile.completed,
                    **serializer.data,
                }
            )
        except MenstrualHealthProfile.DoesNotExist:
            return Response({"completed": False})
