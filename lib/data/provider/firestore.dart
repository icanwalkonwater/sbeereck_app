import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models.dart';

const _accountsCol = 'accounts';

class FirestoreDataModel extends ChangeNotifier {
  final List<CustomerAccount> _accounts = [];
  final List<BeerType> _beerTypes = [];
  final List<Beer> _beers = [];

  List<CustomerAccount> get accounts => _accounts;

  List<BeerType> get beerTypes => _beerTypes;

  List<Beer> get beers => _beers;

  // Setup snapshot listening
  // <editor-fold>

  FirestoreDataModel() {
    // Setup accounts stream
    FirebaseFirestore.instance
        .collection(_accountsCol)
        .withConverter<CustomerAccount>(
            fromFirestore: (snapshot, _) =>
                CustomerAccount.fromJson(snapshot.id, snapshot.data()!),
            toFirestore: (account, _) => account.toJson())
        .snapshots()
        .listen(handleChangesFactory<CustomerAccount>(_accounts),
            onError: logError);

    // Get beer types just one time
    FirebaseFirestore.instance
        .collection('beerTypes')
        .withConverter<BeerType>(
            fromFirestore: (s, _) => BeerType.fromJson(s.id, s.data()!),
            toFirestore: (t, _) => {})
        .get()
        .then((snapshot) =>
            _beerTypes.addAll(snapshot.docs.map((doc) => doc.data())));

    // Setup beer stream
    FirebaseFirestore.instance
        .collection('beers')
        .withConverter<Beer>(
            fromFirestore: (s, _) => Beer.fromJson(s.id, s.data()!),
            toFirestore: (b, _) => b.toJson())
        .snapshots()
        .listen(handleChangesFactory<Beer>(_beers), onError: logError);
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

  CustomerAccount accountById(String id) {
    return _accounts.firstWhere((acc) => acc.id == id,
        orElse: () => CustomerAccount.dummy);
  }

  Future<void> newAccount(NewCustomerAccount account) async {
    await FirebaseFirestore.instance
        .collection(_accountsCol)
        .add(account.toJsonFull());
  }

  Future<void> editAccount(String id, NewCustomerAccount account) async {
    await FirebaseFirestore.instance
        .collection(_accountsCol)
        .doc(id)
        .update(account.toJsonLight());
  }

  Future<void> makeAccountMember(String id) async {
    await FirebaseFirestore.instance
        .collection(_accountsCol)
        .doc(id)
        .update({'isMember': true});
  }

  Future<void> rechargeAccount(String id, int newBalance) async {
    await FirebaseFirestore.instance
        .collection(_accountsCol)
        .doc(id)
        .update({'balance': newBalance});
  }

  Future<void> deleteAccount(String id) async {
    await FirebaseFirestore.instance.collection(_accountsCol).doc(id).delete();
  }
}
