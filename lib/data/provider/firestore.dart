import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models.dart';

class FirestoreDataModel extends ChangeNotifier {
  final List<CustomerAccount> _accounts = [];

  List<CustomerAccount> get accounts => _accounts;

  // Setup snapshot listening
  // <editor-fold>

  FirestoreDataModel() {
    // Setup accounts stream
    FirebaseFirestore.instance
        .collection('accounts')
        .withConverter<CustomerAccount>(
            fromFirestore: (snapshot, a) => CustomerAccount.fromJson(snapshot.id, snapshot.data()!),
            toFirestore: (account, a) => account.toJson())
        .snapshots()
        .listen(handleChangesFactory<CustomerAccount>(_accounts),
            onError: logError);
  }

  void logError(dynamic err, dynamic stacktrace) =>
      log("Firebase error !", error: err, stackTrace: stacktrace);

  void Function(QuerySnapshot<T>) handleChangesFactory<T>(List<T> dest) {
    return (snapshot) {
      for (final change in snapshot.docChanges) {
        log('New change: ${change.type.toString()}');

        if (change.oldIndex != -1) {
          dest.removeAt(change.oldIndex);
        }
        if (change.newIndex != -1) {
          dest.insert(change.newIndex, change.doc.data()!);
        }
      }
      notifyListeners();
    };
  }

// </editor-fold>

  Future<void> newAccount(NewAccount account) async {
    await FirebaseFirestore.instance.collection('accounts').add(account.toJson());
  }
}
