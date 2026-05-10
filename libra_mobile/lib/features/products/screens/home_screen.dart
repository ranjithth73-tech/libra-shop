import 'package:flutter/material.dart';
import '../../../core/theme/halo_theme.dart';
import '../models/product_model.dart';
import '../services/product_services.dart';
import 'category_screen.dart';
import 'product_detail_screen.dart';
import 'stylist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = ProductServices();
  List<ProductModel> _featured = [];
  List<CategoryModel> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _service.getCategories(),
        _service.getProducts(ordering: '-created_at'),
      ]);
      if (mounted) {
        setState(() {
          _categories = results[0] as List<CategoryModel>;
          final data = results[1] as Map<String, dynamic>;
          _featured = (data['results'] as List<ProductModel>).take(6).toList();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _headline {
    final h = DateTime.now().hour;
    if (h < 10) return 'Soft starts,\nslower choices.';
    if (h < 14) return 'Curate your\nworld quietly.';
    if (h < 18) return 'Objects that\noutlast trends.';
    return 'Wind down\nwith intention.';
  }

  @override
  Widget build(BuildContext context) {
    return HaloBg(
      blobs: HaloBg.home,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: Halo.ink,
          child: CustomScrollView(
            slivers: [
              // ── Header ────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      // Location chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.80),
                          borderRadius: Halo.pill,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on_outlined, size: 14, color: Halo.inkMuted),
                            SizedBox(width: 4),
                            Text('Discover', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Halo.ink)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Notification
                      _HeaderIconBtn(icon: Icons.notifications_none_outlined),
                      const SizedBox(width: 8),
                      // Bag shortcut (no action needed — bottom nav handles it)
                      _HeaderIconBtn(icon: Icons.shopping_bag_outlined),
                    ],
                  ),
                ),
              ),

              // ── Greeting + hero ───────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_greeting,
                          style: const TextStyle(fontSize: 13, color: Halo.inkMuted, letterSpacing: 0.2)),
                      const SizedBox(height: 6),
                      Text(_headline,
                          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700,
                              color: Halo.ink, height: 1.15, letterSpacing: -0.5)),
                      const SizedBox(height: 20),
                      // Hero product
                      _HeroCard(
                        product: _featured.isNotEmpty ? _featured.first : null,
                        loading: _loading,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Collections row ───────────────────────────
              SliverToBoxAdapter(child: _CollectionsRow(categories: _categories, loading: _loading)),

              // ── Ask the Stylist card ──────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: GestureDetector(
                    onTap: () {
                      // Navigate to For You tab (index 2)
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const StylistScreen()));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: Halo.card,
                        boxShadow: Halo.cardShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFD4909E), Color(0xFFBAAED4)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Ask the Stylist',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Halo.ink)),
                                SizedBox(height: 2),
                                Text('Describe a feeling. We\'ll dress it.',
                                    style: TextStyle(fontSize: 12, color: Halo.inkMuted)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Halo.ink,
                              borderRadius: Halo.pill,
                            ),
                            child: const Text('Try',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Featured products (small grid) ────────────
              if (_featured.length > 1) ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('New arrivals',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Halo.ink)),
                        TextButton(
                          onPressed: () {},
                          child: const Text('See all',
                              style: TextStyle(fontSize: 13, color: Halo.inkMuted)),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final p = _featured.skip(1).toList()[i];
                        return _ProductCard(product: p);
                      },
                      childCount: (_featured.length - 1).clamp(0, 4),
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero card ─────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final ProductModel? product;
  final bool loading;
  const _HeroCard({this.product, required this.loading});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: product == null ? null : () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product!.id)),
      ),
      child: Container(
        height: 190,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: Halo.card,
          gradient: product != null
              ? Halo.productGradient(product!.id)
              : const LinearGradient(colors: [Color(0xFFE0D8D0), Color(0xFFD0C8C0)]),
          boxShadow: Halo.cardShadow,
        ),
        child: loading
            ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5))
            : product != null
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          (product!.categoryName ?? '').toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                              letterSpacing: 1.5, color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product!.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                              color: Colors.white, height: 1.2),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '\$${product!.price.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(),
      ),
    );
  }
}

// ── Collections row ───────────────────────────────────────────
class _CollectionsRow extends StatelessWidget {
  final List<CategoryModel> categories;
  final bool loading;
  const _CollectionsRow({required this.categories, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(height: 140,
          child: Center(child: CircularProgressIndicator(color: Halo.ink, strokeWidth: 1.5)));
    }
    if (categories.isEmpty) return const SizedBox();

    final cols = [
      [Halo.lavender, Halo.blue],
      [Halo.rose, Halo.mauve],
      [Halo.sage, Halo.mint],
      [Halo.butter, Halo.peach],
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 20),
            child: Text('Collections',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Halo.ink)),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              padding: const EdgeInsets.only(right: 20),
              itemBuilder: (_, i) {
                final cat = categories[i];
                final c = cols[i % cols.length];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CategoryScreen(category: cat)),
                  ),
                  child: Container(
                    width: 108,
                    decoration: BoxDecoration(
                      borderRadius: Halo.card,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [c[0].withValues(alpha: 0.80), c[1].withValues(alpha: 0.65)],
                      ),
                      boxShadow: Halo.cardShadow,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(cat.name,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                                  color: Colors.white, height: 1.2),
                              maxLines: 2),
                          const SizedBox(height: 4),
                          Text('${cat.productCount} pieces',
                              style: const TextStyle(fontSize: 10, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Product card (grid) ───────────────────────────────────────
class _ProductCard extends StatefulWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
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
            // Image area
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (widget.product.categoryName ?? '').toUpperCase(),
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                        letterSpacing: 1.2, color: Halo.inkMuted),
                  ),
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

// ── Header icon button ────────────────────────────────────────
class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  const _HeaderIconBtn({required this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: null,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.78),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: Halo.ink),
      ),
    );
  }
}
