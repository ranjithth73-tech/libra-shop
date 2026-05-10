import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/halo_theme.dart';
import '../models/product_model.dart';
import '../services/product_services.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _service = ProductServices();
  ProductModel? _product;
  bool _loading = true;
  bool _addingToCart = false;
  bool _saved = false;
  int _quantity = 1;
  int _selectedSwatch = 0;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      final p = await _service.getProduct(widget.productId);
      if (mounted) setState(() => _product = p);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addToCart() async {
    setState(() => _addingToCart = true);
    try {
      await DioClient.instance.post(
        ApiConstants.cart,
        data: {'product_id': widget.productId, 'quantity': _quantity},
      );
      if (mounted) {
        _showToast('Added to bag');
      }
    } on DioException catch (_) {
      if (mounted) _showToast('Sign in to add to bag', error: true);
    } finally {
      if (mounted) setState(() => _addingToCart = false);
    }
  }

  void _showToast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red.shade400 : Halo.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: Halo.sm),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Halo.bg,
        body: Center(child: CircularProgressIndicator(color: Halo.ink, strokeWidth: 1.5)),
      );
    }
    if (_product == null) {
      return Scaffold(
        backgroundColor: Halo.bg,
        body: const Center(child: Text('Product not found', style: TextStyle(color: Halo.inkMuted))),
      );
    }

    final p = _product!;
    final gradient = Halo.productGradient(p.id);
    // Generate palette swatches from adjacent gradients
    final swatches = List.generate(
        5, (i) => Halo.productGradient((p.id + i) % 8).colors.first);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Full-screen image / gradient ───────────────
          Column(
            children: [
              // Top 60% of screen = gradient hero
              Expanded(
                flex: 6,
                child: Container(
                  decoration: BoxDecoration(gradient: gradient),
                  width: double.infinity,
                  child: p.image != null
                      ? Image.network(
                          '${ApiConstants.baseUrl}${p.image}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => const SizedBox(),
                        )
                      : const SizedBox(),
                ),
              ),
              // Bottom 40% = white (behind info panel)
              Expanded(flex: 4, child: Container(color: Colors.white)),
            ],
          ),

          // ── Overlay buttons ────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _OverlayBtn(icon: Icons.arrow_back, onTap: () => Navigator.pop(context)),
                  const Spacer(),
                  _OverlayBtn(icon: Icons.share_outlined, onTap: () {}),
                  const SizedBox(width: 8),
                  _OverlayBtn(
                    icon: _saved ? Icons.favorite : Icons.favorite_border,
                    color: _saved ? const Color(0xFFD4909E) : null,
                    onTap: () => setState(() => _saved = !_saved),
                  ),
                ],
              ),
            ),
          ),

          // ── Page dots ─────────────────────────────────
          Positioned(
            left: 0, right: 0,
            top: MediaQuery.sizeOf(context).height * 0.55,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == 0 ? 20 : 6, height: 6,
                decoration: BoxDecoration(
                  color: i == 0 ? Colors.white : Colors.white.withValues(alpha: 0.45),
                  borderRadius: Halo.pill,
                ),
              )),
            ),
          ),

          // ── Info sheet (slides up) ─────────────────────
          Positioned(
            left: 0, right: 0, bottom: 0,
            top: MediaQuery.sizeOf(context).height * 0.52,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand + name + price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (p.categoryName ?? '').toUpperCase(),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                    letterSpacing: 1.5, color: Halo.inkMuted),
                              ),
                              const SizedBox(height: 6),
                              Text(p.name,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                                      color: Halo.ink, height: 1.15)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('\$${p.price.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Halo.ink)),
                            const Text('per item',
                                style: TextStyle(fontSize: 11, color: Halo.inkMuted)),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Color swatches
                    Row(
                      children: [
                        Text(
                          'GLAZE · ',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                              letterSpacing: 1.2, color: Halo.inkMuted),
                        ),
                        Text(
                          _swatchName(_selectedSwatch),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                              letterSpacing: 1.2, color: Halo.ink),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: List.generate(swatches.length, (i) {
                        final selected = i == _selectedSwatch;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedSwatch = i),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 34, height: 34,
                            decoration: BoxDecoration(
                              color: swatches[i],
                              shape: BoxShape.circle,
                              border: selected
                                  ? Border.all(color: Halo.ink, width: 2)
                                  : null,
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 20),

                    // Quantity selector
                    if (p.inStock) ...[
                      Row(
                        children: [
                          const Text('Qty  ',
                              style: TextStyle(fontSize: 13, color: Halo.inkMuted)),
                          _QtyBtn(icon: Icons.remove,
                              enabled: _quantity > 1,
                              onTap: () => setState(() => _quantity--)),
                          const SizedBox(width: 16),
                          Text('$_quantity',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Halo.ink)),
                          const SizedBox(width: 16),
                          _QtyBtn(icon: Icons.add,
                              enabled: _quantity < p.stock,
                              onTap: () => setState(() => _quantity++)),
                          const Spacer(),
                          // Stock indicator
                          Text('${p.stock} left',
                              style: const TextStyle(fontSize: 12, color: Halo.inkMuted)),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Action buttons
                    Row(
                      children: [
                        // Save button
                        GestureDetector(
                          onTap: () => setState(() => _saved = !_saved),
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Halo.bg,
                              borderRadius: Halo.pill,
                              border: Border.all(color: Halo.border),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _saved ? Icons.favorite : Icons.favorite_border,
                                  size: 18,
                                  color: _saved ? const Color(0xFFD4909E) : Halo.inkMuted,
                                ),
                                const SizedBox(width: 6),
                                Text(_saved ? 'Saved' : 'Save',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Halo.ink)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Add to bag
                        Expanded(
                          child: GestureDetector(
                            onTap: (p.inStock && !_addingToCart) ? _addToCart : null,
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: p.inStock ? Halo.ink : Halo.inkFaint,
                                borderRadius: Halo.pill,
                              ),
                              child: Center(
                                child: _addingToCart
                                    ? const SizedBox(width: 20, height: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 18),
                                          const SizedBox(width: 8),
                                          Text(
                                            p.inStock
                                                ? 'Add to bag · \$${(p.price * _quantity).toStringAsFixed(0)}'
                                                : 'Out of stock',
                                            style: const TextStyle(color: Colors.white, fontSize: 14,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Delivery row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Halo.bg,
                        borderRadius: Halo.sm,
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.local_shipping_outlined, size: 16, color: Halo.inkMuted),
                          SizedBox(width: 8),
                          Text('Free shipping on orders over \$80',
                              style: TextStyle(fontSize: 12, color: Halo.inkMuted)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Description
                    if (p.description.isNotEmpty) ...[
                      const Text('About this piece',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Halo.ink)),
                      const SizedBox(height: 8),
                      Text(p.description,
                          style: const TextStyle(fontSize: 14, color: Halo.inkMuted, height: 1.6)),
                      const SizedBox(height: 32),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _swatchName(int i) {
    const names = ['Stone', 'Ivory', 'Mocha', 'Sage', 'Blush'];
    return names[i % names.length];
  }
}

// ── Overlay button ─────────────────────────────────────────────
class _OverlayBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  const _OverlayBtn({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          shape: BoxShape.circle,
          boxShadow: Halo.cardShadow,
        ),
        child: Icon(icon, size: 20, color: color ?? Halo.ink),
      ),
    );
  }
}

// ── Quantity button ────────────────────────────────────────────
class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: enabled ? Halo.ink : Halo.border,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: enabled ? Colors.white : Halo.inkFaint, size: 16),
      ),
    );
  }
}
