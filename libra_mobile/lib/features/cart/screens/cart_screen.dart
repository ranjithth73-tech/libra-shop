import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/halo_theme.dart';
import '../models/cart_model.dart';
import '../services/cart_service.dart';
import '../../orders/services/order_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _cartService = CartService();
  final _orderService = OrderService();

  CartModel? _cart;
  bool _loading = true;
  bool _placingOrder = false;

  // Free shipping threshold
  static const double _freeShippingAt = 80.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final cart = await _cartService.getCart();
      if (mounted) setState(() => _cart = cart);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _update(int itemId, int qty) async {
    try {
      final cart = await _cartService.updateItem(itemId: itemId, quantity: qty);
      if (mounted) setState(() => _cart = cart);
    } on DioException catch (e) {
      _error(e.response?.data['error'] ?? 'Failed to update');
    }
  }

  Future<void> _remove(int itemId) async {
    try {
      final cart = await _cartService.removeItem(itemId);
      if (mounted) setState(() => _cart = cart);
    } catch (_) {
      _error('Failed to remove item');
    }
  }

  Future<void> _checkout() async {
    final addressCtrl = TextEditingController();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Halo.border, borderRadius: Halo.pill),
              alignment: Alignment.center,
            ),
            const Text('Deliver to',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Halo.ink)),
            const SizedBox(height: 6),
            const Text('Enter your shipping address',
                style: TextStyle(fontSize: 14, color: Halo.inkMuted)),
            const SizedBox(height: 20),
            TextField(
              controller: addressCtrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 15, color: Halo.ink),
              decoration: InputDecoration(
                hintText: 'Street, City, State, ZIP',
                hintStyle: const TextStyle(color: Halo.inkFaint),
                filled: true,
                fillColor: Halo.bg,
                border: OutlineInputBorder(borderRadius: Halo.card, borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),
            HaloPrimaryButton(
              label: 'Place order · \$${_cart!.totalPrice.toStringAsFixed(2)}',
              onTap: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    final address = addressCtrl.text.trim();
    if (address.isEmpty) { _error('Please enter a shipping address'); return; }

    setState(() => _placingOrder = true);
    try {
      final order = await _orderService.placeOrder(shippingAddress: address);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Order #${order.id} placed!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: Halo.sm),
        ));
      }
    } on DioException catch (e) {
      _error(e.response?.data['error'] ?? 'Failed to place order');
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }

  void _error(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade400,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: Halo.sm),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Halo.bg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Halo.ink, strokeWidth: 1.5))
            : Column(
                children: [
                  // ── Header ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Row(
                      children: [
                        Text(
                          'Your bag${_cart != null && !_cart!.isEmpty ? ' · ${_cart!.totalItems}' : ''}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Halo.ink),
                        ),
                        const Spacer(),
                        if (_cart != null && !_cart!.isEmpty)
                          GestureDetector(
                            onTap: () {},
                            child: const Icon(Icons.favorite_border, color: Halo.inkMuted, size: 22),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_cart == null || _cart!.isEmpty)
                    Expanded(child: _EmptyBag())
                  else ...[
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        color: Halo.ink,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            // Cart items
                            ..._cart!.items.map((item) => _BagItem(
                                  item: item,
                                  onIncrease: () => _update(item.id, item.quantity + 1),
                                  onDecrease: item.quantity > 1
                                      ? () => _update(item.id, item.quantity - 1)
                                      : null,
                                  onRemove: () => _remove(item.id),
                                )),

                            const SizedBox(height: 16),

                            // Free shipping progress
                            _FreeShippingBar(total: _cart!.totalPrice),

                            const SizedBox(height: 24),

                            // Summary
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: Halo.card),
                              child: Column(
                                children: [
                                  _SummaryRow(label: 'Subtotal', value: '\$${_cart!.totalPrice.toStringAsFixed(2)}'),
                                  const SizedBox(height: 10),
                                  _SummaryRow(
                                    label: 'Shipping · standard',
                                    value: _cart!.totalPrice >= _freeShippingAt ? 'Free' : '\$8.00',
                                    valueColor: _cart!.totalPrice >= _freeShippingAt ? const Color(0xFF10B981) : null,
                                  ),
                                  const Divider(height: 24, color: Halo.border),
                                  _SummaryRow(
                                    label: 'Total',
                                    value: '\$${_cart!.totalPrice.toStringAsFixed(2)}',
                                    bold: true,
                                    valueSize: 20,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),

                    // ── Pay button ─────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: HaloPrimaryButton(
                        label: '  Pay',
                        icon: Icons.apple,
                        onTap: _placingOrder ? null : _checkout,
                        loading: _placingOrder,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

// ── Empty bag ─────────────────────────────────────────────────
class _EmptyBag extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: Halo.cardShadow,
            ),
            child: const Icon(Icons.shopping_bag_outlined, size: 36, color: Halo.inkMuted),
          ),
          const SizedBox(height: 20),
          const Text('Your bag is empty',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Halo.ink)),
          const SizedBox(height: 6),
          const Text('Add pieces to get started',
              style: TextStyle(fontSize: 14, color: Halo.inkMuted)),
        ],
      ),
    );
  }
}

