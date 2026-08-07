from django.urls import path
from rest_framework.routers import DefaultRouter

from .views import (
    ChangePasswordView,
    ForgotPasswordView,
    LoginView,
    LogoutView,
    MeView,
    RegisterView,
    ResetPasswordView,
    RotatingTokenRefreshView,
    UserViewSet,
    VerifyOTPView,
)

urlpatterns = [
    path("register/", RegisterView.as_view(), name="auth-register"),
    path("login/", LoginView.as_view(), name="auth-login"),
    path("logout/", LogoutView.as_view(), name="auth-logout"),
    path(
        "token/refresh/",
        RotatingTokenRefreshView.as_view(),
        name="token-refresh",
    ),
    path("me/", MeView.as_view(), name="auth-me"),
    path("password/forgot/", ForgotPasswordView.as_view(), name="password-forgot"),
    path(
        "password/verify-otp/",
        VerifyOTPView.as_view(),
        name="password-verify-otp",
    ),
    path("password/reset/", ResetPasswordView.as_view(), name="password-reset"),
    path("password/change/", ChangePasswordView.as_view(), name="password-change"),
]

users_router = DefaultRouter()
users_router.register("", UserViewSet, basename="users")
users_urlpatterns = users_router.urls
