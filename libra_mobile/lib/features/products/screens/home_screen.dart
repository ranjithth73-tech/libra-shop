import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/product_services.dart';
import 'product_detail_screen.dart';
import '../../../core/constants/api_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _productService = ProductServices();
  final _searchCtrl = TextEditingController();

  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String _searchQuery = '';
  int? _selectedCategory;
  String _ordering = '-created_at';
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _productService.getCategories();
      setState(() => _categories = categories);
    } catch (e) {
      debugPrint('Categories error: $e');
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final data = await _productService.getProducts(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        category: _selectedCategory,
        ordering: _ordering,
      );
      setState(() {
        _products = data['results'];
        _totalCount = data['count'];
      });
    } catch (e) {
      debugPrint('Products error: $e');
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
        title: const Text('LiBRA', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.black,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                          _loadProducts();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _loadProducts();
              },
            ),
          ),

          // Category filter chips
          if (_categories.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('All'),
                      selected: _selectedCategory == null,
                      onSelected: (_) {
                        setState(() => _selectedCategory = null);
                        _loadProducts();
                      },
                      selectedColor: Colors.black,
                      labelStyle: TextStyle(
                        color: _selectedCategory == null ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  ..._categories.map(
                    (cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat.name),
                        selected: _selectedCategory == cat.id,
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory =
                                _selectedCategory == cat.id ? null : cat.id;
                          });
                          _loadProducts();
                        },
                        selectedColor: Colors.black,
                        labelStyle: TextStyle(
                          color: _selectedCategory == cat.id ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Results count + sort dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$_totalCount Products',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                DropdownButton<String>(
                  value: _ordering,
                  underline: const SizedBox(),
                  style: const TextStyle(color: Colors.black, fontSize: 13),
                  items: const [
                    DropdownMenuItem(value: '-created_at', child: Text('Newest')),
                    DropdownMenuItem(value: 'price', child: Text('Price: Low → High')),
                    DropdownMenuItem(value: '-price', child: Text('Price: High → Low')),
                    DropdownMenuItem(value: 'name', child: Text('Name A → Z')),
                  ],
                  onChanged: (value) {
                    setState(() => _ordering = value!);
                    _loadProducts();
                  },
                ),
              ],
            ),
          ),

          // Product grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text('No products found', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadProducts,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.68,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _products.length,
                      itemBuilder: (context, index) =>
                          _ProductCard(product: _products[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(productId: product.id),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 1,
                child: product.image != null
                    ? Image.network(
                        '${ApiConstants.baseUrl}${product.image}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
            ),
            // Details
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: product.inStock ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      product.inStock ? 'In Stock' : 'Out of Stock',
                      style: TextStyle(
                        fontSize: 10,
                        color: product.inStock ? Colors.green[700] : Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.image_outlined, size: 48, color: Colors.grey),
      ),
    );
  }
}
