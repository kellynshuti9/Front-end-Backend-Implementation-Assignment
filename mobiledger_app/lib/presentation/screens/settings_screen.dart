import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';  
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _autoSync = true;
  bool _notifications = true;
  bool _dataSaver = false;
  String _selectedLanguage = 'English';
  String _selectedCurrency = 'RWF';
  
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isBackingUp = false;
  bool _isExporting = false;
  
  final List<String> _languages = ['English', 'Kinyarwanda', 'French'];
  final List<String> _currencies = ['RWF', 'USD', 'EUR'];
  
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadUserData();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _autoSync = prefs.getBool('auto_sync') ?? true;
      _notifications = prefs.getBool('notifications') ?? true;
      _dataSaver = prefs.getBool('data_saver') ?? false;
      _selectedLanguage = prefs.getString('language') ?? 'English';
      _selectedCurrency = prefs.getString('currency') ?? 'RWF';
    });
  }

  Future<void> _loadUserData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final snapshot = await _database.child('users').child(userId).get();
      if (snapshot.exists) {
        setState(() {
          _userData = Map<String, dynamic>.from(snapshot.value as Map);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  Future<void> _backupToCloud() async {
    setState(() => _isBackingUp = true);
    
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');
      
      final userSnapshot = await _database.child('users').child(userId).get();
      final productsSnapshot = await _database
          .child('products')
          .orderByChild('sellerId')
          .equalTo(userId)
          .get();
      final transactionsSnapshot = await _database
          .child('transactions')
          .orderByChild('buyerId')
          .equalTo(userId)
          .get();
      
      final backupData = {
        'userData': userSnapshot.value,
        'products': productsSnapshot.value,
        'transactions': transactionsSnapshot.value,
        'backupDate': ServerValue.timestamp,
      };
      
      await _database.child('backups').child(userId).push().set(backupData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBackingUp = false);
      }
    }
  }

  Future<void> _exportSalesReport() async {
    setState(() => _isExporting = true);
    
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');
      
      final transactions = await _database
          .child('transactions')
          .orderByChild('sellerId')
          .equalTo(userId)
          .get();
      
      String csvData = "Order Number,Date,Total,Status\n";
      if (transactions.exists) {
        for (var child in transactions.children) {
          final data = child.value as Map;
          final date = DateTime.fromMillisecondsSinceEpoch(
            data['createdAt'] as int? ?? 0
          );
          csvData += "${data['orderNumber']},"
              "${date.day}/${date.month}/${date.year},"
              "${data['total']},"
              "${data['status']}\n";
        }
      }
      
      print('Export data: $csvData');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sales report exported! Check console for data.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _loadPreferences();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache cleared successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear cache: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Center(
          child: Text(
            'About MobiLedger',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  'ML',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'MobiLedger',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'Track. Learn. Grow in Your Language.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              '© 2026 MobiLedger. All rights reserved.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Us'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('We\'re here to help!'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.email, color: Color(0xFF4CAF50)),
              title: const Text('Email'),
              subtitle: const Text('support@mobiledger.com'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: Color(0xFF4CAF50)),
              title: const Text('Phone'),
              subtitle: const Text('+250 788 123 456'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.web, color: Color(0xFF4CAF50)),
              title: const Text('Website'),
              subtitle: const Text('www.mobiledger.com'),
              onTap: () {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & FAQ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Frequently Asked Questions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text('• How to add products?'),
              const SizedBox(height: 4),
              const Text('  Go to Dashboard → Add Product → Fill details → Save'),
              const SizedBox(height: 8),
              const Text('• How to track sales?'),
              const SizedBox(height: 4),
              const Text('  Go to Dashboard → View Sales → See your sales data'),
              const SizedBox(height: 8),
              const Text('• How to manage credit?'),
              const SizedBox(height: 4),
              const Text('  Go to Credit Tracker → Add credit → Manage payments'),
              const SizedBox(height: 8),
              const Text('• How to edit profile?'),
              const SizedBox(height: 4),
              const Text('  Go to Profile → Edit Profile → Save changes'),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Need more help? Contact our support team!',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Settings',
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
          : SingleChildScrollView(
              child: Column(
                children: [
                  // My Profile Section
                  _buildSectionHeader('My Profile'),
                  Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.store, color: Color(0xFF4CAF50)),
                          title: const Text('Shop Name'),
                          trailing: Text(
                            _userData?['shopName']?.isNotEmpty == true
                                ? _userData!['shopName']
                                : 'Mama Toto Shop',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          onTap: () {},
                        ),
                        ListTile(
                          leading: const Icon(Icons.person, color: Color(0xFF4CAF50)),
                          title: const Text('Owner'),
                          trailing: Text(
                            _userData?['fullName'] ?? 
                            FirebaseAuth.instance.currentUser?.displayName ?? 
                            'User',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          onTap: () {},
                        ),
                        ListTile(
                          leading: const Icon(Icons.location_on, color: Color(0xFF4CAF50)),
                          title: const Text('Location'),
                          trailing: Text(
                            _userData?['location']?.isNotEmpty == true
                                ? _userData!['location']
                                : 'Kigali, Rwanda',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          onTap: () {},
                        ),
                        ListTile(
                          leading: const Icon(Icons.edit, color: Color(0xFF4CAF50)),
                          title: const Text('Edit Profile'),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          onTap: () {
                            Navigator.pushNamed(context, '/edit-profile');
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // App Preferences Section
                  _buildSectionHeader('App Preferences'),
                  Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        _buildPreferenceDropdown(
                          title: 'App Language',
                          value: _selectedLanguage,
                          items: _languages,
                          onChanged: (value) async {
                            setState(() => _selectedLanguage = value!);
                            await _savePreference('language', value);
                          },
                        ),
                        _buildPreferenceDropdown(
                          title: 'Currency',
                          value: _selectedCurrency,
                          items: _currencies,
                          onChanged: (value) async {
                            setState(() => _selectedCurrency = value!);
                            await _savePreference('currency', value);
                          },
                        ),
                        _buildPreferenceSwitch(
                          title: 'Dark Mode',
                          value: _darkMode,
                          onChanged: (value) async {
                            setState(() => _darkMode = value);
                            await _savePreference('dark_mode', value);
                          },
                        ),
                        _buildPreferenceSwitch(
                          title: 'Auto Sync',
                          value: _autoSync,
                          onChanged: (value) async {
                            setState(() => _autoSync = value);
                            await _savePreference('auto_sync', value);
                          },
                        ),
                        _buildPreferenceSwitch(
                          title: 'Notifications',
                          value: _notifications,
                          onChanged: (value) async {
                            setState(() => _notifications = value);
                            await _savePreference('notifications', value);
                          },
                        ),
                        _buildPreferenceSwitch(
                          title: 'Data Saver',
                          value: _dataSaver,
                          onChanged: (value) async {
                            setState(() => _dataSaver = value);
                            await _savePreference('data_saver', value);
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Data & Backup Section
                  _buildSectionHeader('Data & Backup'),
                  Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.cloud_upload_outlined,
                          title: 'Backup to Cloud',
                          onTap: _backupToCloud,
                          isLoading: _isBackingUp,
                        ),
                        _buildMenuItem(
                          icon: Icons.file_download_outlined,
                          title: 'Export Sales Report',
                          onTap: _exportSalesReport,
                          isLoading: _isExporting,
                        ),
                        _buildMenuItem(
                          icon: Icons.delete_outline,
                          title: 'Clear App Cache',
                          onTap: _clearCache,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Support Section
                  _buildSectionHeader('Support'),
                  Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.help_outline,
                          title: 'Help & FAQ',
                          onTap: _showHelpDialog,
                        ),
                        _buildMenuItem(
                          icon: Icons.email_outlined,
                          title: 'Contact Us',
                          onTap: _showContactDialog,
                        ),
                        _buildMenuItem(
                          icon: Icons.info_outline,
                          title: 'About MobiLedger',
                          onTap: _showAboutDialog,
                        ),
                        const ListTile(
                          leading: Icon(Icons.info_outline, color: Colors.grey),
                          title: Text('Version'),
                          trailing: Text('1.0.0'),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Log Out Button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _showLogoutDialog,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Log Out',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildPreferenceSwitch({
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF4CAF50),
    );
  }

  Widget _buildPreferenceDropdown({
    required String title,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return ListTile(
      title: Text(title),
      trailing: DropdownButton<String>(
        value: value,
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF4CAF50)),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700),
      title: Text(title),
      trailing: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: isLoading ? null : onTap,
    );
  }
}