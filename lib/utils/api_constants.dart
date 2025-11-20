/// API URL Configuration
///
/// Update BASE_URL when deploying to production server
class ApiConstants {
  // ============ BASE URLs ============
  // For local development/testing with physical device
  static const String BASE_URL = 'http://192.168.31.64:3000/api';
  static const String BASE_URL_WITHOUT_API = 'http://192.168.31.64:3000';

  // For production (update when deploying to cPanel)
  // static const String BASE_URL = 'https://yourdomain.com/api';
  // static const String BASE_URL_WITHOUT_API = 'https://yourdomain.com';

  // ============ AUTH ENDPOINTS ============
  static const String LOGIN_PATH = '/auth/login';
  static const String REGISTER_PATH = '/auth/register';
  static const String LOGIN_GOOGLE_PATH = '/auth/google';
  static const String LOGOUT_PATH = '/auth/logout';
  static const String ME_PATH = '/auth/me';

  // ============ PRODUCT ENDPOINTS ============
  static const String PRODUCTS_PATH = '/products';
  static String productsPagePath(int page) => '$PRODUCTS_PATH?page=$page';
  static String productByIdPath(int id) => '$PRODUCTS_PATH/$id';
  static String productImagesPath(int id) => '$PRODUCTS_PATH/$id/images';
  static String productsByWarehousePath(int warehouseId) =>
      '$PRODUCTS_PATH/warehouse/$warehouseId';

  // ============ MASTER DATA ENDPOINTS ============
  static const String WAREHOUSES_PATH = '/warehouses';
  static const String CATEGORIES_PATH = '/categories';
  static const String BRANDS_PATH = '/brands';

  // ============ PRODUCT SHIFT ENDPOINTS ============
  static const String PRODUCT_SHIFT_PATH = '/product-shift';

  // ============ REPORT ENDPOINTS ============
  static const String SHIFTING_REPORT_PATH = '/reports/shifting';
  static const String SALES_REPORT_PATH = '/reports/sales';

  // ============ IMPORT/EXPORT ENDPOINTS ============
  static const String IMPORT_PATH = '/import';
  static const String EXPORT_PATH = '/export';
  static String exportByWarehousePath(int warehouseId) =>
      '$EXPORT_PATH/warehouse/$warehouseId';

  // ============ HTTP TIMEOUTS ============
  static const int CONNECTION_TIMEOUT = 30000; // 30 seconds
  static const int RECEIVE_TIMEOUT = 30000; // 30 seconds

  // ============ HELPER METHODS ============
  static String getFullUrl(String path) => '$BASE_URL$path';
  static String getImageUrl(String imagePath) =>
      '$BASE_URL_WITHOUT_API/$imagePath';
}
