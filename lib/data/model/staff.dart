import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sbeereck_app/data/provider/firestore.dart';

class Staff {
  final String id;
  final String name;
  final String tel;
  final bool isAdmin;
  final bool isAvailable;

  const Staff(
      {required this.id,
      required this.name,
      required this.tel,
      required this.isAdmin,
      required this.isAvailable});

  DocumentReference<Staff> get asRef => FirebaseFirestore.instance
      .doc('${FirestoreDataModel.staffsCol}/$id')
      .withStaffConverter();

  Staff.fromJson(String id, Map<String, dynamic> raw)
      : this(
          id: id,
          name: raw['name'],
          tel: raw['tel'],
          isAdmin: raw['isAdmin'],
          isAvailable: raw['isAvailable'],
        );

  Map<String, dynamic> toJson() => {
        'name': name,
        'tel': tel,
        'isAdmin': isAdmin,
        'isAvailable': isAvailable,
      };
}

extension StaffConverterD<T> on DocumentReference<T> {
  DocumentReference<Staff> withStaffConverter() => withConverter(
        fromFirestore: (snapshot, _) =>
            Staff.fromJson(snapshot.id, snapshot.data()!),
        toFirestore: (staff, _) => staff.toJson(),
      );
}

extension StaffConverterQ<T> on Query<T> {
  Query<Staff> withStaffConverter() => withConverter(
        fromFirestore: (snapshot, _) =>
            Staff.fromJson(snapshot.id, snapshot.data()!),
        toFirestore: (staff, _) => staff.toJson(),
      );
}
