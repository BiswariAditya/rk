import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rk_adv/providers/invoice_provider.dart';
import 'package:rk_adv/providers/purchase_provider.dart';
import 'package:rk_adv/screens/nav_bar.dart';

void main() async {
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: "AIzaSyB2YZHZwvthIYmp7ryQyFZabSipghaCkhc",
            authDomain: "rkbillsoft.firebaseapp.com",
            projectId: "rkbillsoft",
            storageBucket: "rkbillsoft.firebasestorage.app",
            messagingSenderId: "123295930773",
            appId: "1:123295930773:web:731b098f502063baa5be9c",
            measurementId: "G-JTH0J28GRR"
        ),
      );
    } else {
      // Mobile initialization (if you add mobile later)
      await Firebase.initializeApp();
    }
    print('✅ Firebase initialized successfully');
  } catch (e,st) {
    print('Firebase initialization error: $e\n$st');
    runApp(MaterialApp(home: Scaffold(body: Center(child: Text('Firebase init failed: $e')))));
    return;
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => InvoiceProvider()),
        ChangeNotifierProvider(create: (context) => PurchaseProvider()),
      ],
      child: MaterialApp(
        title: 'RK billing System',
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const NavBar(),
      ),
    );
  }
}
