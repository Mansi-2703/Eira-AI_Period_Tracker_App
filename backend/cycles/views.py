from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status
from rest_framework.generics import RetrieveUpdateAPIView
from .models import Cycle
from .serializers import CycleSerializer

class CycleCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        cycles = Cycle.objects.filter(user=request.user).order_by('-start_date')
        serializer = CycleSerializer(cycles, many=True)
        return Response(serializer.data)

    def post(self, request):
        serializer = CycleSerializer(data=request.data,context={'request': request})
        if serializer.is_valid():
            serializer.save()
            return Response( {"message": "Cycle saved successfully"}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class CycleDetailView(RetrieveUpdateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = CycleSerializer

    def get_queryset(self):
        return Cycle.objects.filter(user=self.request.user)
