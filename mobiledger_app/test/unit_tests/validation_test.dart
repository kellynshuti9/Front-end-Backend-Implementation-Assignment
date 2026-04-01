// test/unit_tests/validation_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validation Tests', () {
    test('Email validation - valid emails pass', () {
      bool isValidEmail(String email) {
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        return emailRegex.hasMatch(email);
      }
      
      expect(isValidEmail('user@example.com'), true);
      expect(isValidEmail('test@gmail.com'), true);
    });

    test('Email validation - invalid emails fail', () {
      bool isValidEmail(String email) {
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        return emailRegex.hasMatch(email);
      }
      
      expect(isValidEmail('invalid'), false);
      expect(isValidEmail('user@'), false);
    });

    test('Password validation - valid passwords', () {
      bool isValidPassword(String password) {
        return password.length >= 6;
      }
      
      expect(isValidPassword('123456'), true);
      expect(isValidPassword('password123'), true);
    });

    test('Password validation - invalid passwords', () {
      bool isValidPassword(String password) {
        return password.length >= 6;
      }
      
      expect(isValidPassword('12345'), false);
      expect(isValidPassword(''), false);
    });

    test('Password confirmation matches', () {
      bool doPasswordsMatch(String password, String confirmPassword) {
        return password == confirmPassword;
      }
      
      expect(doPasswordsMatch('123456', '123456'), true);
      expect(doPasswordsMatch('123456', '12345'), false);
    });
  });
}