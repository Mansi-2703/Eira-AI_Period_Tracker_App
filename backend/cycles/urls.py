from django.urls import path
from .views import CycleCreateView, CycleDetailView


urlpatterns = [
    path('create/', CycleCreateView.as_view()),
    path('log/<int:pk>/', CycleDetailView.as_view()),
]
