// lib/services/firebase_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(fullName);
      await _database.child('users').child(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'fullName': fullName,
        'email': email,
        'createdAt': ServerValue.timestamp,
        'role': 'user',
        'shopName': '',
        'phone': '',
        'location': 'Kigali, Rwanda',
      });
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      final snapshot = await _database.child('users').child(userCredential.user!.uid).get();
      if (!snapshot.exists) {
        await _database.child('users').child(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'fullName': userCredential.user!.displayName ?? '',
          'email': userCredential.user!.email,
          'createdAt': ServerValue.timestamp,
          'role': 'user',
          'shopName': '',
          'phone': '',
          'location': 'Kigali, Rwanda',
        });
      }
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  Future<void> resetPassword({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  String _handleAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak (minimum 6 characters)';
      case 'user-not-found':
        return 'User not found';
      case 'wrong-password':
        return 'Wrong password';
      default:
        return error.message ?? 'Authentication failed';
    }
  }

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    final snapshot = await _database.child('users').child(userId).get();
    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return null;
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _database.child('users').child(userId).update(data);
  }

  Future<List<Map<String, dynamic>>> getProducts({String? sellerId}) async {
    Query query = _database.child('products');
    if (sellerId != null) {
      query = query.orderByChild('sellerId').equalTo(sellerId);
    }
    final snapshot = await query.get();
    final List<Map<String, dynamic>> products = [];
    if (snapshot.exists) {
      for (var child in snapshot.children) {
        final data = Map<String, dynamic>.from(child.value as Map);
        data['id'] = child.key;
        products.add(data);
      }
    }
    return products;
  }

  Future<Map<String, dynamic>?> getProduct(String productId) async {
    final snapshot = await _database.child('products').child(productId).get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      data['id'] = snapshot.key;
      return data;
    }
    return null;
  }

  Future<String> addProduct(Map<String, dynamic> productData) async {
    final productRef = _database.child('products').push();
    final productId = productRef.key!;
    final newProduct = {
      'id': productId,
      ...productData,
      'createdAt': ServerValue.timestamp,
      'updatedAt': ServerValue.timestamp,
    };
    await productRef.set(newProduct);
    return productId;
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    data['updatedAt'] = ServerValue.timestamp;
    await _database.child('products').child(productId).update(data);
  }

  Future<void> deleteProduct(String productId) async {
    await _database.child('products').child(productId).remove();
  }

  Future<Map<String, dynamic>> getCart(String userId) async {
    final snapshot = await _database.child('carts').child(userId).get();
    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return {'items': {}, 'subtotal': 0};
  }

  Future<void> addToCart(String userId, Map<String, dynamic> product) async {
    final cartRef = _database.child('carts').child(userId);
    final itemsRef = cartRef.child('items').child(product['id']);
    final snapshot = await itemsRef.get();
    
    int currentQuantity = 0;
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      currentQuantity = (data['quantity'] as num?)?.toInt() ?? 0;
    }
    
    final int productQuantity = (product['quantity'] as num?)?.toInt() ?? 1;
    final int newQuantity = currentQuantity + productQuantity;
    
    await itemsRef.set({
      'productId': product['id'],
      'productName': product['productName'],
      'price': (product['price'] as num?)?.toInt() ?? 0,
      'quantity': newQuantity,
      'image': product['image'] ?? '',
    });
    
    await _updateCartSubtotal(userId);
  }

  Future<void> removeFromCart(String userId, String productId) async {
    await _database.child('carts').child(userId).child('items').child(productId).remove();
    await _updateCartSubtotal(userId);
  }

  Future<void> updateCartQuantity(String userId, String productId, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(userId, productId);
    } else {
      await _database
          .child('carts')
          .child(userId)
          .child('items')
          .child(productId)
          .update({'quantity': quantity});
      await _updateCartSubtotal(userId);
    }
  }

  Future<void> _updateCartSubtotal(String userId) async {
    final itemsSnapshot = await _database.child('carts').child(userId).child('items').get();
    int subtotal = 0;
    if (itemsSnapshot.exists) {
      final items = itemsSnapshot.value as Map;
      items.forEach((key, value) {
        final item = value as Map;
        final price = (item['price'] as num?)?.toInt() ?? 0;
        final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
        subtotal += price * quantity;
      });
    }
    await _database.child('carts').child(userId).update({
      'subtotal': subtotal,
      'updatedAt': ServerValue.timestamp,
    });
  }

  Future<void> clearCart(String userId) async {
    await _database.child('carts').child(userId).remove();
  }

  Future<String> createTransaction(Map<String, dynamic> transactionData) async {
    final transactionRef = _database.child('transactions').push();
    final transactionId = transactionRef.key!;
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final orderNumber = 'MOB-${random.substring(random.length - 8)}';
    final newTransaction = {
      'id': transactionId,
      'orderNumber': orderNumber,
      ...transactionData,
      'status': 'pending',
      'createdAt': ServerValue.timestamp,
    };
    await transactionRef.set(newTransaction);
    return transactionId;
  }

  Future<List<Map<String, dynamic>>> getSellerTransactions(String sellerId) async {
    final snapshot = await _database
        .child('transactions')
        .orderByChild('sellerId')
        .equalTo(sellerId)
        .get();
    final List<Map<String, dynamic>> transactions = [];
    if (snapshot.exists) {
      for (var child in snapshot.children) {
        final data = Map<String, dynamic>.from(child.value as Map);
        data['id'] = child.key;
        transactions.add(data);
      }
    }
    return transactions;
  }

  Future<Map<String, dynamic>> getSalesSummary(String sellerId) async {
    final transactions = await getSellerTransactions(sellerId);
    int totalSales = 0;
    int totalTransactions = 0;
    for (var transaction in transactions) {
      if (transaction['status'] == 'completed') {
        final total = (transaction['total'] as num?)?.toInt() ?? 0;
        totalSales += total;
        totalTransactions++;
      }
    }
    return {
      'totalSales': totalSales,
      'totalTransactions': totalTransactions,
      'averageSale': totalTransactions > 0 ? totalSales ~/ totalTransactions : 0,
    };
  }

  Future<String> addCredit(Map<String, dynamic> creditData) async {
    final creditRef = _database.child('credits').push();
    final creditId = creditRef.key!;
    final newCredit = {
      'id': creditId,
      ...creditData,
      'status': 'active',
      'createdAt': ServerValue.timestamp,
    };
    await creditRef.set(newCredit);
    return creditId;
  }

  Future<List<Map<String, dynamic>>> getCredits(String sellerId) async {
    final snapshot = await _database
        .child('credits')
        .orderByChild('sellerId')
        .equalTo(sellerId)
        .get();
    final List<Map<String, dynamic>> credits = [];
    if (snapshot.exists) {
      for (var child in snapshot.children) {
        final data = Map<String, dynamic>.from(child.value as Map);
        data['id'] = child.key;
        credits.add(data);
      }
    }
    return credits;
  }

  Future<void> markCreditAsPaid(String creditId) async {
    await _database.child('credits').child(creditId).update({
      'status': 'paid',
      'paidDate': ServerValue.timestamp,
    });
  }
}