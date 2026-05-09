import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/product_services.dart';
import '../../../core/storage/token_storage.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _productService = ProductServices();
  final _searchCtrl = TextEditingController();

  // State variables — changing these triggers UI rebuild
  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  final String _searchQuery = '';
  int? _selectedCategory;
  String _ordering = '-created_at';
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();

    // initState runs once when screen first loads
    // load categories and products immediately

    _loadCategories();
    _loadProducts();
  }

  @override
  void dispose() {
    // Always dispose controllers when screen is destroyed — prevents memory leaks

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
      // finally always runs — even if there was an error
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await TokenStorage.clearTokens();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('LiBRA', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: (() => Navigator.pushNamed(context, '/cart')),
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar
          Container(
            color: Colors.black,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search products....',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),

                // Show clear button only when there is tex
                // suffixIcon: _searchQuery.isNotEmpty
                //  ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey,),onPressed: () {_searchCtrl.clear(); setState(() => _searchQuery = ''); _loadProducts();},))
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _searchCtrl.clear();
                          });
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
                setState(() {});
                _loadProducts();
                Future.delayed(const Duration(microseconds: 500), () {
                  if (_searchQuery == value) _loadProducts();
                });
              },
            ),
          ),
          // ── Category filter chips
          if (_categories.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('All'),
                      selected: _selectedCategory == null,
                      onSelected: (_) {
                        setState(() => _selectedCategory == null);
                        _loadProducts();
                      },
                      selectedColor: Colors.black,
                      labelStyle: TextStyle(
                        color: _selectedCategory == null
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),

                  // One chip per category from Django
                  ..._categories.map(
                    (cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat.name),
                        selected: _selectedCategory == cat.id,
                        onSelected: (_) {
                          setState(() {
                            // Tap again to deselect
                            _selectedCategory = _selectedCategory == cat.id
                                ? null
                                : cat.id;
                          });
                          _loadProducts();
                        },
                        selectedColor: Colors.black,
                        labelStyle: TextStyle(
                          color: _selectedCategory == cat.id
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Results count + sort dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_totalCount Products',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                DropdownButton<String>(
                  value: _ordering,
                  underline: const SizedBox(),
                  style: const TextStyle(color: Colors.black, fontSize: 13),
                  items: const [
                    DropdownMenuItem(
                      value: '-created_at',
                      child: Text('Newest'),
                    ),
                    DropdownMenuItem(
                      value: 'price',
                      child: Text('Price: Low → High'),
                    ),

                    DropdownMenuItem(
                      value: '-price',
                      child: Text('Price: High → Low'),
                    ),
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

          // ── Product grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadProducts,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.72,
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

// ── Product card widget
// Extracted as a separate widget — keeps HomeScreen clean
// and Flutter can optimize rebuilds better with separate widgets

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Tap the card → go to product detail screen
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
            // Product name — max 2 lines then "..."
            Text(
              product.name,
              style: const TextStyle(fontWeight: .w600, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '₹${product.price.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),

            // Stock badge — green if in stock, red if not
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: product.inStock ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                product.inStock ? "In Stock" : 'Out of Stock',
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
    );
  }
}
