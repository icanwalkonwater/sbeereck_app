import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sbeereck_app/data/model/staff.dart';

import '../models.dart';
import '../providers.dart';

class EventPeriod {
  final String id;
  final String name;
  final Timestamp created;

  EventPeriod({required this.id, required this.name, required this.created});

  EventPeriod.fromJson(String id, Map<String, dynamic> raw)
      : this(
          id: id,
          name: raw['name'],
          created: raw['created'],
        );

  Map<String, dynamic> toJson() => {
        'name': name,
        'created': created,
      };
}

enum EventTransactionType { drink, recharge }

abstract class EventTransaction {
  Map<String, dynamic> toJson();
}

class EventTransactionDrink implements EventTransaction {
  final String id;
  final DocumentReference<Beer> beerRef;
  final int price;
  final DocumentReference<CustomerAccount> customerRef;
  final DocumentReference<Staff> staffRef;
  final Timestamp created;

  num get priceReal => price.toDouble() / 100.0;

  Future<Beer> get beer async => (await beerRef.get(optionFromCache)).data()!;

  Future<CustomerAccount> get customer async =>
      (await customerRef.get(optionFromCache)).data()!;

  Future<Staff> get staff async =>
      (await staffRef.get(optionFromCache)).data()!;

  const EventTransactionDrink(
      {required this.id,
      required this.beerRef,
      required this.price,
      required this.customerRef,
      required this.staffRef,
      required this.created});

  EventTransactionDrink.blueprint(
      {this.id = 'dummy',
      required this.beerRef,
      required this.price,
      required this.customerRef,
      required this.staffRef,
      required this.created});

  EventTransactionDrink.fromJson(String id, Map<String, dynamic> raw)
      : this(
          id: id,
          beerRef: (raw['beer'] as DocumentReference).withBeerConverter(),
          price: raw['price'],
          customerRef: (raw['customer'] as DocumentReference)
              .withCustomerAccountConverter(),
          staffRef: (raw['staff'] as DocumentReference).withStaffConverter(),
          created: raw['created'],
        );

  @override
  Map<String, dynamic> toJson() => {
        'type': EventTransactionType.drink.index,
        'beer': beerRef,
        'price': price,
        'customer': customerRef,
        'staff': staffRef,
        'created': created,
      };
}
