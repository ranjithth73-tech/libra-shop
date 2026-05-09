import '../../products/models/product_model.dart';

class CartItemModel {
  final int id;
  final ProductModel product;
  final int quantity;
  final double totalPrice;

  CartItemModel({
    required this.id,
    required this.product,
    required this.quantity,
    required this.totalPrice,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'],
      product: ProductModel.fromJson(json['product']),
      quantity: json['quantity'],
      totalPrice: double.parse(json['total_price'].toString()),
    );
  }
}

class CartModel {
  final int id;
  final List<CartItemModel> items;
  final double totalPrice;
  final int totalItems;
  final String updatedAt;

  CartModel({
    required this.id,
    required this.items,
    required this.totalPrice,
    required this.totalItems,
    required this.updatedAt,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      id: json['id'],
      items: (json['items'] as List)
          .map((i) => CartItemModel.fromJson(i))
          .toList(),
      totalPrice: double.parse(json['total_price'].toString()),
      totalItems: json['total_items'],
      updatedAt: json['updated_at'] ?? '',
    );
  }

  bool get isEmpty => items.isEmpty;
}
