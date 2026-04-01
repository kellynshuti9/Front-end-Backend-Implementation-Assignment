import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mobiledger_app/core/routes/app_routes.dart';
import 'package:mobiledger_app/core/themes/app_theme.dart';
import 'package:mobiledger_app/presentation/screens/create_shop_screen.dart';

const FirebaseOptions webOptions = FirebaseOptions(
  apiKey: "AIzaSyCQ7GaDHFKCTs8PCVxsqna53n78hqifl-4",
  appId: "1:423673139047:web:e87506344063f0e52629c2",
  messagingSenderId: "423673139047",
  projectId: "mobiledger-6f54f",
  authDomain: "mobiledger-6f54f.firebaseapp.com",
  storageBucket: "mobiledger-6f54f.firebasestorage.app",
  databaseURL: "https://mobiledger-6f54f-default-rtdb.europe-west1.firebasedatabase.app",
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(options: webOptions);
    print('✅ Firebase initialized successfully!');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MobiLedger',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      routes: {
        ...AppRoutes.routes,
        '/create-shop': (context) => const CreateShopScreen(),
      },
    );
  }
}