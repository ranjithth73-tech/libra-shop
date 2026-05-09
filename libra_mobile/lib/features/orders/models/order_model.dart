import 'package:flutter/material.dart';

class OrderItemModel {
  final int id;
  final int? productId;
  final String productName;
  final double productPrice;
  final int quantity;
  final double totalPrice;

  OrderItemModel({
    required this.id,
    this.productId,
    required this.productName,
    required this.productPrice,
    required this.quantity,
    required this.totalPrice,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'],
      productId: json['product'],
      productName: json['product_name'],
      productPrice: double.parse(json['product_price'].toString()),
      quantity: json['quantity'],
      totalPrice: double.parse(json['total_price'].toString()),
    );
  }
}

class OrderModel {
  final int id;
  final String userEmail;
  final String status;
  final String shippingAddress;
  final double totalPrice;
  final List<OrderItemModel> items;
  final String createdAt;
  final String updatedAt;

  OrderModel({
    required this.id,
    required this.userEmail,
    required this.status,
    required this.shippingAddress,
    required this.totalPrice,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      userEmail: json['user_email'] ?? '',
      status: json['status'],
      shippingAddress: json['shipping_address'],
      totalPrice: double.parse(json['total_price'].toString()),
      items: (json['items'] as List)
          .map((i) => OrderItemModel.fromJson(i))
          .toList(),
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  String get statusLabel {
    switch (status) {
      case 'pending': return 'Pending';
      case 'confirmed': return 'Confirmed';
      case 'shipped': return 'Shipped';
      case 'delivered': return 'Delivered';
      case 'canceled': return 'Canceled';
      default: return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending': return const Color(0xFFF59E0B);
      case 'confirmed': return const Color(0xFF3B82F6);
      case 'shipped': return const Color(0xFF8B5CF6);
      case 'delivered': return const Color(0xFF10B981);
      case 'canceled': return const Color(0xFFEF4444);
      default: return const Color(0xFF6B7280);
    }
  }
}
