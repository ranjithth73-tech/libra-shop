class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.11.116:8000',
  );

  // Auth endpoints
  static const String register = '/api/auth/register/';
  static const String login = '/api/auth/login/';
  static const String tokenRefresh = '/api/auth/token/refresh/';
  static const String profile = '/api/auth/profile/';

  // Product endpoints
  static const String products = '/api/products/';
  static const String categories = '/api/categories/';

  // Cart endpoints
  static const String cart = '/api/cart/';

  // Order endpoints
  static const String orders = '/api/orders/';
  static const String placeOrder = '/api/orders/place/';
}
