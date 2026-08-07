"""CSV / PDF builders for report exports."""

from __future__ import annotations

import csv
import io
from datetime import datetime

from django.http import HttpResponse


def _stamp() -> str:
    return datetime.now().strftime("%Y%m%d_%H%M%S")


def csv_response(filename: str, headers: list[str], rows: list[list]) -> HttpResponse:
    buf = io.StringIO()
    writer = csv.writer(buf)
    writer.writerow(headers)
    for row in rows:
        writer.writerow(row)
    # UTF-8 BOM so Excel opens encoding correctly
    content = "\ufeff" + buf.getvalue()
    response = HttpResponse(content, content_type="text/csv; charset=utf-8")
    response["Content-Disposition"] = f'attachment; filename="{filename}"'
    return response


def pdf_table_response(
    filename: str,
    title: str,
    headers: list[str],
    rows: list[list],
    subtitle: str | None = None,
) -> HttpResponse:
    from reportlab.lib import colors
    from reportlab.lib.pagesizes import A4, landscape
    from reportlab.lib.styles import getSampleStyleSheet
    from reportlab.lib.units import mm
    from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

    buf = io.BytesIO()
    doc = SimpleDocTemplate(
        buf,
        pagesize=landscape(A4),
        leftMargin=12 * mm,
        rightMargin=12 * mm,
        topMargin=14 * mm,
        bottomMargin=14 * mm,
    )
    styles = getSampleStyleSheet()
    story = [Paragraph(title, styles["Heading1"])]
    if subtitle:
        story.append(Paragraph(subtitle, styles["Normal"]))
    story.append(Spacer(1, 8))

    data = [headers] + [[("" if c is None else str(c)) for c in row] for row in rows]
    table = Table(data, repeatRows=1)
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#0B2A4A")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("FONTSIZE", (0, 0), (-1, -1), 9),
                ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#CBD5E1")),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F8FAFC")]),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("LEFTPADDING", (0, 0), (-1, -1), 6),
                ("RIGHTPADDING", (0, 0), (-1, -1), 6),
                ("TOPPADDING", (0, 0), (-1, -1), 5),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
            ]
        )
    )
    story.append(table)
    doc.build(story)
    response = HttpResponse(buf.getvalue(), content_type="application/pdf")
    response["Content-Disposition"] = f'attachment; filename="{filename}"'
    return response


def stock_summary_export(data: dict, fmt: str) -> HttpResponse:
    headers = [
        "Category",
        "Total Items",
        "Total Quantity",
        "Stock Value (GBP)",
        "Out of Stock",
        "Low Stock",
    ]
    rows = []
    for row in data.get("by_category", []):
        rows.append(
            [
                row["category"],
                row["total_items"],
                row["total_quantity"],
                row.get("stock_value") or "-",
                row["out_of_stock"],
                row["low_stock"],
            ]
        )
    totals = data.get("totals") or {}
    if totals:
        rows.append(
            [
                "Total",
                totals.get("total_items", ""),
                totals.get("total_quantity", ""),
                totals.get("stock_value") or "-",
                totals.get("out_of_stock", ""),
                totals.get("low_stock", ""),
            ]
        )
    name = f"stock_summary_{_stamp()}"
    if fmt == "pdf":
        return pdf_table_response(
            f"{name}.pdf",
            "Stock Summary Report",
            headers,
            rows,
            subtitle=(
                f"Items: {data.get('total_items', 0)} · "
                f"Qty: {data.get('total_quantity', 0)} · "
                f"Out of stock: {data.get('out_of_stock', 0)} · "
                f"Low stock: {data.get('low_stock', 0)}"
            ),
        )
    return csv_response(f"{name}.csv", headers, rows)


def stock_movement_export(data: dict, fmt: str) -> HttpResponse:
    headers = [
        "Date",
        "Stock In (Qty)",
        "Stock Out (Qty)",
        "Net Movement",
        "Transactions",
    ]
    rows = [
        [
            row["label"],
            row["stock_in"],
            row["stock_out"],
            row["net"],
            row["transactions"],
        ]
        for row in data.get("series", [])
    ]
    totals = data.get("totals") or {}
    if totals:
        rows.append(
            [
                "Total",
                totals.get("stock_in", ""),
                totals.get("stock_out", ""),
                totals.get("net", ""),
                totals.get("transactions", ""),
            ]
        )
    name = f"stock_movement_{data.get('period', 'daily')}_{_stamp()}"
    subtitle = (
        f"Period: {data.get('period', '')} · "
        f"{data.get('from_date', '')} to {data.get('to_date', '')}"
    )
    if fmt == "pdf":
        return pdf_table_response(
            f"{name}.pdf", "Stock Movement Report", headers, rows, subtitle=subtitle
        )
    return csv_response(f"{name}.csv", headers, rows)


def users_export(rows_data: list[dict], fmt: str) -> HttpResponse:
    headers = ["Name", "Email", "Role", "Status", "Last Login"]
    rows = [
        [
            r.get("name") or "",
            r.get("email") or "",
            r.get("role") or "",
            r.get("status") or "",
            r.get("last_login_display") or "-",
        ]
        for r in rows_data
    ]
    name = f"users_{_stamp()}"
    if fmt == "pdf":
        return pdf_table_response(
            f"{name}.pdf",
            "Users Report",
            headers,
            rows,
            subtitle=f"{len(rows)} user(s)",
        )
    return csv_response(f"{name}.csv", headers, rows)
