from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth.models import User

from .models import PasswordResetOTP, PasswordResetToken, UserProfile


class UserProfileInline(admin.StackedInline):
    model = UserProfile
    can_delete = False
    fields = (
        "role",
        "department",
        "phone",
        "account_status",
        "must_change_password",
        "password_changed_at",
    )
    readonly_fields = ("password_changed_at",)


class UserAdmin(BaseUserAdmin):
    inlines = (UserProfileInline,)


@admin.register(PasswordResetOTP)
class PasswordResetOTPAdmin(admin.ModelAdmin):
    list_display = ("email", "user", "created_at", "expires_at", "used", "attempt_count")
    list_filter = ("used",)
    search_fields = ("email", "user__username")
    readonly_fields = ("code_hash", "created_at")


@admin.register(PasswordResetToken)
class PasswordResetTokenAdmin(admin.ModelAdmin):
    list_display = ("user", "created_at", "expires_at", "used")
    list_filter = ("used",)
    readonly_fields = ("token_hash", "created_at")


admin.site.unregister(User)
admin.site.register(User, UserAdmin)
