// lib/presentation/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mobiledger_app/services/firebase_service.dart';
import 'package:mobiledger_app/presentation/screens/create_shop_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  User? _currentUser;
  
  int _activeProducts = 0;
  int _todayInquiries = 5;
  int _monthlySales = 0;
  
  List<Map<String, dynamic>> _recentActivities = [];
  bool _isLoading = true;
  bool _hasShopLoaded = false;
  bool _userHasShop = false;
  
  final FirebaseService _firebaseService = FirebaseService();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _currentUser = _firebaseService.currentUser;
    _loadDashboardData();
    _checkUserShop();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    final userId = _currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final products = await _firebaseService.getProducts(sellerId: userId);
      final salesSummary = await _firebaseService.getSalesSummary(userId);
      final transactions = await _firebaseService.getSellerTransactions(userId);
      
      setState(() {
        _activeProducts = products.length;
        _monthlySales = salesSummary['totalSales'];
        
        if (transactions.isEmpty && products.isNotEmpty) {
          _recentActivities = products.take(5).map((p) {
            return {
              'title': 'Added: ${p['productName']}',
              'amount': '${p['price']} RWF',
            };
          }).toList();
        } else {
          _recentActivities = transactions.take(5).map((t) {
            return {
              'title': 'Order #${t['orderNumber']}',
              'amount': '${t['total']} RWF',
            };
          }).toList();
        }
        
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkUserShop() async {
    final userId = _firebaseService.currentUser?.uid;
    if (userId == null) {
      setState(() {
        _hasShopLoaded = true;
        _userHasShop = false;
      });
      return;
    }
    
    try {
      final snapshot = await _database.child('shops').orderByChild('ownerId').equalTo(userId).get();
      setState(() {
        _userHasShop = snapshot.exists && snapshot.children.isNotEmpty;
        _hasShopLoaded = true;
      });
    } catch (e) {
      setState(() {
        _hasShopLoaded = true;
        _userHasShop = false;
      });
    }
  }

  Future<void> _manageShop() async {
    final userId = _firebaseService.currentUser?.uid;
    if (userId == null) return;
    
    try {
      final snapshot = await _database.child('shops').orderByChild('ownerId').equalTo(userId).get();
      
      if (snapshot.exists && snapshot.children.isNotEmpty) {
        // User has a shop - go to edit
        final shop = snapshot.children.first;
        final shopData = Map<String, dynamic>.from(shop.value as Map);
        shopData['id'] = shop.key;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateShopScreen(existingShop: shopData),
          ),
        ).then((_) {
          _loadDashboardData();
          _checkUserShop();
        });
      } else {
        // No shop - create new
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateShopScreen()),
        ).then((_) {
          _loadDashboardData();
          _checkUserShop();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
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
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'ML',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'MobiLedger',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: () async {
              await _firebaseService.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildBrowseShops();
      case 2:
        return _buildLearn();
      case 3:
        return _buildSettings();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadDashboardData();
        await _checkUserShop();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${_currentUser?.displayName ?? 'User'}!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Here\'s your business summary',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            
            // Stats Cards Row 1
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Active Products',
                    value: '$_activeProducts',
                    icon: Icons.shopping_bag_outlined,
                    color: const Color(0xFF4CAF50),
                    onTap: () {
                      Navigator.pushNamed(context, '/my-products');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: "Today's Inquiries",
                    value: '$_todayInquiries',
                    icon: Icons.message_outlined,
                    color: const Color(0xFF2196F3),
                    onTap: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Stats Cards Row 2
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Monthly Sales',
                    value: '${_monthlySales.toString()} RWF',
                    icon: Icons.trending_up_outlined,
                    color: const Color(0xFFFF9800),
                    onTap: () {
                      Navigator.pushNamed(context, '/sales');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Total Profit',
                    value: '${(_monthlySales * 0.2).round()} RWF',
                    icon: Icons.account_balance_wallet_outlined,
                    color: const Color(0xFF9C27B0),
                    onTap: () {},
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Recent Activity Section
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'View All Activity',
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Recent Activity List
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _recentActivities.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text('No recent activity'),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentActivities.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final activity = _recentActivities[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.shade50,
                            child: const Icon(
                              Icons.shopping_cart_outlined,
                              color: Color(0xFF4CAF50),
                              size: 20,
                            ),
                          ),
                          title: Text(activity['title']),
                          trailing: activity['amount'].isNotEmpty
                              ? Text(
                                  activity['amount'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4CAF50),
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
            ),
            
            const SizedBox(height: 24),
            
            // Quick Actions Section
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Quick Actions Buttons - Dynamic Shop Button
            Row(
              children: [
                Expanded(
                  child: _buildQuickAction(
                    title: _hasShopLoaded ? (_userHasShop ? 'My Shop' : 'Create Shop') : '...',
                    icon: Icons.store,
                    color: const Color(0xFF4CAF50),
                    onTap: _manageShop,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAction(
                    title: 'Add Product',
                    icon: Icons.add_shopping_cart,
                    color: const Color(0xFFFF9800),
                    onTap: () {
                      Navigator.pushNamed(context, '/add-product').then((_) {
                        _loadDashboardData();
                        _checkUserShop();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAction(
                    title: 'Profile',
                    icon: Icons.person,
                    color: const Color(0xFF2196F3),
                    onTap: () {
                      Navigator.pushNamed(context, '/profile');
                    },
                  ),
                ),
              ],
            ),
            
            // Hint text for new users
            if (_hasShopLoaded && !_userHasShop) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Click "Create Shop" to start selling your products!',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
      ),
    );
  }

  Widget _buildQuickAction({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseShops() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Browse Shops',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/browse-shops');
            },
            child: const Text('View All Shops'),
          ),
        ],
      ),
    );
  }

  Widget _buildLearn() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Learn & Grow',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/learn-hub');
            },
            child: const Text('Start Learning'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF4CAF50),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.store_outlined),
          activeIcon: Icon(Icons.store),
          label: 'Browse',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.school_outlined),
          activeIcon: Icon(Icons.school),
          label: 'Learn',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}