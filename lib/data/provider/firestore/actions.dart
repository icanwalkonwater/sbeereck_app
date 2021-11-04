import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models.dart';
import '../../providers.dart';

/// Extension to contain actions possible with accounts
extension FirestoreCustomers on FirestoreDataModel {
  CustomerAccount accountById(String id) {
    return accounts.firstWhere((acc) => acc.id == id,
        orElse: () => CustomerAccount.dummy);
  }

  Future<String> newAccount(NewCustomerAccount account) async {
    return (await FirebaseFirestore.instance
            .collection(FirestoreDataModel.accountsCol)
            .add(account.toJsonFull()))
        .id;
  }

  Future<void> editAccount(String id, NewCustomerAccount account) async {
    await FirebaseFirestore.instance
        .collection(FirestoreDataModel.accountsCol)
        .doc(id)
        .update(account.toJsonLight());
  }

  Future<void> makeAccountMember(String id) async {
    await FirebaseFirestore.instance
        .collection(FirestoreDataModel.accountsCol)
        .doc(id)
        .update({'isMember': true});
  }

  Future<void> setAccountBalance(String id, int newBalance) async {
    await FirebaseFirestore.instance
        .collection(FirestoreDataModel.accountsCol)
        .doc(id)
        .update({'balance': newBalance});
  }

  Future<void> deleteAccount(String id) async {
    await FirebaseFirestore.instance
        .collection(FirestoreDataModel.accountsCol)
        .doc(id)
        .delete();
  }
}

/// Extension to contain actions possible with beers
extension FirestoreBeers on FirestoreDataModel {
  Future<void> setAvailability(String id, bool available) async {
    await FirebaseFirestore.instance
        .collection(FirestoreDataModel.beersCol)
        .doc(id)
        .update({'available': available});
  }
}

extension FirestoreTransaction on FirestoreDataModel {
  Future<void> handleTransaction(
      CustomerAccount account, EventTransaction transaction) async {
    if (transaction is EventTransactionDrink) {
      log('Handle drink transaction');
      await newTransaction(transaction);
      await setAccountBalance(account.id, account.balance - transaction.price);
    } else if (transaction is EventTransactionRecharge) {
      log('Handle recharge transaction');
      await newTransaction(transaction);
      await setAccountBalance(account.id, account.balance + transaction.amount);
    } else {
      logError(
          'Error a transaction that was not drink or recharge was submited !',
          StackTrace.current);
    }
  }

  Future<void> newTransaction(EventTransaction transaction) async {
    await FirebaseFirestore.instance
        .collection(
            '${FirestoreDataModel.eventsCol}/${currentEvent.id}/${FirestoreDataModel.transactionsCol}')
        .add(transaction.toJson());
  }
}
