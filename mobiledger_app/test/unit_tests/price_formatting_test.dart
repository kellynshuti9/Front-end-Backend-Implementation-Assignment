// test/unit_tests/price_formatting_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Price Formatting Tests', () {
    String formatPrice(int price) {
      if (price >= 1000) {
        final thousands = (price / 1000).floor();
        final remainder = price % 1000;
        if (remainder == 0) {
          return '${thousands}K RWF';
        }
        return '${thousands}K $remainder RWF';
      }
      return '$price RWF';
    }
    
    test('Format small prices', () {
      expect(formatPrice(500), '500 RWF');
      expect(formatPrice(999), '999 RWF');
      expect(formatPrice(0), '0 RWF');
    });
    
    test('Format thousand prices', () {
      expect(formatPrice(1000), '1K RWF');
      expect(formatPrice(2000), '2K RWF');
      expect(formatPrice(5000), '5K RWF');
    });
    
    test('Format prices with remainder', () {
      expect(formatPrice(1500), '1K 500 RWF');
      expect(formatPrice(2500), '2K 500 RWF');
      expect(formatPrice(12500), '12K 500 RWF');
    });
    
    test('Format large prices', () {
      expect(formatPrice(1000000), '1000K RWF');
      expect(formatPrice(1250000), '1250K RWF');
    });
  });
}