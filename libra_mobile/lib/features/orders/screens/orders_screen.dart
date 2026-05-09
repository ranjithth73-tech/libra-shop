import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _orderService = OrderService();
  List<OrderModel> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _orderService.getOrders();
      setState(() => _orders = orders);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load orders.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadOrders,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _orders.length,
                itemBuilder: (context, index) =>
                    _OrderCard(order: _orders[index]),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No orders yet', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Your order history will appear here', style: TextStyle(color: Colors.grey[400])),
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
    final date = _formatDate(order.createdAt);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order #${order.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  _StatusBadge(status: order.status, label: order.statusLabel, color: order.statusColor),
                ],
              ),
              const SizedBox(height: 8),
              Text(date, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              const Divider(height: 20),
              ...order.items.take(2).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text('${item.quantity}× ${item.productName}',
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis),
                        ),
                        Text('₹${item.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )),
              if (order.items.length > 2)
                Text('+${order.items.length - 2} more items',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('₹${order.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final String label;
  final Color color;
  const _StatusBadge({required this.status, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}
