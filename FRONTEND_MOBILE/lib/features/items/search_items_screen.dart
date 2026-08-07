import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_snackbar.dart';
import 'data/items_repository.dart';
import 'item_details_screen.dart';
import 'models/item.dart';
import 'widgets/item_card.dart';
import 'widgets/search_box.dart';

/// Dedicated search screen with a live, name/code-based filter.
class SearchItemsScreen extends StatefulWidget {
  const SearchItemsScreen({super.key});

  @override
  State<SearchItemsScreen> createState() => _SearchItemsScreenState();
}

class _SearchItemsScreenState extends State<SearchItemsScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openDetails(Item item) async {
    final ItemDetailsResult? result = await Navigator.of(context).push(
      MaterialPageRoute<ItemDetailsResult>(
        builder: (_) => ItemDetailsScreen(item: item),
      ),
    );
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final List<Item> results = ItemsRepository.query(search: _query);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(AppStrings.searchItemsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: SearchBox(
              controller: _controller,
              hintText: AppStrings.searchHint,
              autofocus: true,
              onChanged: (String value) => setState(() => _query = value),
              onClear: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? const _EmptyResults()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: results.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Item item = results[index];
                      return ItemCard(
                        item: item,
                        onTap: () => _openDetails(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.search_off_rounded, size: 52, color: AppColors.textMuted),
          SizedBox(height: 12),
          Text(
            AppStrings.noItemsFound,
            style: TextStyle(color: AppColors.textMuted, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
