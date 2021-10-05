/// Represent a single account straight from firestore
class CustomerAccount {
  final String id;
  final String firstName;
  final String lastName;
  final CustomerSchool? school;
  final String? phone;
  final bool isMember;
  final num balance;
  final CustomerStat stats;

  CustomerAccount({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.school,
    this.phone,
    required this.isMember,
    required this.balance,
    required this.stats,
  });

  // Conversion methods from and to documents

  CustomerAccount.fromJson(String id, Map<String, dynamic> raw)
      : this(
            id: id,
            firstName: raw['first_name'],
            lastName: raw['last_name'],
            school: CustomerSchool.values[raw['school']],
            phone: raw['phone'],
            isMember: raw['is_member'],
            balance: raw['balance'],
            stats: CustomerStat(
                regularCount: raw['stat_regular_count'],
                specialCount: raw['stat_special_count'],
                totalSpentMoney: raw['stat_total_money']));

  Map<String, dynamic> toJson() => {
        'first_name': firstName,
        'last_name': lastName,
        if (school != null) 'school': school!.index,
        if (phone != null) 'phone': phone,
        'is_member': isMember,
        'balance': balance,
        'stat_regular_count': stats.regularCount,
        'stat_special_count': stats.specialCount,
        'stat_total_money': stats.totalSpentMoney,
      };

  @override
  String toString() =>
      'CustomerAccount{id=$id, firstName=$firstName, lastName=$lastName, school=$school, phone=$phone, isMember=$isMember, balance=$balance, stats=ommitted}';
}

enum CustomerSchool {
  Ensimag,
  E3,
  Phelma,
  Papet,
  GI,
  Polytech,
  Esisar,
  IAE,
  UGA,
  Others,
}

class CustomerStat {
  final int regularCount;
  final int specialCount;
  final int totalSpentMoney;

  CustomerStat({
    required this.regularCount,
    required this.specialCount,
    required this.totalSpentMoney,
  });
}
