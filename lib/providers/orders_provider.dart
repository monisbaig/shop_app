import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'cart_provider.dart';

class OrderProviderItem {
  final String? id;
  final double? amount;
  final List<CartProviderItem>? products;
  final DateTime? dateTime;

  OrderProviderItem({
    required this.id,
    required this.amount,
    required this.products,
    required this.dateTime,
  });
}

class OrdersProvider with ChangeNotifier {
  List<OrderProviderItem>? _orders = [];
  String? authToken;
  String? userId;

  OrdersProvider(this.authToken, this._orders, this.userId);

  List<OrderProviderItem>? get orders {
    return [..._orders!];
  }

  Future<void> fetchAndSetOrders() async {
    final url = Uri.parse(
        'https://shop-app-fb09f-default-rtdb.asia-southeast1.firebasedatabase.app/orders/$userId.json?auth=$authToken');
    try {
      final response = await http.get(url);
      final extractedData = jsonDecode(response.body) as Map<String, dynamic>;
      List<OrderProviderItem> loadedOrders = [];
      if (extractedData == null) {
        return;
      }
      extractedData.forEach((orderId, orderData) {
        loadedOrders.add(
          OrderProviderItem(
            id: orderId,
            amount: orderData['amount'],
            dateTime: DateTime.parse(orderData['dateTime']),
            products: (orderData['products'] as List<dynamic>)
                .map(
                  (item) => CartProviderItem(
                    id: item['id'],
                    title: item['title'],
                    quantity: item['quantity'],
                    price: item['price'],
                  ),
                )
                .toList(),
          ),
        );
      });
      _orders = loadedOrders.reversed.toList();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addOrder(
      List<CartProviderItem> cartProducts, double total) async {
    final url = Uri.parse(
      'https://shop-app-fb09f-default-rtdb.asia-southeast1.firebasedatabase.app/orders/$userId.json?auth=$authToken',
    );
    final timeStamp = DateTime.now();
    try {
      final response = await http.post(
        url,
        body: jsonEncode({
          'amount': total,
          'dateTime': timeStamp.toIso8601String(),
          'products': cartProducts
              .map((cp) => {
                    'id': cp.id,
                    'title': cp.title,
                    'quantity': cp.quantity,
                    'price': cp.price,
                  })
              .toList(),
        }),
      );
      _orders!.insert(
        0,
        OrderProviderItem(
          id: jsonDecode(response.body)['name'],
          amount: total,
          dateTime: timeStamp,
          products: cartProducts,
        ),
      );
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
