// lib/presentation/screens/shopping_cart_screen.dart
import 'package:flutter/material.dart';
import 'package:mobiledger_app/services/firebase_service.dart';

class ShoppingCartScreen extends StatefulWidget {
  const ShoppingCartScreen({super.key});

  @override
  State<ShoppingCartScreen> createState() => _ShoppingCartScreenState();
}

class _ShoppingCartScreenState extends State<ShoppingCartScreen> {
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;
  bool _isPlacingOrder = false;
  int _deliveryFee = 500;
  int _discount = 0;
  String _selectedPayment = 'Mobile Money';
  
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => _isLoading = true);
    
    final userId = _firebaseService.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final cart = await _firebaseService.getCart(userId);
      final items = cart['items'] as Map? ?? {};
      
      final List<Map<String, dynamic>> cartItems = [];
      items.forEach((key, value) {
        final item = Map<String, dynamic>.from(value as Map);
        item['id'] = key;
        cartItems.add(item);
      });
      
      setState(() {
        _cartItems = cartItems;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading cart: $e');
      setState(() => _isLoading = false);
    }
  }

  int get _subtotal {
    return _cartItems.fold(0, (sum, item) {
      final price = item['price'] as int? ?? 0;
      final quantity = item['quantity'] as int? ?? 0;
      return sum + (price * quantity);
    });
  }

  int get _total {
    return _subtotal + _deliveryFee - _discount;
  }

  Future<void> _updateQuantity(String productId, int newQuantity) async {
    final userId = _firebaseService.currentUser?.uid;
    if (userId == null) return;
    
    try {
      await _firebaseService.updateCartQuantity(userId, productId, newQuantity);
      await _loadCart();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating quantity: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeItem(String productId) async {
    final userId = _firebaseService.currentUser?.uid;
    if (userId == null) return;
    
    try {
      await _firebaseService.removeFromCart(userId, productId);
      await _loadCart();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item removed from cart'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing item: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _placeOrder() async {
    final userId = _firebaseService.currentUser?.uid;
    final userName = _firebaseService.currentUser?.displayName ?? 'Customer';
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to place order'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() => _isPlacingOrder = true);
    
    try {
      final orderData = {
        'buyerId': userId,
        'buyerName': userName,
        'items': _cartItems.map((item) => {
          'productId': item['productId'],
          'productName': item['productName'],
          'price': item['price'],
          'quantity': item['quantity'],
        }).toList(),
        'subtotal': _subtotal,
        'deliveryFee': _deliveryFee,
        'discount': _discount,
        'total': _total,
        'paymentMethod': _selectedPayment,
        'deliveryAddress': 'K6 7 Ave, Kigali, Rwanda',
      };
      
      await _firebaseService.createTransaction(orderData);
      await _firebaseService.clearCart(userId);
      
      if (mounted) {
        _showOrderConfirmation();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error placing order: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isPlacingOrder = false);
    }
  }

  void _showOrderConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Color(0xFF4CAF50),
              size: 60,
            ),
            const SizedBox(height: 16),
            const Text(
              'Order Confirmation!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Thank you for your order.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Order #MOB-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Date: ${DateTime.now().day} ${_getMonthName(DateTime.now().month)} ${DateTime.now().year}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    'Payment: $_selectedPayment',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    'Delivery: 3-5 business days',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total: $_total RWF',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'CONTINUE SHOPPING',
              style: TextStyle(color: Color(0xFF4CAF50)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/dashboard');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
            child: const Text('GO TO DASHBOARD'),
          ),
        ],
      ),
    );
    
    setState(() => _isPlacingOrder = false);
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Shopping Cart',
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
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Cart'),
              Tab(text: 'Checkout'),
            ],
            indicatorColor: Color(0xFF4CAF50),
            labelColor: Color(0xFF4CAF50),
            unselectedLabelColor: Colors.grey,
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildCartTab(),
                  _buildCheckoutTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildCartTab() {
    if (_cartItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Your cart is empty',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some products to your cart',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue Shopping'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _cartItems.length,
            itemBuilder: (context, index) {
              final item = _cartItems[index];
              final price = item['price'] as int? ?? 0;
              final quantity = item['quantity'] as int? ?? 0;
              final productId = item['productId'] ?? item['id'];
              final productName = item['productName'] ?? 'Product';
              final itemTotal = price * quantity;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        color: Color(0xFF4CAF50),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$price RWF',
                            style: const TextStyle(
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        if (quantity > 1) {
                                          _updateQuantity(productId, quantity - 1);
                                        }
                                      },
                                      icon: const Icon(Icons.remove, size: 18),
                                      constraints: const BoxConstraints(minWidth: 30),
                                    ),
                                    SizedBox(
                                      width: 30,
                                      child: Text(
                                        '$quantity',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        _updateQuantity(productId, quantity + 1);
                                      },
                                      icon: const Icon(Icons.add, size: 18),
                                      constraints: const BoxConstraints(minWidth: 30),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: () => _removeItem(productId),
                                child: const Text(
                                  'Remove',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$itemTotal RWF',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'ORDER SUMMARY',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildSummaryRow(
                'Subtotal (${_cartItems.length} items)',
                '$_subtotal RWF',
              ),
              _buildSummaryRow('Delivery Fee', '$_deliveryFee RWF'),
              _buildSummaryRow('Discount', '$_discount RWF'),
              const Divider(height: 24),
              _buildSummaryRow('TOTAL', '$_total RWF', isTotal: true),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    DefaultTabController.of(context).animateTo(1);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'PROCEED TO CHECKOUT',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DELIVERY ADDRESS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Edit Address',
                      style: TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'John Doe',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'K6 7 Ave, Kigali, Rwanda',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '+250 788 123 456',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PAYMENT METHOD',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                RadioListTile<String>(
                  value: 'Mobile Money',
                  groupValue: _selectedPayment,
                  onChanged: (value) {
                    setState(() {
                      _selectedPayment = value!;
                    });
                  },
                  title: const Text('Mobile Money (MTN/Airtel)'),
                  activeColor: const Color(0xFF4CAF50),
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<String>(
                  value: 'Credit/Debit Card',
                  groupValue: _selectedPayment,
                  onChanged: (value) {
                    setState(() {
                      _selectedPayment = value!;
                    });
                  },
                  title: const Text('Credit / Debit Card'),
                  activeColor: const Color(0xFF4CAF50),
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<String>(
                  value: 'Cash on Delivery',
                  groupValue: _selectedPayment,
                  onChanged: (value) {
                    setState(() {
                      _selectedPayment = value!;
                    });
                  },
                  title: const Text('Cash on Delivery'),
                  activeColor: const Color(0xFF4CAF50),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ORDER SUMMARY',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ..._cartItems.map((item) {
                  final price = item['price'] as int? ?? 0;
                  final quantity = item['quantity'] as int? ?? 0;
                  final productName = item['productName'] ?? 'Product';
                  final itemTotal = price * quantity;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$productName x$quantity',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text('$itemTotal RWF', style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  );
                }).toList(),
                const Divider(height: 16),
                _buildSummaryRow('Subtotal', '$_subtotal RWF'),
                _buildSummaryRow('Delivery Fee', '$_deliveryFee RWF'),
                const Divider(height: 16),
                _buildSummaryRow('TOTAL', '$_total RWF', isTotal: true),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isPlacingOrder ? null : _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isPlacingOrder
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'PLACE ORDER',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? const Color(0xFF4CAF50) : null,
            ),
          ),
        ],
      ),
    );
  }
}