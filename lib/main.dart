import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: FirebaseTestPage(),
    );
  }
}

class FirebaseTestPage extends StatelessWidget {
  const FirebaseTestPage({super.key});

  Future<void> testFirestore() async {
    await FirebaseFirestore.instance
        .collection('test')
        .doc('connection')
        .set({
      'message': 'Firebase bağlantısı başarılı 🎉',
      'time': DateTime.now().toString(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Test'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              await testFirestore();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Firestore’a veri yazıldı ✅'),
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Hata ❌: $e'),
                ),
              );
            }
          },
          child: const Text('Firebase Test Et'),
        ),
      ),
    );
  }
}