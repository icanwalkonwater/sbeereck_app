import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'login.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SbeereckApp());
}

class SbeereckApp extends StatefulWidget {
  const SbeereckApp({Key? key}) : super(key: key);

  @override
  _SbeereckAppState createState() => _SbeereckAppState();
}

class _SbeereckAppState extends State<SbeereckApp> {
  final Future<FirebaseApp> _initialisation = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "S'Beer Eck",
        theme: ThemeData(brightness: Brightness.dark),
        home: FutureBuilder(
          future: _initialisation,
          builder: (context, snapshot) {
            log('Bwa');
            if (snapshot.hasError) {
              log('Error', error: snapshot.error);
              return const Text('An error has occurred');
            }

            if (snapshot.connectionState == ConnectionState.done) {
              return AppReady(firebaseApp: snapshot.requireData as FirebaseApp);
            }

            return const Center(child: CircularProgressIndicator());
          },
        ));
  }
}

class AppReady extends StatefulWidget {
  final FirebaseApp firebaseApp;
  late final FirebaseAuth firebaseAuth;

  AppReady({Key? key, required this.firebaseApp}) : super(key: key) {
    firebaseAuth = FirebaseAuth.instanceFor(app: firebaseApp);
  }

  @override
  _AppReadyState createState() => _AppReadyState();
}

class _AppReadyState extends State<AppReady> {
  User? _user;

  @override
  Widget build(BuildContext context) {
    return Navigator(
      pages: [
        if (_user == null)
          const MaterialPage(key: ValueKey('login'), child: LoginPage()),
        if (_user != null)
          const MaterialPage(
            key: ValueKey('home'),
            child: HomePage(),
          )
      ],
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }

        return true;
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(child: Text("Hey")),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_rounded), label: 'Comptes'),
          BottomNavigationBarItem(icon: Icon(Icons.anchor), label: 'Bières')
        ],
      ),
    );
  }
}
