import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';
import '../models/product.dart';

class CatalogRepository {
  final http.Client client;
  CatalogRepository({http.Client? client}) : client = client ?? http.Client();

  Future<List<Product>> loadCatalog() async {
    final merged = <String, Product>{};

    final baseResponse = await client.get(AppConfig.endpoint('/products.json'));
    if (baseResponse.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(baseResponse.bodyBytes));
      final list = decoded is Map<String, dynamic> ? decoded['products'] : null;
      if (list is List) {
        for (final item in list.whereType<Map>()) {
          final product = Product.fromJson(Map<String, dynamic>.from(item));
          if (product.id.isNotEmpty) merged[product.id] = product;
        }
      }
    }

    for (final path in const ['/catalog-expanded-a.js', '/catalog-expanded-b.js']) {
      try {
        final response = await client.get(AppConfig.endpoint(path));
        if (response.statusCode != 200) continue;
        final object = _decodeWindowJson(utf8.decode(response.bodyBytes));
        final rows = object['p'];
        if (rows is List) {
          for (final row in rows.whereType<List>()) {
            final product = Product.fromCompactRow(row);
            if (product.id.isNotEmpty) merged.putIfAbsent(product.id, () => product);
          }
        }
      } catch (_) {
        // Base catalog remains usable if an expansion file is unavailable.
      }
    }

    try {
      final overridesResponse = await client.get(AppConfig.endpoint('/api/catalog/overrides'));
      if (overridesResponse.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(overridesResponse.bodyBytes));
        final items = decoded is Map<String, dynamic> ? decoded['items'] : null;
        if (items is List) {
          for (final raw in items.whereType<Map>()) {
            final item = Map<String, dynamic>.from(raw);
            final id = '${item['productId'] ?? ''}';
            final existing = merged[id];
            if (existing == null || item['published'] == false) continue;
            merged[id] = existing.copyWith(
              stock: '${item['stock'] ?? existing.stock}',
              image: '${item['image'] ?? existing.image}',
              specs: item['specs'] is Map ? (item['specs'] as Map).map((k, v) => MapEntry('$k', '$v')) : existing.specs,
              imageVerified: item['imageVerified'] == true ? true : existing.imageVerified,
            );
          }
        }
      }
    } catch (_) {}

    final products = merged.values.toList();
    products.sort((a, b) => '${a.brand} ${a.model}'.compareTo('${b.brand} ${b.model}'));
    return products;
  }

  Map<String, dynamic> _decodeWindowJson(String source) {
    final start = source.indexOf('{');
    final end = source.lastIndexOf('}');
    if (start < 0 || end <= start) return const {};
    final decoded = jsonDecode(source.substring(start, end + 1));
    return decoded is Map<String, dynamic> ? decoded : const {};
  }
}
