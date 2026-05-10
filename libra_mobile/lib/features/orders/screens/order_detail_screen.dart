import 'package:flutter/material.dart';
import '../../../core/theme/halo_theme.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _service = OrderService();
  OrderModel? _order;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final o = await _service.getOrder(widget.orderId);
      if (mounted) setState(() => _order = o);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Halo.ink, strokeWidth: 1.5))
          : _order == null
              ? const Center(child: Text('Order not found'))
              : _OrderBody(order: _order!),
    );
  }
}

class _OrderBody extends StatelessWidget {
  final OrderModel order;
  const _OrderBody({required this.order});

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps(order.status);

    return Stack(
      children: [
        // ── Gradient top section ───────────────────────
        Column(
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.50,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: Halo.bg),
                  // Blobs
                  Positioned(top: -60, left: -60,
                      child: _blob(Halo.peach, 250)),
                  Positioned(top: -40, right: -40,
                      child: _blob(Halo.butter, 220)),
                  Positioned(bottom: 20, left: 40,
                      child: _blob(Halo.lavender, 180)),
                  Positioned(bottom: 10, right: 20,
                      child: _blob(Halo.mint, 160)),
                ],
              ),
            ),
            Expanded(child: Container(color: const Color(0xFF1A1A1A))),
          ],
        ),

        // ── Content ───────────────────────────────────
        SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.80),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 20, color: Halo.ink),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'ORDER · #HAL-${order.id.toString().padLeft(5, '0')}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          letterSpacing: 1.5, color: Halo.inkMuted),
                    ),
                    const Spacer(),
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.80),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chat_bubble_outline, size: 18, color: Halo.ink),
                    ),
                  ],
                ),
              ),

              // Thank you message
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Text(
                        'Thank you, ${order.userEmail.split('@').first}',
                        style: const TextStyle(fontSize: 14, color: Halo.inkMuted),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your bag is\non its way.',
                        style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700,
                            color: Halo.ink, height: 1.1, letterSpacing: -0.5),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Timeline card ───────────────────────────
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  borderRadius: Halo.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ARRIVING',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                    letterSpacing: 1.5, color: Colors.white54)),
                            SizedBox(height: 4),
                            Text('Est. 3–5 business days',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: Halo.pill,
                          ),
                          child: Text(
                            order.status == 'delivered' ? 'Delivered' : 'On time',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Timeline
                    ...steps.map((s) => _TimelineStep(step: s)),

                    const SizedBox(height: 16),

                    // Shipping address
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: Halo.sm,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: Colors.white54),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(order.shippingAddress,
                                style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.4)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Items list ────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: Halo.card,
                    boxShadow: Halo.cardShadow,
                  ),
                  child: Column(
                    children: [
                      ...order.items.map((i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    gradient: Halo.productGradient(i.id),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text('${i.quantity}',
                                        style: const TextStyle(color: Colors.white,
                                            fontWeight: FontWeight.w700, fontSize: 13)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(i.productName,
                                          style: const TextStyle(fontSize: 13,
                                              fontWeight: FontWeight.w600, color: Halo.ink)),
                                      Text('\$${i.productPrice.toStringAsFixed(0)} each',
                                          style: const TextStyle(fontSize: 11, color: Halo.inkMuted)),
                                    ],
                                  ),
                                ),
                                Text('\$${i.totalPrice.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 14,
                                        fontWeight: FontWeight.w700, color: Halo.ink)),
                              ],
                            ),
                          )),
                      const Divider(color: Halo.border, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Halo.ink)),
                          Text('\$${order.totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Halo.ink)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _blob(Color color, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.55), Colors.transparent],
        ),
      ),
    );
  }

  static List<_Step> _buildSteps(String status) {
    const all = ['pending', 'confirmed', 'shipped', 'delivered'];
    final idx = all.indexOf(status);
    return [
      _Step('Ordered', 'Placed successfully', idx >= 0),
      _Step('Confirmed', 'Processing your order', idx >= 1),
      _Step('In transit', 'On the way to you', idx >= 2),
      _Step('Out for delivery', 'Arriving soon', idx >= 3),
      _Step('Delivered', 'Enjoy your pieces', status == 'delivered'),
    ];
  }
}

class _Step {
  final String title, subtitle;
  final bool done;
  const _Step(this.title, this.subtitle, this.done);
}

class _TimelineStep extends StatelessWidget {
  final _Step step;
  const _TimelineStep({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: step.done ? Colors.white : Colors.white24,
                  border: Border.all(
                    color: step.done ? Colors.white : Colors.white24,
                    width: 2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.title,
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: step.done ? Colors.white : Colors.white38,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
