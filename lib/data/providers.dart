import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sbeereck_app/data/models.dart';

class ThemeModel extends ChangeNotifier {
  Brightness _mode = Brightness.light;

  Brightness get theme => _mode;

  void switchTheme() {
    if (_mode == Brightness.light) {
      _mode = Brightness.dark;
    } else {
      _mode = Brightness.light;
    }

    notifyListeners();
  }
}

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
  final List<CustomerAccount> _accounts = [];

  List<CustomerAccount> get accounts => _accounts;

  FirestoreDataModel() {
    // Setup accounts stream
    FirebaseFirestore.instance
        .collection('accounts')
        .withConverter<CustomerAccount>(
            fromFirestore: (snapshot, a) {
              assert(snapshot.exists);
              return CustomerAccount.fromJson(snapshot.id, snapshot.data()!);
            },
            toFirestore: (account, a) => account.toJson())
        .snapshots()
        // When accounts are updated
        .listen((QuerySnapshot<CustomerAccount> snapshot) {
      for (var change in snapshot.docChanges) {
        log('Account Change: ${change.type} (${change.oldIndex} -> ${change.newIndex}) [${change.doc.data()}]');

        if (change.oldIndex != -1) {
          _accounts.removeAt(change.oldIndex);
        }
        if (change.newIndex != -1) {
          _accounts.insert(change.newIndex, change.doc.data()!);
        }
      }
      notifyListeners();
    }, onError: (err, stacktrace) {
      log("Firebase error !", error: err, stackTrace: stacktrace);
    });
  }
}
