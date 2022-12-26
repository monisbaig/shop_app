import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shop_app/models/http_exception.dart';

import 'product_model_provider.dart';

class ProductsProvider extends ChangeNotifier {
  List<ProductModelProvider>? _items = [];
  String? _authToken;
  String? _userId;

  getAuth(token, items, userId) {
    _authToken = token;
    _items = items;
    _userId = userId;
  }

  List<ProductModelProvider>? get items {
    return [..._items!];
  }

  List<ProductModelProvider>? get favoriteItems {
    return _items!.where((prodItems) => prodItems.isFavorite!).toList();
  }

  ProductModelProvider? findById(String? id) {
    return _items!.firstWhereOrNull((prodId) => prodId.id == id);
  }

  Future<void> fetchAndSetProducts([bool filterByUser = false]) async {
    final filterString =
        filterByUser ? 'orderBy="creatorId"&equalTo="$_userId"' : '';
    var url = Uri.parse(
      'https://shop-app-fb09f-default-rtdb.asia-southeast1.firebasedatabase.app/products.json?auth=$_authToken&$filterString',
    );
    try {
      final response = await http.get(url);
      final extractedData = jsonDecode(response.body) as Map<String, dynamic>;
      if (extractedData == null) {
        return;
      }
      url = Uri.parse(
          'https://shop-app-fb09f-default-rtdb.asia-southeast1.firebasedatabase.app/userFavorites/$_userId.json?auth=$_authToken');
      final favoriteResponse = await http.get(url);
      final favoriteData = jsonDecode(favoriteResponse.body);
      final List<ProductModelProvider> loadedProducts = [];

      extractedData.forEach((prodId, prodData) {
        loadedProducts.add(
          ProductModelProvider(
            id: prodId,
            title: prodData['title'],
            description: prodData['description'],
            price: prodData['price'],
            imageUrl: prodData['imageUrl'],
            isFavorite:
                favoriteData == null ? false : favoriteData[prodId] ?? false,
          ),
        );
      });
      _items = loadedProducts;
      notifyListeners();
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<void> addProducts(ProductModelProvider product) async {
    final url = Uri.parse(
        'https://shop-app-fb09f-default-rtdb.asia-southeast1.firebasedatabase.app/products.json?auth=$_authToken');
    try {
      var response = await http.post(
        url,
        body: jsonEncode(
          {
            'title': product.title,
            'description': product.description,
            'price': product.price,
            'imageUrl': product.imageUrl,
            'creatorId': _userId,
          },
        ),
      );
      final newProduct = ProductModelProvider(
        id: jsonDecode(response.body)['name'],
        title: product.title,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
      );
      _items!.add(newProduct);
      notifyListeners();
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<void> updateProduct(String id, ProductModelProvider newProduct) async {
    final prodIndex = _items!.indexWhere((prod) => prod.id == id);
    if (prodIndex >= 0) {
      final url = Uri.parse(
          'https://shop-app-fb09f-default-rtdb.asia-southeast1.firebasedatabase.app/products/$id.json?auth=$_authToken');
      await http.patch(
        url,
        body: jsonEncode({
          'title': newProduct.title,
          'description': newProduct.description,
          'price': newProduct.price,
          'imageUrl': newProduct.imageUrl,
        }),
      );
      _items![prodIndex] = newProduct;
      notifyListeners();
    } else {}
  }

  Future<void> deleteProduct(String id) async {
    final url = Uri.parse(
        'https://shop-app-fb09f-default-rtdb.asia-southeast1.firebasedatabase.app/products/$id.json?auth=$_authToken');
    final existingProductIndex =
        _items!.indexWhere((prodId) => prodId.id == id);
    var existingProduct = _items![existingProductIndex];
    _items!.removeAt(existingProductIndex);
    notifyListeners();
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      _items!.insert(existingProductIndex, existingProduct);
      notifyListeners();
      throw HttpException('Could not delete product');
    }
    existingProduct.dispose();
  }
}
