from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from cycles.models import Cycle
from .utils import predict_next_period, get_menstrual_phase

class PredictionView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        cycles = Cycle.objects.filter(
            user=request.user
        ).order_by('-start_date')

        if not cycles.exists():
            return Response({"message": "Not enough data"})

        last_cycle = cycles.first()

        predicted_date, confidence, model_used, quiz_completed, quiz_insights = predict_next_period(
            cycles,
            request.user
        )

        phase_data = get_menstrual_phase(
            last_period_start=last_cycle.start_date,
            cycle_length=last_cycle.cycle_length,
            period_length=last_cycle.period_length
        )

        return Response({
            "predicted_next_period": predicted_date,
            **phase_data,
            "confidence": confidence,
            "based_on_cycles": cycles.count(),
            "model_used": model_used,
            "quiz_completed": quiz_completed,
            "quiz_insights": quiz_insights or {},
        })
