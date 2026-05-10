import 'package:flutter/material.dart';
import '../../../core/theme/halo_theme.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _service = OrderService();
  List<OrderModel> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final orders = await _service.getOrders();
      if (mounted) setState(() => _orders = orders);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Halo.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: Halo.cardShadow,
                      ),
                      child: const Icon(Icons.arrow_back, size: 20, color: Halo.ink),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text('Orders',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Halo.ink)),
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Halo.ink, strokeWidth: 1.5))
                  : _orders.isEmpty
                      ? _EmptyOrders()
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: Halo.ink,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _orders.length,
                            itemBuilder: (_, i) => _OrderCard(order: _orders[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: Halo.cardShadow),
            child: const Icon(Icons.receipt_long_outlined, size: 36, color: Halo.inkMuted),
          ),
          const SizedBox(height: 20),
          const Text('No orders yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Halo.ink)),
          const SizedBox(height: 6),
          const Text('Your order history will appear here',
              style: TextStyle(fontSize: 14, color: Halo.inkMuted)),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: Halo.card,
          boxShadow: Halo.cardShadow,
        ),
        child: Row(
          children: [
            // Gradient icon
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: Halo.productGradient(order.id),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order #${order.id}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Halo.ink)),
                  const SizedBox(height: 3),
                  Text(
                    '${order.items.length} item${order.items.length == 1 ? '' : 's'} · \$${order.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13, color: Halo.inkMuted),
                  ),
                  const SizedBox(height: 6),
                  _StatusBadge(status: order.status, label: order.statusLabel, color: order.statusColor),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Halo.inkFaint, size: 20),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status, label;
  final Color color;
  const _StatusBadge({required this.status, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: Halo.pill,
      ),
      child: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11, letterSpacing: 0.2)),
    );
  }
}
