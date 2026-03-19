from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from datetime import datetime

from .models import DailyLog
from .serializers import DailyLogSerializer


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def daily_log_create_list(request):
    """
    GET: List all daily logs for the authenticated user.
    POST: Create or update a daily log for a specific date.
    """
    if request.method == 'GET':
        # Get query parameters for filtering
        start_date = request.query_params.get('start_date')
        end_date = request.query_params.get('end_date')
        limit = request.query_params.get('limit', 30)

        logs = DailyLog.objects.filter(user=request.user)

        # Apply date filters if provided
        if start_date:
            logs = logs.filter(date__gte=start_date)
        if end_date:
            logs = logs.filter(date__lte=end_date)

        # Limit results
        try:
            limit = int(limit)
            logs = logs[:limit]
        except (ValueError, TypeError):
            logs = logs[:30]

        serializer = DailyLogSerializer(logs, many=True)
        return Response(serializer.data)

    elif request.method == 'POST':
        # Extract date from request
        log_date = request.data.get('date')

        if not log_date:
            return Response(
                {'error': 'Date is required.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Try to parse the date
        try:
            parsed_date = datetime.fromisoformat(log_date.replace('Z', '+00:00')).date()
        except (ValueError, AttributeError):
            return Response(
                {'error': 'Invalid date format. Use ISO 8601 format.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Get or create the log for this date
        log, created = DailyLog.objects.get_or_create(
            user=request.user,
            date=parsed_date,
            defaults={
                'mood': request.data.get('mood'),
                'flow': request.data.get('flow'),
                'energy': request.data.get('energy'),
                'symptoms': request.data.get('symptoms', []),
            }
        )

        # If log already exists, update it
        if not created:
            log.mood = request.data.get('mood', log.mood)
            log.flow = request.data.get('flow', log.flow)
            log.energy = request.data.get('energy', log.energy)
            log.symptoms = request.data.get('symptoms', log.symptoms)
            log.save()

        serializer = DailyLogSerializer(log)
        return Response(
            serializer.data,
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK
        )


@api_view(['GET', 'PUT', 'DELETE'])
@permission_classes([IsAuthenticated])
def daily_log_detail(request, log_id):
    """
    GET: Retrieve a specific daily log.
    PUT: Update a specific daily log.
    DELETE: Delete a specific daily log.
    """
    log = get_object_or_404(DailyLog, id=log_id, user=request.user)

    if request.method == 'GET':
        serializer = DailyLogSerializer(log)
        return Response(serializer.data)

    elif request.method == 'PUT':
        serializer = DailyLogSerializer(log, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    elif request.method == 'DELETE':
        log.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def daily_log_by_date(request, date):
    """
    GET: Retrieve a daily log by date.
    """
    try:
        log = DailyLog.objects.get(user=request.user, date=date)
        serializer = DailyLogSerializer(log)
        return Response(serializer.data)
    except DailyLog.DoesNotExist:
        return Response(
            {'error': 'No log found for this date.'},
            status=status.HTTP_404_NOT_FOUND
        )
