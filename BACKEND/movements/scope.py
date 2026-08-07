from django.db.models import Q, QuerySet

from accounts.permissions import ADMIN_ROLES

from .models import Movement


def user_display_name(user) -> str:
    full = f"{user.first_name} {user.last_name}".strip()
    return full or user.username


def is_admin_user(user) -> bool:
    if not user or not user.is_authenticated:
        return False
    if user.is_staff or user.is_superuser:
        return True
    profile = getattr(user, "profile", None)
    if profile is None:
        return False
    return (profile.role or "").strip().lower() in ADMIN_ROLES


def movements_visible_to(user, qs: QuerySet | None = None) -> QuerySet:
    """
    Staff see only their own movements.
    Administrators / managers see all store movements.
    """
    base = qs if qs is not None else Movement.objects.all()
    if is_admin_user(user):
        return base
    name = user_display_name(user)
    return base.filter(
        Q(created_by=user)
        | Q(requested_by__iexact=name)
        | Q(requested_by__iexact=user.username)
        | Q(requested_by__iexact=user.email)
    )
