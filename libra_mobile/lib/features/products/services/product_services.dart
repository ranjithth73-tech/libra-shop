import 'package:libra_mobile/core/constants/api_constants.dart';
import 'package:libra_mobile/core/network/dio_client.dart';
import 'package:libra_mobile/features/products/models/product_model.dart';

class ProductServices {
  // Get products list — supports search, filter, sort, pagination

  Future<Map<String, dynamic>> getProducts({
    String? search,
    int? category,
    String? ordering,
    int page = 1,
  }) async {
    // Products are public - no token needed
    final dio = DioClient.instance;

    // Build query parameters map dynamically
    // We only add params that are not null — don't send empty strings

    final params = <String, dynamic>{'page': page};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (category != null) params['category'] = category;
    if (ordering != null) params['ordering'] = ordering;

    final response = await dio.get(
      ApiConstants.products,
      queryParameters: params,
    );

    final results = (response.data['results'] as List)
        .map((p) => ProductModel.formJson(p))
        .toList();
    return {
      'count': response.data['count'],
      'next': response.data['next'],
      'previous': response.data['previous'],
      'result': results,
    };
  }

  // Get a single product by ID — for the detail screen

  Future<ProductModel> getProduct(int id) async {
    final dio = DioClient.instance;
    // URL becomes: /api/products/1/
    final response = await dio.get('${ApiConstants.products}$id/');

    return ProductModel.formJson(response.data);
  }

  // Get all categories — for the filter chips

  Future<List<CategoryModel>> getCategories() async {
    final dio = DioClient.instance;
    final response = await dio.get(ApiConstants.categories);

    // Categories response is a plain list — not paginated
    // So we cast it directly to List and map each item

    return (response.data as List)
        .map((c) => CategoryModel.formJson(c))
        .toList();
  }
}