// ── Bag item card ─────────────────────────────────────────────
class _BagItem extends StatelessWidget {
  final CartItemModel item;
  final VoidCallback onIncrease;
  final VoidCallback? onDecrease;
  final VoidCallback onRemove;

  const _BagItem({
    required this.item,
    required this.onIncrease,
    this.onDecrease,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: Halo.card,
        boxShadow: Halo.cardShadow,
      ),
      child: Row(
        children: [
          // Product gradient image
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(gradient: Halo.productGradient(item.product.id)),
              child: item.product.image != null
                  ? Image.network(
                      '${ApiConstants.baseUrl}${item.product.image}',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => const SizedBox(),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (item.product.categoryName ?? '').toUpperCase(),
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                      letterSpacing: 1.2, color: Halo.inkMuted),
                ),
                const SizedBox(height: 3),
                Text(item.product.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Halo.ink),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                // Qty controls
                Row(
                  children: [
                    _QtyControl(icon: Icons.remove, enabled: onDecrease != null, onTap: onDecrease ?? () {}),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text('${item.quantity}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Halo.ink)),
                    ),
                    _QtyControl(icon: Icons.add, enabled: true, onTap: onIncrease),
                  ],
                ),
              ],
            ),
          ),
          // Price + remove
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${item.totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Halo.ink)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(Icons.close, size: 18, color: Halo.inkFaint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyControl extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _QtyControl({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: enabled ? Halo.ink : Halo.border,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: enabled ? Colors.white : Halo.inkFaint),
      ),
    );
  }
}

// ── Free shipping bar ─────────────────────────────────────────
class _FreeShippingBar extends StatelessWidget {
  final double total;
  const _FreeShippingBar({required this.total});

  static const _threshold = 80.0;

  @override
  Widget build(BuildContext context) {
    final progress = (total / _threshold).clamp(0.0, 1.0);
    final remaining = _threshold - total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: Halo.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.card_giftcard_outlined, size: 16, color: Halo.inkMuted),
              const SizedBox(width: 8),
              Text(
                progress >= 1.0
                    ? 'Free shipping unlocked!'
                    : 'Add \$${remaining.toStringAsFixed(0)} for free shipping',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Halo.ink),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: Halo.pill,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Halo.bg,
              valueColor: const AlwaysStoppedAnimation(Halo.ink),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary row ───────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  final double valueSize;
  final Color? valueColor;

  const _SummaryRow({
    required this.label, required this.value,
    this.bold = false, this.valueSize = 14, this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14, fontWeight: bold ? FontWeight.w700 : FontWeight.w400, color: Halo.ink)),
        Text(value,
            style: TextStyle(
                fontSize: valueSize,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                color: valueColor ?? Halo.ink)),
      ],
    );
  }
}
