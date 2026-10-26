import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/catalog_repository.dart';
import '../models/product.dart';

class AppController extends ChangeNotifier {
  final CatalogRepository repository;
  AppController({CatalogRepository? repository}) : repository = repository ?? CatalogRepository();

  List<Product> products = [];
  final Set<String> favorites = {};
  final List<String> compare = [];
  String language = 'ru';
  bool loading = true;
  String? error;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    language = prefs.getString('medika_lang') ?? 'ru';
    favorites.addAll(prefs.getStringList('medika_fav') ?? const []);
    compare.addAll(prefs.getStringList('medika_cmp') ?? const []);
    await refreshCatalog();
  }

  Future<void> refreshCatalog() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      products = await repository.loadCatalog();
      final ids = products.map((e) => e.id).toSet();
      favorites.removeWhere((id) => !ids.contains(id));
      compare.removeWhere((id) => !ids.contains(id));
      if (compare.isNotEmpty) {
        final category = byId(compare.first)?.category;
        compare.removeWhere((id) => byId(id)?.category != category);
      }
    } catch (e) {
      error = '$e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Product? byId(String id) {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  Future<void> toggleFavorite(String id) async {
    favorites.contains(id) ? favorites.remove(id) : favorites.add(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('medika_fav', favorites.toList());
    notifyListeners();
  }

  Future<String?> toggleCompare(Product product) async {
    if (compare.contains(product.id)) {
      compare.remove(product.id);
    } else {
      if (compare.isNotEmpty && byId(compare.first)?.category != product.category) {
        return language == 'tj' ? 'Танҳо моделҳои як категория муқоиса мешаванд' : 'Сравнивать можно модели одной категории';
      }
      if (compare.length >= 3) {
        return language == 'tj' ? 'Максимум 3 модел' : 'Максимум 3 модели';
      }
      compare.add(product.id);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('medika_cmp', compare);
    notifyListeners();
    return null;
  }

  Future<void> toggleLanguage() async {
    language = language == 'ru' ? 'tj' : 'ru';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('medika_lang', language);
    notifyListeners();
  }
}
