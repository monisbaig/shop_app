import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProductModelProvider extends ChangeNotifier {
  final String? id;
  final String? title;
  final String? description;
  final double? price;
  final String? imageUrl;
  bool? isFavorite;

  ProductModelProvider({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.isFavorite = false,
  });

  // void _setFavVal(bool newValue) {
  //   isFavorite = newValue;
  //   notifyListeners();
  // }

  Future<void> toggleFavorite(String authToken, String userId) async {
    final oldStatus = isFavorite;
    isFavorite = !isFavorite!;
    notifyListeners();
    final url = Uri.parse(
        'https://shop-app-fb09f-default-rtdb.asia-southeast1.firebasedatabase.app/userFavorites/$userId/$id.json?auth=$authToken');
    try {
      await http.put(
        url,
        body: jsonEncode(isFavorite),
      );
    } catch (e) {
      isFavorite = oldStatus;
      notifyListeners();
      print(e);
    }
  }
}
