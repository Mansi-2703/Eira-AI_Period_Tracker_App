from django.urls import path
from .views import ProfileView, RegisterView, UsernameExistsView
from rest_framework_simplejwt.views import TokenObtainPairView

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', TokenObtainPairView.as_view(), name='login'),
    path('profile/', ProfileView.as_view(), name='profile'),
    path('exists/', UsernameExistsView.as_view(), name='username_exists'),
]
