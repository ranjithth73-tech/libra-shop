import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/cart_model.dart';
import '../services/cart_service.dart';
import '../../orders/services/order_service.dart';
import '../../../core/constants/api_constants.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _cartService = CartService();
  final _orderService = OrderService();

  CartModel? _cart;
  bool _isLoading = true;
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => _isLoading = true);
    try {
      final cart = await _cartService.getCart();
      setState(() => _cart = cart);
    } catch (e) {
      _showError('Failed to load cart.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateQuantity(int itemId, int quantity) async {
    try {
      final cart = await _cartService.updateItem(itemId: itemId, quantity: quantity);
      setState(() => _cart = cart);
    } on DioException catch (e) {
      _showError(e.response?.data['error'] ?? 'Failed to update quantity.');
    }
  }

  Future<void> _removeItem(int itemId) async {
    try {
      final cart = await _cartService.removeItem(itemId);
      setState(() => _cart = cart);
    } catch (e) {
      _showError('Failed to remove item.');
    }
  }

  Future<void> _clearCart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Remove all items from your cart?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _cartService.clearCart();
      await _loadCart();
    } catch (e) {
      _showError('Failed to clear cart.');
    }
  }

  Future<void> _checkout() async {
    final addressCtrl = TextEditingController();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Shipping Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: addressCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter your full delivery address',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Confirm Order', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final address = addressCtrl.text.trim();
    if (address.isEmpty) {
      _showError('Please enter a shipping address.');
      return;
    }

    setState(() => _isPlacingOrder = true);
    try {
      final order = await _orderService.placeOrder(shippingAddress: address);
      await _loadCart();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order #${order.id} placed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on DioException catch (e) {
      _showError(e.response?.data['error'] ?? 'Failed to place order.');
    } finally {
      setState(() => _isPlacingOrder = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('My Cart', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_cart != null && !_cart!.isEmpty)
            IconButton(
              onPressed: _clearCart,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear cart',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cart == null || _cart!.isEmpty
          ? _buildEmptyState()
          : _buildCartContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Your cart is empty', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Add products to get started', style: TextStyle(color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadCart,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _cart!.items.length,
              itemBuilder: (context, index) {
                final item = _cart!.items[index];
                return _CartItemCard(
                  item: item,
                  onUpdateQuantity: (q) => _updateQuantity(item.id, q),
                  onRemove: () => _removeItem(item.id),
                );
              },
            ),
          ),
        ),
        _buildCheckoutBar(),
      ],
    );
  }

  Widget _buildCheckoutBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${_cart!.totalItems} item${_cart!.totalItems == 1 ? '' : 's'}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              Text(
                '₹${_cart!.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isPlacingOrder ? null : _checkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isPlacingOrder
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Text('Checkout', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItemModel item;
  final ValueChanged<int> onUpdateQuantity;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.onUpdateQuantity,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 72,
                height: 72,
                child: item.product.image != null
                    ? Image.network(
                        '${ApiConstants.baseUrl}${item.product.image}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            const SizedBox(width: 12),
            // Name + price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.product.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('₹${item.product.price.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _qtyButton(Icons.remove, item.quantity > 1
                          ? () => onUpdateQuantity(item.quantity - 1)
                          : null),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('${item.quantity}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                      _qtyButton(Icons.add, item.quantity < item.product.stock
                          ? () => onUpdateQuantity(item.quantity + 1)
                          : null),
                    ],
                  ),
                ],
              ),
            ),
            // Total + remove
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${item.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onRemove,
                  child: Icon(Icons.delete_outline, color: Colors.red[400], size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: onTap != null ? Colors.black : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.image_outlined, color: Colors.grey),
    );
  }
}
