class CategoryModel {
  final int id;
  final String name;
  final String description;
  final int productCount;

  CategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.productCount,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      productCount: json['product_count'] ?? 0,
    );
  }
}

class ProductModel {
  final int id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final bool inStock;
  final String? categoryName;
  final String? image;
  final bool isActive;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.inStock,
    this.categoryName,
    this.image,
    required this.isActive,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      price: double.parse(json['price'].toString()),
      stock: json['stock'] ?? 0,
      inStock: json['is_in_stock'] ?? false,
      categoryName: json['category_name'],
      image: json['image'],
      isActive: json['is_active'] ?? true,
    );
  }
}
