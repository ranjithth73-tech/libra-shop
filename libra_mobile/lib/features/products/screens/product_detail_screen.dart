import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:libra_mobile/core/constants/api_constants.dart';
import 'package:libra_mobile/core/network/dio_client.dart';
import 'package:libra_mobile/features/products/models/product_model.dart';
import 'package:libra_mobile/features/products/services/product_services.dart';

class ProductDetailScreen extends StatefulWidget {
  // productId passed in from the home screen card tap
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _productService = ProductServices();
  ProductModel? _product;
  bool _isLoading = true;
  bool _addingToCart = true;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      // widget.productId accesses the productId passed to this StatefulWidget
      final product = await _productService.getProduct(widget.productId);
      setState(() => _product = product);
    } catch (e) {
      debugPrint('product detail error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addToCart() async {
    setState(() => _addingToCart = true);
    try {
      // Cart requires auth — use authenticatedDio which loads token from storage
      final dio = await DioClient.authenticatedDio();
      await dio.post(
        ApiConstants.cart,
        data: {'product_id': widget.productId, 'quantity': _quantity},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to cart! 🛒'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on DioException catch (e) {
      debugPrint('Added to cart error: ${e.response?.data}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add to cart. Are you logged in?'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _addingToCart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/cart'),
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _product == null
          ? const Center(child: Text('Product not found'))
          : Column(
              children: [
                // Scrollable content above the fixed bottom button
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //  Product image
                        SizedBox(
                          height: 300,
                          width: double.infinity,
                          child: _product!.image != null
                              ? Image.network(
                                  '${ApiConstants.baseUrl}${_product!.image}',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      _imagePlaceholder(),
                                )
                              : _imagePlaceholder(),
                        ),
                        Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              //Category badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _product!.categoryName!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Product name
                              Text(
                                _product!.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),

                              // Price
                              Text(
                                '₹${_product!.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),

                              // Stock status
                              Row(
                                children: [
                                  Icon(
                                    _product!.inStock
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: _product!.inStock
                                        ? Colors.green
                                        : Colors.red,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _product!.inStock
                                        ? '${_product!.inStock} in stock'
                                        : 'Out of stock',
                                    style: TextStyle(
                                      color: _product!.inStock
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Description
                              const Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                _product!.description.isEmpty
                                    ? 'No description available.'
                                    : _product!.description,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 24),

                              //  Quantity selector
                              // Only show if product is in stock
                              if (_product!.inStock) ...[
                                const Text(
                                  'Quantity',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                Row(
                                  children: [
                                    // Minus button — disabled when quantity is 1
                                    IconButton(
                                      onPressed: _quantity > 1
                                          ? () => setState(() => _quantity--)
                                          : null,
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                      color: Colors.black,
                                    ),
                                    Text(
                                      '$_quantity',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    // Plus button — disabled when quantity = stock
                                    IconButton(
                                      onPressed: _quantity < _product!.stock
                                          ? () => setState(() => _quantity++)
                                          : null,
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                //  Add to cart button — fixed at bottom
                // Container with shadow to separate from scrollable content
                Container(
                  padding: EdgeInsets.all(20),
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
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      // Disable button if out of stock or already adding
                      onPressed: _product!.inStock && _addingToCart
                          ? _addToCart
                          : null,
                      icon: _addingToCart
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.shopping_cart,
                              color: Colors.white,
                            ),
                      label: Text(
                        _product!.inStock ? 'Added to cart' : 'Out of stock',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _product!.inStock
                            ? Colors.black
                            : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.image_outlined, size: 80, color: Colors.grey),
      ),
    );
  }
}
