import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'login.dart';
import 'model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (ctx) => AuthModel()),
  ], child: const SbeereckApp()));
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
            if (snapshot.hasError) {
              log('Firebase Error', error: snapshot.error);
              return const Text('An error has occurred');
            }

            if (snapshot.connectionState == ConnectionState.done) {
              return const AppReady();
            }

            return const Center(child: CircularProgressIndicator());
          },
        ));
  }
}

class AppReady extends StatefulWidget {
  const AppReady({Key? key}) : super(key: key);

  @override
  _AppReadyState createState() => _AppReadyState();
}

class _AppReadyState extends State<AppReady> {
  @override
  void initState() {
    // Can be called safely a number of times
    // TODO: Completely broken
    // Provider.of<AuthModel>(context, listen: false).initFirebaseAuth();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthModel>(
      builder: (ctx, auth, child) {
        return Navigator(
        pages: [
          if (auth.user == null)
            const MaterialPage(key: ValueKey('login'), child: LoginPage()),
          if (auth.user != null)
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
