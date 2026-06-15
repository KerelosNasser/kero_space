import 'package:dio/dio.dart';
import 'package:kero_space/features/health/data/models/health_collections.dart';

class BarcodeService {
  final Dio _dio;

  BarcodeService(this._dio);

  Future<Ingredient?> getProductFromBarcode(String barcode) async {
    try {
      final response = await _dio.get('https://world.openfoodfacts.org/api/v0/product/$barcode.json');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 1) {
          final product = data['product'];
          final nutriments = product['nutriments'] ?? {};
          
          return Ingredient()
            ..deviceId = 'local'
            ..platform = 'openfoodfacts'
            ..name = product['product_name'] ?? 'Unknown Product'
            ..calories = (nutriments['energy-kcal_100g'] ?? nutriments['energy-kcal'] ?? 0).toDouble()
            ..protein = (nutriments['proteins_100g'] ?? 0).toDouble()
            ..carbs = (nutriments['carbohydrates_100g'] ?? 0).toDouble()
            ..fat = (nutriments['fat_100g'] ?? 0).toDouble()
            ..isFastingCompliant = false; // Cannot guarantee fasting compliance from raw OFF data
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
