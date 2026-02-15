from django.urls import path
from .views import QuizProfileView, QuizSubmitView

urlpatterns = [
    path("submit/", QuizSubmitView.as_view()),
    path("profile/", QuizProfileView.as_view()),
]
