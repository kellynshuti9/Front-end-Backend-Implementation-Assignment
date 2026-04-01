import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mobiledger_app/services/firebase_service.dart';

class CreateShopScreen extends StatefulWidget {
  final Map<String, dynamic>? existingShop;
  const CreateShopScreen({super.key, this.existingShop});

  @override
  State<CreateShopScreen> createState() => _CreateShopScreenState();
}

class _CreateShopScreenState extends State<CreateShopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _hoursController = TextEditingController();
  final _aboutController = TextEditingController();
  
  bool _isLoading = false;
  bool _isEditing = false;
  
  final FirebaseService _firebaseService = FirebaseService();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    if (widget.existingShop != null) {
      _isEditing = true;
      _nameController.text = widget.existingShop!['name'] ?? '';
      _locationController.text = widget.existingShop!['location'] ?? '';
      _phoneController.text = widget.existingShop!['phone'] ?? '';
      _emailController.text = widget.existingShop!['email'] ?? '';
      _hoursController.text = widget.existingShop!['hours'] ?? '9AM-6PM';
      _aboutController.text = widget.existingShop!['about'] ?? '';
    }
  }

  Future<void> _saveShop() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final userId = _firebaseService.currentUser?.uid;
      final userName = _firebaseService.currentUser?.displayName ?? 'Seller';
      final userEmail = _firebaseService.currentUser?.email ?? '';
      
      final shopData = {
        'name': _nameController.text,
        'location': _locationController.text,
        'ownerId': userId,
        'ownerName': userName,
        'rating': 5.0,
        'reviews': 0,
        'products': 0,
        'initials': _nameController.text.substring(0, 2).toUpperCase(),
        'hours': _hoursController.text,
        'about': _aboutController.text,
        'phone': _phoneController.text,
        'email': _emailController.text.isEmpty ? userEmail : _emailController.text,
        'updatedAt': ServerValue.timestamp,
      };
      
      if (_isEditing && widget.existingShop != null) {
        await _database.child('shops').child(widget.existingShop!['id']).update(shopData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop updated successfully!'), backgroundColor: Colors.green),
        );
      } else {
        shopData['createdAt'] = ServerValue.timestamp;
        await _database.child('shops').push().set(shopData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop created successfully!'), backgroundColor: Colors.green),
        );
      }
      
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteShop() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shop'),
        content: const Text('Are you sure you want to delete your shop? All products will also be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    
    if (confirm == true && widget.existingShop != null) {
      setState(() => _isLoading = true);
      try {
        final productsSnapshot = await _database
            .child('products')
            .orderByChild('shopId')
            .equalTo(widget.existingShop!['id'])
            .get();
        
        if (productsSnapshot.exists) {
          for (var child in productsSnapshot.children) {
            await _database.child('products').child(child.key!).remove();
          }
        }
        
        await _database.child('shops').child(widget.existingShop!['id']).remove();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop deleted successfully!'), backgroundColor: Colors.green),
        );
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Shop' : 'Create Shop',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: _isEditing
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _deleteShop,
                ),
              ]
            : null,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildTextField(_nameController, 'Shop Name', 'Enter shop name', Icons.store),
              const SizedBox(height: 16),
              _buildTextField(_locationController, 'Location', 'Kigali, Rwanda', Icons.location_on),
              const SizedBox(height: 16),
              _buildTextField(_phoneController, 'Phone Number', '+250 788 123 456', Icons.phone, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildTextField(_emailController, 'Email', 'shop@example.com', Icons.email, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildTextField(_hoursController, 'Business Hours', '9AM-6PM (Mon-Sat)', Icons.access_time),
              const SizedBox(height: 16),
              _buildTextField(_aboutController, 'About', 'Describe your shop...', Icons.info, maxLines: 3),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveShop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                      : Text(_isEditing ? 'UPDATE SHOP' : 'CREATE SHOP', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, IconData icon,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF4CAF50)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
        ),
      ),
      validator: (value) {
        if (label == 'Shop Name' && (value == null || value.isEmpty)) {
          return 'Please enter shop name';
        }
        return null;
      },
    );
  }
}