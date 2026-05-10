import 'package:flutter/material.dart';
import '../../../core/theme/halo_theme.dart';
import '../models/product_model.dart';
import '../services/product_services.dart';
import 'product_detail_screen.dart';

class CategoryScreen extends StatefulWidget {
  final CategoryModel category;
  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _service = ProductServices();
  List<ProductModel> _products = [];
  bool _loading = true;
  String _ordering = '-created_at';
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getProducts(
        category: widget.category.id,
        ordering: _ordering,
      );
      if (mounted) {
        setState(() {
          _products = data['results'] as List<ProductModel>;
          _total = data['count'] as int;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Halo.bg,
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 140,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: Halo.cardShadow,
                  ),
                  child: const Icon(Icons.arrow_back, size: 20, color: Halo.ink),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: Halo.cardShadow,
                    ),
                    child: const Icon(Icons.favorite_border, size: 18, color: Halo.ink),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Halo.sage.withValues(alpha: 0.55),
                      Halo.mint.withValues(alpha: 0.35),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 80, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text('HALO · HOME',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                              letterSpacing: 1.5, color: Halo.inkMuted)),
                      const SizedBox(height: 4),
                      Text(widget.category.name,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                              color: Halo.ink, letterSpacing: -0.3)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Sub-filter chips ───────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 0, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _Chip(label: 'All · $_total', selected: true),
                    const SizedBox(width: 8),
                    _Chip(label: 'New arrivals'),
                    const SizedBox(width: 8),
                    _Chip(label: 'On sale'),
                    const SizedBox(width: 8),
                    _Chip(label: 'In stock'),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ),
          ),

          // ── Sort bar ──────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 0, 16, 10),
              child: Row(
                children: [
                  Text('Sorted by ', style: const TextStyle(fontSize: 13, color: Halo.inkMuted)),
                  GestureDetector(
                    onTap: () => _showSortSheet(context),
                    child: Row(
                      children: [
                        Text(
                          _orderingLabel,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Halo.ink),
                        ),
                        const Icon(Icons.keyboard_arrow_down, size: 18, color: Halo.ink),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Grid toggle (decorative)
                  Icon(Icons.grid_view_rounded, size: 20, color: Halo.inkMuted),
                  const SizedBox(width: 12),
                  Icon(Icons.tune, size: 20, color: Halo.inkMuted),
                ],
              ),
            ),
          ),

          // ── Grid ──────────────────────────────────────
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: Halo.ink, strokeWidth: 1.5)),
            )
          else if (_products.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text('No products', style: TextStyle(color: Halo.inkMuted)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _CatProductCard(product: _products[i]),
                  childCount: _products.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String get _orderingLabel {
    switch (_ordering) {
      case '-created_at': return 'New arrivals';
      case 'price': return 'Price: Low → High';
      case '-price': return 'Price: High → Low';
      default: return 'New arrivals';
    }
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sort by', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Halo.ink)),
            const SizedBox(height: 16),
            for (final opt in [
              ('-created_at', 'New arrivals'),
              ('price', 'Price: Low → High'),
              ('-price', 'Price: High → Low'),
              ('name', 'Name A → Z'),
            ])
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(opt.$2, style: const TextStyle(fontSize: 15, color: Halo.ink)),
                trailing: _ordering == opt.$1
                    ? const Icon(Icons.check, size: 18, color: Halo.ink)
                    : null,
                onTap: () {
                  setState(() => _ordering = opt.$1);
                  Navigator.pop(context);
                  _load();
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  const _Chip({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? Halo.ink : Colors.transparent,
        borderRadius: Halo.pill,
        border: Border.all(color: selected ? Halo.ink : Halo.border),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500,
              color: selected ? Colors.white : Halo.ink)),
    );
  }
}

// ── Category product card ─────────────────────────────────────
class _CatProductCard extends StatefulWidget {
  final ProductModel product;
  const _CatProductCard({required this.product});

  @override
  State<_CatProductCard> createState() => _CatProductCardState();
}

class _CatProductCardState extends State<_CatProductCard> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: widget.product.id)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: Halo.card,
          boxShadow: Halo.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(gradient: Halo.productGradient(widget.product.id)),
                    ),
                  ),
                  // Heart
                  Positioned(
                    top: 10, right: 10,
                    child: GestureDetector(
                      onTap: () => setState(() => _saved = !_saved),
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.90),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _saved ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: _saved ? const Color(0xFFD4909E) : Halo.inkMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((widget.product.categoryName ?? '').toUpperCase(),
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                          letterSpacing: 1.2, color: Halo.inkMuted)),
                  const SizedBox(height: 3),
                  Text(widget.product.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Halo.ink),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('\$${widget.product.price.toStringAsFixed(0)}',
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
