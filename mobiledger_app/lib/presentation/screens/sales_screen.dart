// lib/presentation/screens/sales_screen.dart
import 'package:flutter/material.dart';
import 'package:mobiledger_app/services/firebase_service.dart';
// import 'package:intl/intl.dart';


class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});


  @override
  State<SalesScreen> createState() => _SalesScreenState();
}


class _SalesScreenState extends State<SalesScreen> {
  String _selectedPeriod = 'Today';
  final List<String> _periods = ['Today', 'This Week', 'This Month'];
 
  int _totalSales = 0;
  int _transactions = 0;
  int _avgSale = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactionsList = [];
 
  final FirebaseService _firebaseService = FirebaseService();


  @override
  void initState() {
    super.initState();
    _loadSalesData();
  }


  Future<void> _loadSalesData() async {
    setState(() => _isLoading = true);
   
    final userId = _firebaseService.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
   
    try {
      final transactions = await _firebaseService.getSellerTransactions(userId);
     
      // Filter by period
      final now = DateTime.now();
      final filtered = transactions.where((t) {
        final createdAt = DateTime.fromMillisecondsSinceEpoch(t['createdAt'] as int? ?? 0);
        if (_selectedPeriod == 'Today') {
          return createdAt.day == now.day && createdAt.month == now.month && createdAt.year == now.year;
        } else if (_selectedPeriod == 'This Week') {
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          return createdAt.isAfter(startOfWeek);
        } else {
          return createdAt.month == now.month && createdAt.year == now.year;
        }
      }).toList();
     
      int total = 0;
      for (var t in filtered) {
        total += t['total'] as int? ?? 0;
      }
     
      setState(() {
        _transactionsList = filtered;
        _totalSales = total;
        _transactions = filtered.length;
        _avgSale = _transactions > 0 ? total ~/ _transactions : 0;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading sales: $e');
      setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Sales',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Period Selector
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _periods.map((period) {
                      final isSelected = _selectedPeriod == period;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPeriod = period;
                          });
                          _loadSalesData();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF4CAF50)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            period,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey.shade600,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
               
                const SizedBox(height: 16),
               
                // Stats Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Total Sales',
                          value: '${_totalSales.toString()} RWF',
                          icon: Icons.trending_up,
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Transactions',
                          value: '$_transactions',
                          icon: Icons.receipt,
                          color: const Color(0xFF2196F3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Avg. Sale',
                          value: '${_avgSale.toString()} RWF',
                          icon: Icons.analytics,
                          color: const Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),
                ),
               
                const SizedBox(height: 24),
               
                // Recent Transactions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'View All',
                          style: TextStyle(color: Color(0xFF4CAF50)),
                        ),
                      ),
                    ],
                  ),
                ),
               
                const SizedBox(height: 12),
               
                Expanded(
                  child: _transactionsList.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _transactionsList.length,
                          itemBuilder: (context, index) {
                            final transaction = _transactionsList[index];
                            final date = DateTime.fromMillisecondsSinceEpoch(
                              transaction['createdAt'] as int? ?? 0,
                            );
                           
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.shopping_bag_outlined,
                                      color: Color(0xFF4CAF50),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          transaction['orderNumber'] ?? 'Order',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${transaction['items']?.length ?? 0} items • ${transaction['paymentMethod'] ?? 'Mobile Money'}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${transaction['total'] ?? 0} RWF',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4CAF50),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${date.day} ${_getMonthName(date.month)} ${date.year}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }


  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Transactions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When you make sales, they will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }


  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
