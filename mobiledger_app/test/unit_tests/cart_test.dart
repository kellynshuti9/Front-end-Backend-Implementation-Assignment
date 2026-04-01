// test/unit_tests/cart_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Cart Calculation Tests', () {
    test('Calculate subtotal for empty cart', () {
      final cartItems = <Map<String, dynamic>>[];
      
      int subtotal = 0;
      for (var item in cartItems) {
        final price = item['price'] as int;
        final quantity = item['quantity'] as int;
        subtotal += price * quantity;
      }
      
      expect(subtotal, 0);
    });

    test('Calculate subtotal for single item', () {
      final cartItems = [
        {'price': 2500, 'quantity': 2}
      ];
      
      int subtotal = 0;
      for (var item in cartItems) {
        final price = item['price'] as int;
        final quantity = item['quantity'] as int;
        subtotal += price * quantity;
      }
      
      expect(subtotal, 5000);
    });

    test('Calculate subtotal for multiple items', () {
      final cartItems = [
        {'price': 2500, 'quantity': 2},
        {'price': 1500, 'quantity': 1},
        {'price': 500, 'quantity': 3},
      ];
      
      int subtotal = 0;
      for (var item in cartItems) {
        final price = item['price'] as int;
        final quantity = item['quantity'] as int;
        subtotal += price * quantity;
      }
      
      expect(subtotal, 8000);
    });

    test('Calculate total with delivery fee', () {
      int subtotal = 8000;
      int deliveryFee = 500;
      int discount = 0;
      int total = subtotal + deliveryFee - discount;
      expect(total, 8500);
    });

    test('Calculate total with discount', () {
      int subtotal = 10000;
      int deliveryFee = 500;
      int discount = 1000;
      int total = subtotal + deliveryFee - discount;
      expect(total, 9500);
    });
  });
}