import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/cart_model.dart';

class CartService {
  Future<CartModel> getCart() async {
    final response = await DioClient.instance.get(ApiConstants.cart);
    return CartModel.fromJson(response.data);
  }

  Future<CartModel> addItem({required int productId, required int quantity}) async {
    final response = await DioClient.instance.post(
      ApiConstants.cart,
      data: {'product_id': productId, 'quantity': quantity},
    );
    return CartModel.fromJson(response.data);
  }

  Future<CartModel> updateItem({required int itemId, required int quantity}) async {
    final response = await DioClient.instance.patch(
      '${ApiConstants.cart}update/$itemId/',
      data: {'quantity': quantity},
    );
    return CartModel.fromJson(response.data);
  }

  Future<CartModel> removeItem(int itemId) async {
    final response = await DioClient.instance.delete(
      '${ApiConstants.cart}remove/$itemId/',
    );
    return CartModel.fromJson(response.data);
  }

  Future<void> clearCart() async {
    await DioClient.instance.delete('${ApiConstants.cart}clear/');
  }
}
