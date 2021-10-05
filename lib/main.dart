import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/providers.dart';
import 'view/home.dart';
import 'view/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (ctx) => ThemeModel()),
    ChangeNotifierProvider(create: (ctx) => AuthModel()),
    ChangeNotifierProvider(create: (ctx) => FirestoreDataModel()),
  ], child: const FirebaseWaitReadyApp()));
}

class FirebaseWaitReadyApp extends StatefulWidget {
  const FirebaseWaitReadyApp({Key? key}) : super(key: key);

  @override
  _FirebaseWaitReadyAppState createState() => _FirebaseWaitReadyAppState();
}

class _FirebaseWaitReadyAppState extends State<FirebaseWaitReadyApp> {
  final Future<FirebaseApp> _initialisation = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    final theme = context.select((ThemeModel theme) => theme.theme);
    return MaterialApp(
        title: "S'Beer Eck",
        theme: ThemeData(brightness: theme),
        home: FutureBuilder(
          future: _initialisation,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              log('Firebase Error', error: snapshot.error);
              return const Text('An error has occurred');
            }

            if (snapshot.connectionState == ConnectionState.done) {
              return AppReady(key: UniqueKey());
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
