// lib/presentation/screens/credit_tracker_screen.dart
import 'package:flutter/material.dart';


import 'package:mobiledger_app/services/firebase_service.dart';


class CreditTrackerScreen extends StatefulWidget {
  const CreditTrackerScreen({super.key});


  @override
  State<CreditTrackerScreen> createState() => _CreditTrackerScreenState();
}


class _CreditTrackerScreenState extends State<CreditTrackerScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Overdue', 'Active', 'Paid'];
 
  List<Map<String, dynamic>> _credits = [];
  bool _isLoading = true;
 
  final FirebaseService _firebaseService = FirebaseService();


  @override
  void initState() {
    super.initState();
    _loadCredits();
  }


  Future<void> _loadCredits() async {
    setState(() => _isLoading = true);
   
    final userId = _firebaseService.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
   
    try {
      final credits = await _firebaseService.getCredits(userId);
      setState(() {
        _credits = credits;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading credits: $e');
      setState(() => _isLoading = false);
    }
  }


  // ✅ FIXED: Cast to int explicitly
  int get _totalOwed {
    return _credits.fold(0, (sum, credit) {
      if (credit['status'] != 'Paid') {
        final amount = credit['amount'] as int? ?? 0;
        return sum + amount;
      }
      return sum;
    });
  }


  // ✅ FIXED: Cast to int explicitly
  int get _overdue {
    return _credits.fold(0, (sum, credit) {
      if (credit['status'] == 'Overdue') {
        final amount = credit['amount'] as int? ?? 0;
        return sum + amount;
      }
      return sum;
    });
  }


  // ✅ FIXED: Cast to int explicitly
  int get _dueThis {
    return _credits.fold(0, (sum, credit) {
      if (credit['status'] == 'Active') {
        final amount = credit['amount'] as int? ?? 0;
        return sum + amount;
      }
      return sum;
    });
  }


  List<Map<String, dynamic>> get _filteredCredits {
    if (_selectedFilter == 'All') return _credits;
    return _credits.where((credit) => credit['status'] == _selectedFilter).toList();
  }


  Future<void> _markAsPaid(String creditId, int index) async {
    try {
      await _firebaseService.markCreditAsPaid(creditId);
      setState(() {
        _credits[index]['status'] = 'Paid';
        _credits[index]['paidDate'] = DateTime.now().millisecondsSinceEpoch;
      });
     
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marked as paid!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
          'Credit Tracker',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF4CAF50)),
            onPressed: () {
              _showAddCreditDialog();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Total Owed',
                          value: '$_totalOwed RWF',
                          color: const Color(0xFF4CAF50),
                          icon: Icons.account_balance_wallet,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Overdue',
                          value: '$_overdue RWF',
                          color: Colors.red,
                          icon: Icons.warning_amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Due This',
                          value: '$_dueThis RWF',
                          color: const Color(0xFFFF9800),
                          icon: Icons.calendar_today,
                        ),
                      ),
                    ],
                  ),
                ),
               
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: const Color(0xFF4CAF50).withOpacity(0.1),
                          checkmarkColor: const Color(0xFF4CAF50),
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade700,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
               
                const SizedBox(height: 8),
               
                Expanded(
                  child: _filteredCredits.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredCredits.length,
                          itemBuilder: (context, index) {
                            final credit = _filteredCredits[index];
                            final isOverdue = credit['status'] == 'Overdue';
                            final isPaid = credit['status'] == 'Paid';
                            final amount = credit['amount'] as int? ?? 0;
                            final daysAgo = credit['daysAgo'] as int? ?? 0;
                            final dueDate = credit['dueDate'] as String? ?? '';
                           
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: isOverdue
                                    ? Border.all(color: Colors.red.shade100)
                                    : null,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          credit['customerName'] ?? 'Customer',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isOverdue
                                              ? Colors.red.shade50
                                              : isPaid
                                                  ? Colors.green.shade50
                                                  : Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          credit['status'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isOverdue
                                                ? Colors.red
                                                : isPaid
                                                    ? Colors.green
                                                    : Colors.orange,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Amount: $amount RWF',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF4CAF50),
                                        ),
                                      ),
                                      Text(
                                        isPaid
                                            ? 'Paid: ${_formatDate(credit['paidDate'])}'
                                            : 'Due: $dueDate${daysAgo > 0 ? ' ($daysAgo days ago)' : daysAgo == 0 ? ' (Today)' : ''}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isOverdue
                                              ? Colors.red
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Product: ${credit['product'] ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Phone: ${credit['customerPhone'] ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                 
                                  if (!isPaid)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Calling customer...'),
                                                ),
                                              );
                                            },
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: Color(0xFF4CAF50)),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: const Text('Call'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Reminder sent!'),
                                                  backgroundColor: Colors.orange,
                                                ),
                                              );
                                            },
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: Color(0xFFFF9800)),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: const Text('Remind'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () => _markAsPaid(credit['id'], index),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF4CAF50),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: const Text('Paid'),
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Repeat order created!'),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            },
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: Color(0xFF4CAF50)),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: const Text('Accept'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Order repeated!'),
                                                  backgroundColor: Color(0xFF4CAF50),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF4CAF50),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: const Text('Repeat'),
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


  void _showAddCreditDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final amountController = TextEditingController();
    final productController = TextEditingController();
    final dueDateController = TextEditingController();
   
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Credit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Customer Name',
                  hintText: 'Enter customer name',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+250 788 123 456',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (RWF)',
                  hintText: 'Enter amount',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: productController,
                decoration: const InputDecoration(
                  labelText: 'Product',
                  hintText: 'Product name',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dueDateController,
                decoration: const InputDecoration(
                  labelText: 'Due Date',
                  hintText: 'DD/MM/YYYY',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && amountController.text.isNotEmpty) {
                final userId = _firebaseService.currentUser?.uid;
                if (userId != null) {
                  await _firebaseService.addCredit({
                    'sellerId': userId,
                    'customerName': nameController.text,
                    'customerPhone': phoneController.text,
                    'amount': int.parse(amountController.text),
                    'product': productController.text,
                    'dueDate': dueDateController.text,
                    'status': 'active',
                  });
                  _loadCredits();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Credit added successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }


  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
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
            Icons.credit_card_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Credit Records',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add credit records',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }


  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is int) {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return '${date.day} ${_getMonthName(date.month)} ${date.year}';
    }
    return 'N/A';
  }


  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
