import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../items/data/items_repository.dart';
import '../items/models/item.dart';
import '../items/widgets/search_box.dart';
import '../items/widgets/stock_status_badge.dart';
import '../../core/api/api_exception.dart';
import '../auth/data/auth_repository.dart';
import 'data/movements_repository.dart';
import 'models/movement.dart';
import 'movement_success_screen.dart';
import 'widgets/form_fields.dart';

/// Single-item stock movement form.
///
/// Doubles as the "Enter New Stock" (stock in) and "Issue Stock" (stock out)
/// screen — the direction is fixed by [type], so there is no movement-type
/// picker. An optional [item] pre-selects the inventory item (e.g. when opened
/// from a reorder alert).
class MovementFormScreen extends StatefulWidget {
  const MovementFormScreen({super.key, required this.type, this.item});

  final MovementType type;
  final Item? item;

  @override
  State<MovementFormScreen> createState() => _MovementFormScreenState();
}

class _MovementFormScreenState extends State<MovementFormScreen> {
  final TextEditingController _quantity = TextEditingController();
  final TextEditingController _notes = TextEditingController();

  Item? _item;
  String? _location;
  String? _reason;
  bool _showErrors = false;

  bool _submitting = false;

  bool get _isIn => widget.type == MovementType.stockIn;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
  }

  @override
  void dispose() {
    _quantity.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickItem() async {
    final Item? selected = await showModalBottomSheet<Item>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ItemPickerSheet(),
    );
    if (selected != null && mounted) setState(() => _item = selected);
  }

  int? get _quantityValue => int.tryParse(_quantity.text.trim());

  String? get _quantityError {
    if (!_showErrors) return null;
    final int? value = _quantityValue;
    if (value == null || value <= 0) return AppStrings.fieldRequired;
    return null;
  }

  bool get _isValid {
    final int? qty = _quantityValue;
    final bool reasonOk = _isIn || _reason != null;
    return _item != null && qty != null && qty > 0 && _location != null &&
        reasonOk;
  }

  Future<void> _save() async {
    if (!_isValid) {
      setState(() => _showErrors = true);
      return;
    }
    final Item item = _item!;
    final int qty = _quantityValue!;
    final String notes = _notes.text.trim();
    final String resolvedNotes = _isIn
        ? (notes.isEmpty ? '—' : notes)
        : <String>[
            ?_reason,
            if (notes.isNotEmpty) notes,
          ].join(' — ');

    final String requestedBy =
        AuthRepository.instance.currentUser?.displayName ?? 'Staff';

    setState(() => _submitting = true);
    try {
      if (ItemsRepository.isMemoryMode) {
        final String reference = MovementsRepository.nextReference();
        final Movement movement = Movement(
          id: '$reference-${item.code}',
          type: widget.type,
          itemName: item.name,
          itemCode: item.code,
          image: item.image,
          quantity: qty,
          date: DateTime.now(),
          referenceNo: reference,
          requestedBy: requestedBy,
          location: _location!,
          notes: resolvedNotes.isEmpty ? '—' : resolvedNotes,
          unit: item.unit,
          stockBefore: item.quantity,
        );
        MovementsRepository.record(<Movement>[movement]);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => MovementSuccessScreen(
              type: widget.type,
              reference: reference,
              recorded: <Movement>[movement],
            ),
          ),
        );
        return;
      }

      final Movement movement = await MovementsRepository.recordMovement(
        type: widget.type,
        itemCode: item.code,
        quantity: qty,
        requestedBy: requestedBy,
        location: _location,
        notes: resolvedNotes.isEmpty ? '—' : resolvedNotes,
        reason: _reason,
      );
      await ItemsRepository.refresh();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => MovementSuccessScreen(
            type: widget.type,
            reference: movement.referenceNo,
            recorded: <Movement>[movement],
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String unit = _item?.unit ?? 'Pcs';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(_isIn ? AppStrings.enterNewStock : AppStrings.issueStock),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
        children: <Widget>[
          LabeledField(
            label: AppStrings.selectItemLabel,
            required: true,
            child: _SelectItemField(
              item: _item,
              hasError: _showErrors && _item == null,
              onTap: _pickItem,
            ),
          ),
          const SizedBox(height: 18),
          LabeledField(
            label: AppStrings.quantityLabel,
            required: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _quantity,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (_) {
                      if (_showErrors) setState(() {});
                    },
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: AppStrings.quantityHint,
                      hintStyle: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14.5,
                      ),
                      filled: true,
                      fillColor: AppColors.fieldFill,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      errorText: _quantityError,
                      enabledBorder: _border(AppColors.border),
                      focusedBorder: _border(AppColors.navy, width: 1.5),
                      border: _border(AppColors.border),
                      errorBorder: _border(AppColors.red),
                      focusedErrorBorder: _border(AppColors.red, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.fieldFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    unit,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!_isIn) ...<Widget>[
            const SizedBox(height: 18),
            LabeledDropdown<String>(
              label: AppStrings.purposeReasonLabel,
              required: true,
              hint: AppStrings.selectReasonHint,
              value: _reason,
              items: MovementsRepository.reasons,
              labelOf: (String v) => v,
              errorText: _showErrors && _reason == null
                  ? AppStrings.fieldRequired
                  : null,
              onChanged: (String? v) => setState(() => _reason = v),
            ),
          ],
          const SizedBox(height: 18),
          LabeledDropdown<String>(
            label: AppStrings.locationLabel,
            required: true,
            hint: AppStrings.selectLocation,
            value: _location,
            items: MovementsRepository.locations,
            labelOf: (String v) => v,
            errorText: _showErrors && _location == null
                ? AppStrings.fieldRequired
                : null,
            onChanged: (String? v) => setState(() => _location = v),
          ),
          const SizedBox(height: 18),
          LabeledField(
            label: AppStrings.notesLabel,
            child: TextField(
              controller: _notes,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: AppStrings.optionalNotesHint,
                hintStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14.5,
                ),
                filled: true,
                fillColor: AppColors.fieldFill,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                enabledBorder: _border(AppColors.border),
                focusedBorder: _border(AppColors.navy, width: 1.5),
                border: _border(AppColors.border),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Row(
          children: <Widget>[
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    AppStrings.cancel,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    AppStrings.saveCta,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

/// A dropdown-styled field that opens the searchable item picker on tap.
class _SelectItemField extends StatelessWidget {
  const _SelectItemField({
    required this.item,
    required this.hasError,
    required this.onTap,
  });

  final Item? item;
  final bool hasError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool hasValue = item != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError ? AppColors.red : AppColors.border,
                width: hasError ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    hasValue ? item!.name : AppStrings.selectItemHint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasValue ? AppColors.navy : AppColors.textMuted,
                      fontSize: 15,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
        if (hasError)
          const Padding(
            padding: EdgeInsets.only(left: 12, top: 6),
            child: Text(
              AppStrings.fieldRequired,
              style: TextStyle(color: AppColors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

/// A searchable, scrollable bottom sheet for picking an inventory item.
///
/// Filters the catalogue live by name/code so it scales to large catalogues.
class _ItemPickerSheet extends StatefulWidget {
  const _ItemPickerSheet();

  @override
  State<_ItemPickerSheet> createState() => _ItemPickerSheetState();
}

class _ItemPickerSheetState extends State<_ItemPickerSheet> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final double maxHeight = media.size.height * 0.9 - media.viewInsets.bottom;
    final List<Item> items = ItemsRepository.query(search: _search.text);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: maxHeight > 280 ? maxHeight : media.size.height * 0.6,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: <Widget>[
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
                  child: Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          AppStrings.selectItemLabel,
                          style: TextStyle(
                            color: AppColors.navy,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        color: AppColors.textMuted,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: SearchBox(
                    hintText: AppStrings.searchHint,
                    controller: _search,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    onClear: () => setState(() => _search.clear()),
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? const Center(
                          child: Text(
                            AppStrings.noItemsFound,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 15,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 1,
                            color: AppColors.border,
                          ),
                          itemBuilder: (BuildContext context, int index) {
                            final Item item = items[index];
                            return _ItemPickerTile(
                              item: item,
                              onTap: () => Navigator.of(context).pop(item),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemPickerTile extends StatelessWidget {
  const _ItemPickerTile({required this.item, required this.onTap});

  final Item item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                item.image,
                width: 46,
                height: 46,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 46,
                  height: 46,
                  color: AppColors.fieldFill,
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.code} · ${item.quantity} ${item.unit}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            StockStatusBadge(status: item.status),
          ],
        ),
      ),
    );
  }
}
