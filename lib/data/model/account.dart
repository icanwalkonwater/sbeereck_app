/// Represent a single account straight from firestore
class CustomerAccount {
  final String id;
  final String firstName;
  final String lastName;
  final CustomerSchool? school;
  final bool isMember;
  final num balance;
  final CustomerStat stats;

  const CustomerAccount({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.school,
    required this.isMember,
    required this.balance,
    required this.stats,
  });

  // Conversion methods from and to documents

  CustomerAccount.fromJson(String id, Map<String, dynamic> raw)
      : this(
            id: id,
            firstName: raw['firstName'],
            lastName: raw['lastName'],
            school: raw.containsKey('school')
                ? CustomerSchool.values[raw['school']]
                : null,
            isMember: raw['isMember'],
            balance: raw['balance'],
            stats: CustomerStat(
              quantityDrank: raw['stats']['quantityDrank'],
              totalMoney: raw['stats']['totalMoney'],
            ));

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        if (school != null) 'school': school!.index,
        'isMember': isMember,
        'balance': balance,
        'stats': stats.toJson(),
      };

  @override
  String toString() =>
      'CustomerAccount{id=$id, firstName=$firstName, lastName=$lastName, school=$school, isMember=$isMember, balance=$balance, stats=$stats}';
}

// @formatter:off
enum CustomerSchool {
  ensimag, phelma, e3, papet, gi, polytech, esisar, iae, uga, unknown,
}
// @formatter:on

class CustomerStat {
  final int quantityDrank;
  final int totalMoney;

  const CustomerStat({required this.quantityDrank, required this.totalMoney});

  Map<String, dynamic> toJson() => {
        'quantityDrank': quantityDrank,
        'totalMoney': totalMoney,
      };

  @override
  String toString() =>
      'CustomerStats{quantityDrank=$quantityDrank, totalMoney=$totalMoney}';
}

class NewAccount {
  final String firstName;
  final String lastName;
  final CustomerSchool? school;

  const NewAccount(
      {required this.firstName, required this.lastName, this.school});

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'school': school?.index ?? CustomerSchool.unknown.index,
        'isMember': true,
        'balance': 0,
        'stats': const CustomerStat(quantityDrank: 0, totalMoney: 0).toJson(),
      };
}
