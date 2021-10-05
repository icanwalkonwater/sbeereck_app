import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthModel extends ChangeNotifier {
  AuthModel() {
    // initFirebaseAuth();
    FirebaseAuth.instance.authStateChanges().listen((user) => this.user = user);
  }

  // Currently logged in user
  User? _user;

  User? get user => _user;
  set user(User? value) {
    _user = value;
    notifyListeners();
  }
}

class FirestoreDataModel extends ChangeNotifier {
  
}

