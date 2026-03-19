from django.urls import path
from . import views

urlpatterns = [
    path('', views.daily_log_create_list, name='daily-log-list-create'),
    path('<int:log_id>/', views.daily_log_detail, name='daily-log-detail'),
    path('date/<str:date>/', views.daily_log_by_date, name='daily-log-by-date'),
]
