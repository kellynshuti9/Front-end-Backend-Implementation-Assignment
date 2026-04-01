// lib/presentation/screens/shop_details_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mobiledger_app/services/firebase_service.dart';

class ShopDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? shopData;
  
  const ShopDetailsScreen({super.key, this.shopData});

  @override
  State<ShopDetailsScreen> createState() => _ShopDetailsScreenState();
}

class _ShopDetailsScreenState extends State<ShopDetailsScreen> {
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  Map<String, bool> _addingToCart = {};
  
  final FirebaseService _firebaseService = FirebaseService();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _loadShopProducts();
  }

  Future<void> _loadShopProducts() async {
    setState(() => _isLoading = true);
    
    final shopId = widget.shopData?['id'];
    if (shopId == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final snapshot = await _database
          .child('products')
          .orderByChild('shopId')
          .equalTo(shopId)
          .get();
      
      final List<Map<String, dynamic>> products = [];
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          data['id'] = child.key;
          products.add(data);
        }
      }
      
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading shop products: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addToCart(Map<String, dynamic> product) async {
    final userId = _firebaseService.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to add items to cart'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _addingToCart[product['id']] = true;
    });

    try {
      await _firebaseService.addToCart(userId, {
        'id': product['id'],
        'productName': product['productName'],
        'price': product['price'],
        'quantity': 1,
        'image': '',
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product['productName']} added to cart!'),
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
    } finally {
      setState(() {
        _addingToCart[product['id']] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shopData ?? {
      'name': 'Kigali Fresh Market',
      'owner': 'Jean de Dieu',
      'location': 'Kicukiro, Kigali',
      'phone': '+250 78 123 4567',
      'email': 'contact@kigalifresh.com',
      'hours': '7AM-8PM (Mon-Sat)',
      'rating': 4.5,
      'reviews': 128,
      'about': 'Family-owned fresh market since 2020. Groceries, fruits, vegetables, and household essentials. Delivery in Kigali. Cash & mobile money.',
    };
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          shop['name'] ?? 'Shop Details',
          style: const TextStyle(
            fontSize: 18,
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
            icon: const Icon(Icons.share_outlined, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        (shop['name'] ?? 'KF').toString().substring(0, 2).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    shop['name'] ?? 'Kigali Fresh Market',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${shop['rating']}/5 (${shop['reviews']} reviews)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Contact Information
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildContactRow(Icons.person_outline, 'Owner: ${shop['owner']}'),
                  _buildContactRow(Icons.location_on_outlined, shop['location']),
                  _buildContactRow(Icons.phone_outlined, shop['phone']),
                  _buildContactRow(Icons.email_outlined, shop['email']),
                  _buildContactRow(Icons.access_time_outlined, shop['hours']),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // About
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    shop['about'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Products Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Products',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _products.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                  'No products available in this shop',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _products.length,
                              itemBuilder: (context, index) {
                                final product = _products[index];
                                final price = product['price'] ?? 0;
                                final productName = product['productName'] ?? 'Product';
                                final stock = product['stock'] ?? 0;
                                final isAdding = _addingToCart[product['id']] ?? false;
                                
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      // Product Image
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.shopping_bag_outlined,
                                          color: Color(0xFF4CAF50),
                                          size: 24,
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
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '$price RWF',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF4CAF50),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            if (stock > 0)
                                              Text(
                                                'In Stock: $stock',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.green.shade700,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: stock > 0 ? (isAdding ? null : () => _addToCart(product)) : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF4CAF50),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          minimumSize: const Size(80, 36),
                                        ),
                                        child: isAdding
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Text(
                                                'Add to Cart',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
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
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF4CAF50)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Message'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/cart');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('View Cart'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String? text) {
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}