from rest_framework.permissions import BasePermission

ADMIN_ROLES = {"administrator", "admin", "manager"}


class IsAdminRole(BasePermission):
    """Allow only staff with Administrator/Manager role (or Django is_staff)."""

    message = "Admin access required."

    def has_permission(self, request, view) -> bool:
        user = request.user
        if not user or not user.is_authenticated:
            return False
        if not user.is_active:
            return False
        if user.is_staff or user.is_superuser:
            return True
        profile = getattr(user, "profile", None)
        if profile is None:
            return False
        return (profile.role or "").strip().lower() in ADMIN_ROLES
