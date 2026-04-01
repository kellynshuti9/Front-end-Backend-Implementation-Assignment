// lib/presentation/screens/my_products_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mobiledger_app/presentation/screens/edit_product_screen.dart';
import 'package:mobiledger_app/presentation/screens/product_details_screen.dart';

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({super.key});

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> {
  String _searchQuery = '';
  String _filterStatus = 'All';
  
  int _activeCount = 0;
  int _lowStockCount = 0;
  int _outCount = 0;
  bool _isLoading = true;
  
  List<Map<String, dynamic>> _products = [];
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final snapshot = await _database
          .child('products')
          .orderByChild('sellerId')
          .equalTo(userId)
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
        _updateCounts();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      setState(() => _isLoading = false);
    }
  }

  void _updateCounts() {
    int active = 0;
    int lowStock = 0;
    int out = 0;
    
    for (var product in _products) {
      final stock = product['stock'] as int? ?? 0;
      if (stock == 0) {
        out++;
      } else if (stock <= 5) {
        lowStock++;
      } else {
        active++;
      }
    }
    
    setState(() {
      _activeCount = active;
      _lowStockCount = lowStock;
      _outCount = out;
    });
  }

  List<Map<String, dynamic>> get _filteredProducts {
    var filtered = _products;
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        final productName = product['productName']?.toString().toLowerCase() ?? '';
        return productName.contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    if (_filterStatus != 'All') {
      filtered = filtered.where((product) {
        final stock = product['stock'] as int? ?? 0;
        if (_filterStatus == 'Active') return stock > 5;
        if (_filterStatus == 'Low Stock') return stock > 0 && stock <= 5;
        if (_filterStatus == 'Out') return stock == 0;
        return true;
      }).toList();
    }
    
    return filtered;
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      await _database.child('products').child(productId).remove();
      _loadProducts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting product: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(String productId, String productName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Product?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "$productName"?'),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await _deleteProduct(productId);
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
          'My Products',
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
              Navigator.pushNamed(context, '/add-product').then((_) => _loadProducts());
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
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
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search products',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ),
                
                // Status Filters
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildFilterChip('All', _filterStatus == 'All'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Active: $_activeCount', _filterStatus == 'Active'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Low Stock: $_lowStockCount', _filterStatus == 'Low Stock'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Out: $_outCount', _filterStatus == 'Out'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Products List - Clickable Products
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            final stock = product['stock'] as int? ?? 0;
                            final price = product['price'] ?? 0;
                            final category = product['category'] ?? 'Uncategorized';
                            final productName = product['productName'] ?? 'No name';
                            final productId = product['id'] ?? '';
                            
                            Color stockColor;
                            String stockText;
                            if (stock == 0) {
                              stockColor = Colors.red;
                              stockText = 'Out of Stock';
                            } else if (stock <= 5) {
                              stockColor = Colors.orange;
                              stockText = 'Low Stock: $stock';
                            } else {
                              stockColor = Colors.green;
                              stockText = 'In Stock: $stock';
                            }
                            
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailsScreen(
                                      productId: productId,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
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
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius: BorderRadius.circular(8),
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
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Price: $price RWF',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF4CAF50),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey.shade100,
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        category,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.grey.shade600,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: stockColor.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        stockText,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: stockColor,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => EditProductScreen(
                                                      productId: productId,
                                                      productData: product,
                                                    ),
                                                  ),
                                                ).then((_) => _loadProducts());
                                              },
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(color: Color(0xFF4CAF50)),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                              ),
                                              child: const Text(
                                                'Edit',
                                                style: TextStyle(color: Color(0xFF4CAF50)),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () => _showDeleteConfirmation(productId, productName),
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(color: Colors.red),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                              ),
                                              child: const Text(
                                                'Delete',
                                                style: TextStyle(color: Colors.red),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = label.split(':')[0].trim();
        });
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF4CAF50).withOpacity(0.1),
      checkmarkColor: const Color(0xFF4CAF50),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Products Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'No products match your search'
                : 'Tap the + button to add your first product',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Clear Search'),
            ),
          ] else ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/add-product').then((_) => _loadProducts());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('ADD PRODUCT'),
            ),
          ],
        ],
      ),
    );
  }
}