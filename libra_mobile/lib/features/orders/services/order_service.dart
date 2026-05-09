import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/order_model.dart';

class OrderService {
  Future<List<OrderModel>> getOrders() async {
    final response = await DioClient.instance.get(ApiConstants.orders);
    return (response.data as List).map((o) => OrderModel.fromJson(o)).toList();
  }

  Future<OrderModel> getOrder(int id) async {
    final response = await DioClient.instance.get('${ApiConstants.orders}$id/');
    return OrderModel.fromJson(response.data);
  }

  Future<OrderModel> placeOrder({required String shippingAddress}) async {
    final response = await DioClient.instance.post(
      ApiConstants.placeOrder,
      data: {'shipping_address': shippingAddress},
    );
    return OrderModel.fromJson(response.data);
  }
}
