import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sbeereck_app/data/provider/firestore.dart';

/// Represent a single account straight from firestore
class CustomerAccount {
  final String id;
  final String firstName;
  final String lastName;
  final CustomerSchool school;
  final bool isMember;
  final int balance;
  final CustomerStat stats;

  // Fixed point decimal
  num get balanceReal => balance.toDouble() / 100.0;

  bool get isPoor => balance <= 0;

  bool get isVeryPoor => balance < 0;

  const CustomerAccount({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.school,
    required this.isMember,
    required this.balance,
    required this.stats,
  });

  static const dummy = CustomerAccount(
      id: '0',
      firstName: 'John',
      lastName: 'Doe',
      school: CustomerSchool.unknown,
      isMember: false,
      balance: 0,
      stats: CustomerStat(quantityDrank: 0, totalMoney: 0));

  DocumentReference<CustomerAccount> get asRef => FirebaseFirestore.instance
      .doc('${FirestoreDataModel.accountsCol}/$id')
      .withCustomerAccountConverter();

  // Conversion methods from and to documents

  CustomerAccount.fromJson(String id, Map<String, dynamic> raw)
      : this(
            id: id,
            firstName: raw['firstName'],
            lastName: raw['lastName'],
            school: raw.containsKey('school')
                ? CustomerSchool.values[raw['school']]
                : CustomerSchool.unknown,
            isMember: raw['isMember'],
            balance: raw['balance'],
            stats: CustomerStat(
              quantityDrank: raw['stats']['quantityDrank'],
              totalMoney: raw['stats']['totalMoney'],
            ));

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        if (school != CustomerSchool.unknown) 'school': school.index,
        'isMember': isMember,
        'balance': balance,
        'stats': stats.toJson(),
      };

  Map<String, dynamic> toJsonEditable() => {
        'firstName': firstName,
        'lastName': lastName,
        'school': school,
      };

  @override
  String toString() =>
      'CustomerAccount{id=$id, firstName=$firstName, lastName=$lastName, school=$school, isMember=$isMember, balance=$balance, stats=$stats}';
}

extension CustomerAccountConverter<T> on DocumentReference<T> {
  DocumentReference<CustomerAccount> withCustomerAccountConverter() => withConverter(
    fromFirestore: (snapshot, _) => CustomerAccount.fromJson(snapshot.id, snapshot.data()!),
    toFirestore: (account, _) => account.toJson(),
  );
}

extension CustomerAccountConverterQ<T> on Query<T> {
  Query<CustomerAccount> withCustomerAccountConverter() => withConverter(
    fromFirestore: (snapshot, _) => CustomerAccount.fromJson(snapshot.id, snapshot.data()!),
    toFirestore: (account, _) => account.toJson(),
  );
}

// @formatter:off
enum CustomerSchool {
  ensimag, phelma, e3, papet, gi, polytech, esisar, iae, uga, unknown,
}
// @formatter:on

extension SchoolData on CustomerSchool {
  String assetLogo() {
    switch (this) {
      case CustomerSchool.ensimag:
        return 'assets/schools/ensimag.png';
      case CustomerSchool.phelma:
        return 'assets/schools/phelma.png';
      case CustomerSchool.e3:
        return 'assets/schools/e3.png';
      case CustomerSchool.papet:
        return 'assets/schools/papet.png';
      case CustomerSchool.gi:
        return 'assets/schools/gi.png';
      case CustomerSchool.polytech:
        return 'assets/schools/polytech.png';
      case CustomerSchool.esisar:
        return 'assets/schools/esisar.png';
      case CustomerSchool.iae:
        return 'assets/schools/iae.png';
      case CustomerSchool.uga:
      case CustomerSchool.unknown:
        return 'assets/schools/uga.png';
    }
  }
}

class CustomerStat {
  final int quantityDrank;
  final int totalMoney;

  num get totalMoneyReal => totalMoney.toDouble() / 100.0;

  const CustomerStat({required this.quantityDrank, required this.totalMoney});

  Map<String, dynamic> toJson() => {
        'quantityDrank': quantityDrank,
        'totalMoney': totalMoney,
      };

  @override
  String toString() =>
      'CustomerStats{quantityDrank=$quantityDrank, totalMoney=$totalMoney}';
}

class NewCustomerAccount {
  final String firstName;
  final String lastName;
  final CustomerSchool? school;

  const NewCustomerAccount(
      {required this.firstName, required this.lastName, this.school});

  Map<String, dynamic> toJsonFull() => {
        'firstName': firstName,
        'lastName': lastName,
        'school': school?.index ?? CustomerSchool.unknown.index,
        'isMember': true,
        'balance': 0,
        'stats': const CustomerStat(quantityDrank: 0, totalMoney: 0).toJson(),
      };

  Map<String, dynamic> toJsonLight() => {
        'firstName': firstName,
        'lastName': lastName,
        'school': school?.index ?? CustomerSchool.unknown.index,
      };
}
