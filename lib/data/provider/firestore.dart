import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models.dart';

export 'firestore/actions.dart';

const optionFromCache = GetOptions(source: Source.cache);

class FirestoreDataModel extends ChangeNotifier {
  static const accountsCol = 'accounts';
  static const beerTypesCol = 'beerTypes';
  static const beersCol = 'beers';
  static const eventsCol = 'events';
  static const transactionsCol = 'transactions';
  static const staffsCol = 'staffs';

  bool _hasBeenInit = false;

  final List<CustomerAccount> _accounts = [];
  final List<BeerType> _beerTypes = [];
  final List<Beer> _beers = [];
  final List<EventTransaction> _transactions = [];
  final List<Staff> _staffs = [];

  late Staff _currentStaff;
  late final EventPeriod _currentEvent;
  StreamSubscription<QuerySnapshot<EventTransaction>>? _transactionStream;

  List<CustomerAccount> get accounts => _accounts;

  List<BeerType> get beerTypes => _beerTypes;

  List<Beer> get beers => _beers;

  Staff get currentStaff => _currentStaff;

  bool get isAdmin => _currentStaff.isAdmin;

  EventPeriod get currentEvent => _currentEvent;

  // Setup snapshot listening
  FirestoreDataModel() {
    // Listen for current staff
    FirebaseAuth.instance.userChanges().listen((user) async {
      if (user == null) return;

      _currentStaff = (await FirebaseFirestore.instance
              .collection(staffsCol)
              .where('mail', isEqualTo: user.email)
              .limit(1)
              .withStaffConverter()
              .get())
          .docs
          .first
          .data();
      notifyListeners();

      if (!_hasBeenInit) {
        _initListenersAndAll();
      }
    });
  }

  Future<void> _initListenersAndAll() async {
    log('Firebase INIT !');
    if (_hasBeenInit) {
      return;
    }
    _hasBeenInit = true;
    // Setup accounts stream
    FirebaseFirestore.instance
        .collection(accountsCol)
        .orderBy('lastName')
        .orderBy('firstName')
        .withCustomerAccountConverter()
        .snapshots()
        .listen(handleChangesFactory<CustomerAccount>(_accounts),
            onError: logError);

    // Get beer types just one time
    final beerTypeSnapshot = await FirebaseFirestore.instance
        .collection(beerTypesCol)
        .withBeerTypeConverter()
        .get();
    _beerTypes.addAll(beerTypeSnapshot.docs.map((doc) => doc.data()));

    // Setup beer stream
    FirebaseFirestore.instance
        .collection(beersCol)
        .orderBy('type')
        .orderBy('name')
        .withBeerConverter()
        .snapshots()
        .listen(handleChangesFactory<Beer>(_beers), onError: logError);

    // Get all staffs
    FirebaseFirestore.instance
        .collection(staffsCol)
        .orderBy('name')
        .withStaffConverter()
        .snapshots()
        .listen(handleChangesFactory<Staff>(_staffs), onError: logError);

    // Setup event & transactions
    FirebaseFirestore.instance
        .collection(eventsCol)
        .orderBy('created', descending: true)
        .limit(1)
        .withEventPeriodConverter()
        .snapshots()
        .listen((snapshot) async {
      assert(snapshot.size == 1);
      log('New event period started');
      _currentEvent = snapshot.docs.first.data();

      // Setup transaction stream
      if (_transactionStream != null) {
        await _transactionStream!.cancel();
      }

      _transactionStream = FirebaseFirestore.instance
          .collection('$eventsCol/${_currentEvent.id}/$transactionsCol')
          .orderBy('createdAt', descending: true)
          .withEventTransactionConverter()
          .snapshots()
          .listen(handleChangesFactory(_transactions));
    }, onError: logError);

    notifyListeners();
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
}
