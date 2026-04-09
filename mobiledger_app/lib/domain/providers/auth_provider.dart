import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider with ChangeNotifier {
  final AuthRepository _repo;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;
  bool _emailVerified = false;
  StreamSubscription<User?>? _authSub;

  AuthProvider({required AuthRepository repository}) : _repo = repository {
    _authSub = _repo.authStateChanges.listen(_onAuthChanged);
  }

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuth => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  bool get emailVerified => _emailVerified;

  void _onAuthChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _status = AuthStatus.unauthenticated;
      _user = null;
      notifyListeners();
      return;
    }
    await firebaseUser.reload();
    _emailVerified = firebaseUser.emailVerified;
    try {
      _user = await _repo.getUserProfile(firebaseUser.uid);
      _user ??= UserModel(
        uid: firebaseUser.uid,
        fullName: firebaseUser.displayName ?? '',
        email: firebaseUser.email ?? '',
        photoUrl: firebaseUser.photoURL,
        createdAt: DateTime.now(),
      );
      _status = AuthStatus.authenticated;
    } catch (_) {
      _status = AuthStatus.error;
    }
    notifyListeners();
  }

  // ─── Register ─────────────────────────────────────────────────────────────
  Future<bool> registerWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _setLoading();
    try {
      _user = await _repo.registerWithEmail(
        fullName: fullName,
        email: email,
        password: password,
      );
      _status = AuthStatus.authenticated;
      _emailVerified = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_friendlyError(e.code));
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ─── Login ────────────────────────────────────────────────────────────────
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading();
    try {
      _user = await _repo.signInWithEmail(email: email, password: password);
      _status = AuthStatus.authenticated;
      final fb = _repo.currentFirebaseUser;
      _emailVerified = fb?.emailVerified ?? false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_friendlyError(e.code));
      return false;
    }
  }

  // ─── Google ───────────────────────────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    _setLoading();
    try {
      _user = await _repo.signInWithGoogle();
      _emailVerified = true; // Google accounts are verified
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_friendlyError(e.code));
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // ─── Reset password ───────────────────────────────────────────────────────
  Future<bool> sendPasswordReset(String email) async {
    _setLoading();
    try {
      await _repo.sendPasswordResetEmail(email);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_friendlyError(e.code));
      return false;
    }
  }

  // ─── Sign out ─────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();
      await _repo.signOut();
      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to sign out: ${e.toString()}';
      _status = AuthStatus.error;
      notifyListeners();
    }
  }

  // ─── Update profile ───────────────────────────────────────────────────────
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (_user == null) return false;
    try {
      await _repo.updateProfile(_user!.uid, data);
      _user = await _repo.getUserProfile(_user!.uid);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Follow / unfollow shop ───────────────────────────────────────────────
  Future<void> toggleFollowShop(String shopId, bool follow) async {
    if (_user == null) return;
    await _repo.toggleFollowShop(_user!.uid, shopId, follow);
    _user = await _repo.getUserProfile(_user!.uid);
    notifyListeners();
  }

  bool isFollowing(String shopId) =>
      _user?.followedShopIds.contains(shopId) ?? false;

  // ─── Resend verification ──────────────────────────────────────────────────
  Future<void> resendVerificationEmail() async {
    await _repo.currentFirebaseUser?.sendEmailVerification();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _status = AuthStatus.error;
    _errorMessage = msg;
    notifyListeners();
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
