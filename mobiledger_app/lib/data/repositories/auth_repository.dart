import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final GoogleSignIn _google;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? db,
    GoogleSignIn? google,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance,
        _google = google ?? GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentFirebaseUser => _auth.currentUser;

  // ─── Register with email/password ─────────────────────────────────────────
  Future<UserModel> registerWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    // Send email verification
    await cred.user!.sendEmailVerification();
    await cred.user!.updateDisplayName(fullName.trim());

    final user = UserModel(
      uid: cred.user!.uid,
      fullName: fullName.trim(),
      email: email.trim(),
      createdAt: DateTime.now(),
    );
    await _saveUserProfile(user);
    // Create a shop doc for the new user
    await _createDefaultShop(user);
    return user;
  }

  // ─── Sign in with email/password ──────────────────────────────────────────
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _getOrCreateProfile(cred.user!);
  }

  // ─── Google Sign-In ───────────────────────────────────────────────────────
  Future<UserModel> signInWithGoogle() async {
    final googleUser = await _google.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final cred = await _auth.signInWithCredential(credential);
    return _getOrCreateProfile(cred.user!);
  }

  // ─── Password reset ───────────────────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  // ─── Sign out ─────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _google.signOut();
    await _auth.signOut();
  }

  // ─── Profile ──────────────────────────────────────────────────────────────
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, uid);
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
    // If shopName changed, update the shop doc too
    if (data.containsKey('shopName')) {
      final snap = await _db
          .collection('shops')
          .where('ownerId', isEqualTo: uid)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        await snap.docs.first.reference.update({'name': data['shopName']});
      }
    }
  }

  // ─── Follow / Unfollow shop ───────────────────────────────────────────────
  Future<void> toggleFollowShop(String uid, String shopId, bool follow) async {
    final ref = _db.collection('users').doc(uid);
    if (follow) {
      await ref.update({
        'followedShopIds': FieldValue.arrayUnion([shopId]),
      });
      await _db.collection('shops').doc(shopId).update({
        'followerCount': FieldValue.increment(1),
      });
    } else {
      await ref.update({
        'followedShopIds': FieldValue.arrayRemove([shopId]),
      });
      await _db.collection('shops').doc(shopId).update({
        'followerCount': FieldValue.increment(-1),
      });
    }
  }

  // ─── Internal helpers ─────────────────────────────────────────────────────
  Future<UserModel> _getOrCreateProfile(User firebaseUser) async {
    final existing = await getUserProfile(firebaseUser.uid);
    if (existing != null) return existing;

    final user = UserModel(
      uid: firebaseUser.uid,
      fullName: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
      photoUrl: firebaseUser.photoURL,
      createdAt: DateTime.now(),
    );
    await _saveUserProfile(user);
    await _createDefaultShop(user);
    return user;
  }

  Future<void> _saveUserProfile(UserModel user) =>
      _db.collection('users').doc(user.uid).set(user.toMap());

  Future<void> _createDefaultShop(UserModel user) async {
    final shopName =
        user.shopName.isNotEmpty ? user.shopName : "${user.fullName}'s Shop";
    await _db.collection('shops').doc(user.uid).set({
      'ownerId': user.uid,
      'name': shopName,
      'location': user.location.isNotEmpty ? user.location : 'Kigali, Rwanda',
      'about': 'Welcome to $shopName',
      'rating': 0.0,
      'reviewCount': 0,
      'productCount': 0,
      'imageUrl': null,
      'phone': user.phoneNumber,
      'topProducts': [],
      'category': 'General',
      'followerCount': 0,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}
