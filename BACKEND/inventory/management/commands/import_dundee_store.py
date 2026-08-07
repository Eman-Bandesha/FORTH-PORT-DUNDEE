from pathlib import Path

import pandas as pd
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction

from inventory.models import Item

DEFAULT_XLS = Path(__file__).resolve().parents[4] / "Dundee Store List 29.05.26.xls"

LOCATION_LABEL = "Dundee Store"

UNIT_MAP = {
    "EA": "Each",
    "PR": "Pair",
    "BX": "Box",
    "LTR": "Litre",
    "PK": "Pack",
}


def _safe_int(value, default: int = 0) -> int:
    if value is None or (isinstance(value, float) and pd.isna(value)):
        return default
    try:
        return max(0, int(float(value)))
    except (TypeError, ValueError):
        return default


def _catalogue_code(raw) -> str:
    if raw is None or (isinstance(raw, float) and pd.isna(raw)):
        return ""
    return f"{int(float(raw)):010d}"


def _unit_label(raw: str) -> str:
    if not raw or (isinstance(raw, float) and pd.isna(raw)):
        return "Each"
    key = str(raw).strip().upper()
    return UNIT_MAP.get(key, key.title())


def _category(row) -> str:
    comments = row.get("Comments")
    if comments is not None and not (isinstance(comments, float) and pd.isna(comments)):
        text = str(comments).strip()
        if text:
            return text[:120]
    cat = row.get("Category Code")
    if cat is not None and not (isinstance(cat, float) and pd.isna(cat)):
        return str(int(cat)) if float(cat) == int(float(cat)) else str(cat)
    return "General"


def _description(row) -> str:
    parts = []
    short = row.get("Short Name Descripton") or row.get("Short Name Description")
    if short is not None and not (isinstance(short, float) and pd.isna(short)):
        parts.append(str(short).strip())
    comments = row.get("Comments")
    if comments is not None and not (isinstance(comments, float) and pd.isna(comments)):
        parts.append(str(comments).strip())
    bin_loc = row.get("Bin Location Code")
    if bin_loc is not None and not (isinstance(bin_loc, float) and pd.isna(bin_loc)):
        try:
            bin_str = str(int(bin_loc)) if float(bin_loc) == int(float(bin_loc)) else str(bin_loc)
        except (TypeError, ValueError):
            bin_str = str(bin_loc).strip()
        if bin_str:
            parts.append(f"Bin: {bin_str}")
    return " · ".join(p for p in parts if p)


class Command(BaseCommand):
    help = "Import items from Dundee Store List Excel (.xls) into the inventory database."

    def add_arguments(self, parser):
        parser.add_argument(
            "--file",
            type=str,
            default=str(DEFAULT_XLS),
            help="Path to Dundee Store List .xls file",
        )
        parser.add_argument(
            "--fresh",
            action="store_true",
            help="Delete all movements and items before import (full catalogue replace).",
        )
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Parse file and report counts without writing to the database.",
        )

    def handle(self, *args, **options):
        path = Path(options["file"])
        if not path.is_file():
            raise CommandError(f"File not found: {path}")

        df = pd.read_excel(path, sheet_name=0, header=0)
        df["code"] = df["Catalogue Code"].apply(_catalogue_code)
        df = df[df["code"] != ""]
        before = len(df)
        df = df.drop_duplicates(subset=["code"], keep="first")
        if len(df) < before:
            self.stdout.write(
                self.style.WARNING(
                    f"Skipped {before - len(df)} duplicate catalogue code row(s)."
                )
            )

        active_col = "Active Indicator"
        if active_col in df.columns:
            df = df[df[active_col].astype(str).str.upper().eq("Y")]

        if options["dry_run"]:
            self.stdout.write(f"Would import {len(df)} items from {path.name}")
            return

        with transaction.atomic():
            if options["fresh"]:
                from movements.models import Movement

                mov_count = Movement.objects.count()
                item_count = Item.objects.count()
                Movement.objects.all().delete()
                Item.objects.all().delete()
                self.stdout.write(
                    f"Removed {item_count} item(s) and {mov_count} movement(s)."
                )

            created = updated = 0
            for _, row in df.iterrows():
                code = row["code"]
                name = str(row["Local Description"]).strip()[:255]
                qty = _safe_int(row.get("Quantity on Hand"))
                reorder = _safe_int(row.get("Reorder Level"))
                defaults = {
                    "name": name,
                    "quantity": qty,
                    "category": _category(row),
                    "unit": _unit_label(row.get("Unit of Stock")),
                    "reorder_level": reorder,
                    "location": LOCATION_LABEL,
                    "description": _description(row)[:2000],
                    "image": "",
                }
                _, was_created = Item.objects.update_or_create(
                    code=code, defaults=defaults
                )
                if was_created:
                    created += 1
                else:
                    updated += 1

        self.stdout.write(
            self.style.SUCCESS(
                f"Import complete: {created} created, {updated} updated "
                f"({created + updated} total from {path.name})."
            )
        )
