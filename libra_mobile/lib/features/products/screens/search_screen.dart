import 'package:flutter/material.dart';
import '../../../core/theme/halo_theme.dart';
import '../models/product_model.dart';
import '../services/product_services.dart';
import 'product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _service = ProductServices();
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();

  List<ProductModel> _results = [];
  List<CategoryModel> _categories = [];
  List<String> _recent = ['linen shirt', 'stoneware mug', 'bouclé throw', 'tonal knit'];
  bool _loading = false;
  bool _hasFocus = false;
  String _query = '';

  static const _trending = ['Quiet wools', 'Linen sets', 'Slow ceramics', 'Tonal', 'Brass + walnut'];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _hasFocus = _focusNode.hasFocus));
    _service.getCategories().then((c) { if (mounted) setState(() => _categories = c); });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    setState(() { _query = q; _loading = true; });
    if (q.isEmpty) { setState(() { _results = []; _loading = false; }); return; }
    try {
      final data = await _service.getProducts(search: q);
      if (mounted) setState(() => _results = data['results'] as List<ProductModel>);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addRecent(String q) {
    if (q.isEmpty) return;
    setState(() {
      _recent.remove(q);
      _recent.insert(0, q);
      if (_recent.length > 6) _recent.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    return HaloBg(
      blobs: const [
        HaloBlob(color: Halo.blue,     dx: -0.7, dy: -0.8, r: 0.60),
        HaloBlob(color: Halo.lavender, dx:  0.7, dy: -0.7, r: 0.55),
      ],
      child: SafeArea(
        child: Column(
          children: [
            // ── Search bar ────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: Halo.pill,
                        boxShadow: Halo.cardShadow,
                      ),
                      child: TextField(
                        controller: _ctrl,
                        focusNode: _focusNode,
                        style: const TextStyle(fontSize: 15, color: Halo.ink),
                        decoration: InputDecoration(
                          hintText: 'Search for anything…',
                          hintStyle: const TextStyle(color: Halo.inkFaint, fontSize: 15),
                          prefixIcon: const Icon(Icons.search, color: Halo.inkMuted, size: 20),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.mic_none_outlined, color: Halo.inkMuted, size: 20),
                              const SizedBox(width: 6),
                              Icon(Icons.camera_alt_outlined, color: Halo.inkMuted, size: 20),
                              const SizedBox(width: 12),
                            ],
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onChanged: _search,
                        onSubmitted: (q) { _addRecent(q); _search(q); },
                        textInputAction: TextInputAction.search,
                      ),
                    ),
                  ),
                  if (_hasFocus || _query.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () {
                        _ctrl.clear();
                        _focusNode.unfocus();
                        setState(() { _query = ''; _results = []; });
                      },
                      child: const Text('Cancel',
                          style: TextStyle(color: Halo.ink, fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ],
              ),
            ),

            Expanded(
              child: _query.isNotEmpty
                  ? _ResultsList(results: _results, loading: _loading)
                  : _EmptyState(
                      recent: _recent,
                      trending: _trending,
                      categories: _categories,
                      onRecentTap: (q) { _ctrl.text = q; _search(q); },
                      onClearRecent: () => setState(() => _recent = []),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty/discovery state ─────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final List<String> recent, trending;
  final List<CategoryModel> categories;
  final ValueChanged<String> onRecentTap;
  final VoidCallback onClearRecent;

  const _EmptyState({
    required this.recent, required this.trending, required this.categories,
    required this.onRecentTap, required this.onClearRecent,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        if (recent.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Halo.ink)),
              TextButton(
                onPressed: onClearRecent,
                child: const Text('Clear', style: TextStyle(fontSize: 13, color: Halo.inkMuted)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...recent.map((q) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history, size: 18, color: Halo.inkMuted),
            title: Text(q, style: const TextStyle(fontSize: 14, color: Halo.ink)),
            trailing: const Icon(Icons.arrow_forward, size: 16, color: Halo.inkFaint),
            onTap: () => onRecentTap(q),
          )),
          const SizedBox(height: 24),
        ],

        const Text('Trending now',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Halo.ink)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: trending.map((t) => GestureDetector(
            onTap: () => onRecentTap(t),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: Halo.pill,
                border: Border.all(color: Halo.border),
                boxShadow: Halo.cardShadow,
              ),
              child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Halo.ink)),
            ),
          )).toList(),
        ),

        if (categories.isNotEmpty) ...[
          const SizedBox(height: 28),
          // Search by photo card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Halo.rose.withValues(alpha: 0.60), Halo.lavender.withValues(alpha: 0.50)],
              ),
              borderRadius: Halo.card,
            ),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Halo.rose.withValues(alpha: 0.80), Halo.mauve.withValues(alpha: 0.70)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Search by photo',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Halo.ink)),
                      SizedBox(height: 3),
                      Text('Snap anything · find the closest match',
                          style: TextStyle(fontSize: 12, color: Halo.inkMuted)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, size: 18, color: Halo.inkMuted),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Search results list ───────────────────────────────────────
class _ResultsList extends StatelessWidget {
  final List<ProductModel> results;
  final bool loading;
  const _ResultsList({required this.results, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: Halo.ink, strokeWidth: 1.5));
    }
    if (results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_outlined, size: 56, color: Halo.inkFaint),
            SizedBox(height: 12),
            Text('No results found', style: TextStyle(fontSize: 16, color: Halo.inkMuted)),
            SizedBox(height: 4),
            Text('Try a different term', style: TextStyle(fontSize: 13, color: Halo.inkFaint)),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 12, mainAxisSpacing: 12,
      ),
      itemCount: results.length,
      itemBuilder: (_, i) => _SearchResultCard(product: results[i]),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final ProductModel product;
  const _SearchResultCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.id)),
      ),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: Halo.card, boxShadow: Halo.cardShadow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(gradient: Halo.productGradient(product.id)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((product.categoryName ?? '').toUpperCase(),
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                          letterSpacing: 1.2, color: Halo.inkMuted)),
                  const SizedBox(height: 3),
                  Text(product.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Halo.ink),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('\$${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Halo.ink)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

