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

  // fromJson — Django sends JSON, convert it to a Dart object here

  factory CategoryModel.formJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      productCount: json['productCount'] ?? 0,
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
  final String? categoryName; // nullable — product might not have a category
  final String? image; // nullable — product might not have an image
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

  factory ProductModel.formJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',

      // Django returns price as a string "999.00" — parse it to a Dart double
      // Always use double.parse() for decimal numbers from Django
      price: double.parse(json['price'].toString()),
      stock: json['stock'] ?? 0,
      inStock: json['inStock'] ?? false,
      isActive: json['isActive'] ?? true,
    );
  }
}
