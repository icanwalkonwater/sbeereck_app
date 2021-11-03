import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sbeereck_app/data/providers.dart';

import '../../models.dart';

/// Extension to contain actions possible with accounts
extension FirestoreCustomers on FirestoreDataModel {
  CustomerAccount accountById(String id) {
    return accounts.firstWhere((acc) => acc.id == id,
        orElse: () => CustomerAccount.dummy);
  }

  Future<void> newAccount(NewCustomerAccount account) async {
    await FirebaseFirestore.instance
        .collection(FirestoreDataModel.accountsCol)
        .add(account.toJsonFull());
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
  Future<void> newTransaction(EventTransaction transaction) async {
    await FirebaseFirestore.instance
        .collection(
            '${FirestoreDataModel.eventsCol}/${currentEvent.id}/${FirestoreDataModel.transactionsCol}')
        .add(transaction.toJson());
  }

  Future<void> payDrink(CustomerAccount account, EventTransactionDrink transaction) async {
    await newTransaction(transaction);
    await setAccountBalance(account.id, account.balance - transaction.price);
  }
}
