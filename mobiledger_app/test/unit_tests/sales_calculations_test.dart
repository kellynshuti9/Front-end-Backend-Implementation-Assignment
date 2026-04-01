// test/unit_tests/sales_calculations_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Sales Calculations Tests', () {
    test('Calculate total sales from transactions', () {
      final transactions = [
        {'total': 10000, 'status': 'completed'},
        {'total': 25000, 'status': 'completed'},
        {'total': 5000, 'status': 'pending'},
        {'total': 15000, 'status': 'completed'},
      ];
      
      int totalSales = 0;
      for (var t in transactions) {
        if (t['status'] == 'completed') {
          totalSales += t['total'] as int;
        }
      }
      
      expect(totalSales, 50000);
    });
    
    test('Calculate average sale amount', () {
      final transactions = [
        {'total': 10000},
        {'total': 25000},
        {'total': 15000},
      ];
      
      int totalSales = transactions.fold(0, (sum, t) => sum + (t['total'] as int));
      int averageSale = totalSales ~/ transactions.length;
      
      expect(totalSales, 50000);
      expect(averageSale, 16666);
    });
    
    test('Filter transactions by period - Today', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final transactions = [
        {'createdAt': today.millisecondsSinceEpoch, 'amount': 10000},
        {'createdAt': today.subtract(const Duration(days: 1)).millisecondsSinceEpoch, 'amount': 20000},
        {'createdAt': today.millisecondsSinceEpoch, 'amount': 15000},
      ];
      
      final todayTransactions = transactions.where((t) {
        final date = DateTime.fromMillisecondsSinceEpoch(t['createdAt'] as int);
        return date.day == today.day && date.month == today.month && date.year == today.year;
      }).toList();
      
      expect(todayTransactions.length, 2);
      expect(todayTransactions[0]['amount'], 10000);
      expect(todayTransactions[1]['amount'], 15000);
    });
    
    test('Calculate profit margin', () {
      int calculateProfit(int sales, double margin) {
        return (sales * margin).round();
      }
      
      expect(calculateProfit(100000, 0.2), 20000);
      expect(calculateProfit(25000, 0.15), 3750);
      expect(calculateProfit(50000, 0.25), 12500);
    });
  });
}