// test/unit_tests/product_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Product Model Tests', () {
    test('Create product with valid data', () {
      final product = {
        'productName': 'Test Product',
        'category': 'Food & Groceries',
        'price': 2500,
        'stock': 10,
      };
      
      expect(product['productName'], 'Test Product');
      expect(product['category'], 'Food & Groceries');
      expect(product['price'], 2500);
      expect(product['stock'], 10);
    });

    test('Product price calculation with quantity', () {
      int calculateTotal(int price, int quantity) {
        return price * quantity;
      }
      
      expect(calculateTotal(2500, 2), 5000);
      expect(calculateTotal(1000, 5), 5000);
      expect(calculateTotal(500, 0), 0);
    });

    test('Product stock status', () {
      String getStockStatus(int stock) {
        if (stock == 0) return 'Out of Stock';
        if (stock <= 5) return 'Low Stock';
        return 'In Stock';
      }
      
      expect(getStockStatus(0), 'Out of Stock');
      expect(getStockStatus(3), 'Low Stock');
      expect(getStockStatus(10), 'In Stock');
    });
  });
}