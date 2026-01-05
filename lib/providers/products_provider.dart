import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/product.dart';

class ProductsProvider extends ChangeNotifier {
  List<Product> products = [];
  bool loading = false;
  String? error;

  ProductsProvider();

  Future<void> fetchProducts() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      products = await SupabaseService.fetchProducts();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
