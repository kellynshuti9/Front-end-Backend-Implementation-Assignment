class Validators {
  Validators._();

  static String? required(String? v, [String field = 'This field']) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final re = RegExp(r'^[\w._%+\-]+@[\w.\-]+\.[a-zA-Z]{2,}$');
    if (!re.hasMatch(v.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? confirmPassword(String? v, String original) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != original) return 'Passwords do not match';
    return null;
  }

  static String? price(String? v) {
    if (v == null || v.trim().isEmpty) return 'Price is required';
    final n = double.tryParse(v);
    if (n == null || n <= 0) return 'Enter a valid price greater than 0';
    return null;
  }

  static String? quantity(String? v) {
    if (v == null || v.trim().isEmpty) return 'Quantity is required';
    final n = int.tryParse(v);
    if (n == null || n < 0) return 'Enter a valid non-negative quantity';
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone number is required';
    final re = RegExp(r'^\+?[0-9]{10,14}$');
    if (!re.hasMatch(v.replaceAll(' ', ''))) {
      return 'Enter a valid phone number';
    }
    return null;
  }
}
