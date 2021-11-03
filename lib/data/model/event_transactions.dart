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

extension EventPeriodConverterD<T> on DocumentReference<T> {
  DocumentReference<EventPeriod> withEventPeriodConverter() => withConverter(
        fromFirestore: (snapshot, _) =>
            EventPeriod.fromJson(snapshot.id, snapshot.data()!),
        toFirestore: (event, _) => event.toJson(),
      );
}

extension EventPeriodConverterQ<T> on Query<T> {
  Query<EventPeriod> withEventPeriodConverter() => withConverter(
        fromFirestore: (snapshot, _) =>
            EventPeriod.fromJson(snapshot.id, snapshot.data()!),
        toFirestore: (event, _) => event.toJson(),
      );
}

enum EventTransactionType { drink, recharge }

abstract class EventTransaction {
  Map<String, dynamic> toJson();
}

class EventTransactionDrink implements EventTransaction {
  final String id;
  final DocumentReference<Beer> beerRef;
  final List<int> addons;
  final int quantity;
  final int price;
  final DocumentReference<CustomerAccount> customerRef;
  final DocumentReference<Staff> staffRef;
  final Timestamp createdAt;

  num get priceReal => price.toDouble() / 100.0;

  Future<Beer> get beer async => (await beerRef.get(optionFromCache)).data()!;

  Future<CustomerAccount> get customer async =>
      (await customerRef.get(optionFromCache)).data()!;

  Future<Staff> get staff async =>
      (await staffRef.get(optionFromCache)).data()!;

  EventTransactionDrink(
      {required this.id,
      required this.beerRef,
      required this.addons,
      required this.quantity,
      required this.price,
      required this.customerRef,
      required this.staffRef,
      required this.createdAt});

  EventTransactionDrink.blueprint(CustomerAccount customer, Beer beer,
      List<int> addons, int quantity, int price, Staff staff)
      : this(
          id: 'dummy',
          beerRef: beer.asRef,
          addons: addons,
          quantity: quantity,
          price: price,
          customerRef: customer.asRef,
          staffRef: staff.asRef,
          createdAt: Timestamp.now(),
        );

  EventTransactionDrink.fromJson(String id, Map<String, dynamic> raw)
      : this(
          id: id,
          beerRef: (raw['beer'] as DocumentReference).withBeerConverter(),
          addons: (raw['addons'] as List<dynamic>?)?.cast() ?? [],
          quantity: raw['quantity'] ?? 1,
          price: raw['price'],
          customerRef: (raw['customer'] as DocumentReference)
              .withCustomerAccountConverter(),
          staffRef: (raw['staff'] as DocumentReference).withStaffConverter(),
          createdAt: raw['createdAt'],
        );

  @override
  Map<String, dynamic> toJson() => {
        'type': EventTransactionType.drink.index,
        'beer': beerRef,
        'addons': addons,
        'quantity': quantity,
        'price': price,
        'customer': customerRef,
        'staff': staffRef,
        'createdAt': createdAt,
      };
}

class EventTransactionRecharge implements EventTransaction {
  final String id;
  final int amount;
  final DocumentReference<CustomerAccount> customerRef;
  final DocumentReference<Staff> staffRef;
  final Timestamp createdAt;

  EventTransactionRecharge(
      {required this.id,
      required this.amount,
      required this.customerRef,
      required this.staffRef,
      required this.createdAt});

  EventTransactionRecharge.blueprint(
      CustomerAccount customer, Staff staff, int amount)
      : this(
          id: 'dummy',
          amount: amount,
          customerRef: customer.asRef,
          staffRef: staff.asRef,
          createdAt: Timestamp.now(),
        );

  EventTransactionRecharge.fromJson(String id, Map<String, dynamic> raw)
      : this(
          id: id,
          amount: raw['amount'],
          customerRef: (raw['customer'] as DocumentReference)
              .withCustomerAccountConverter(),
          staffRef: (raw['staff'] as DocumentReference).withStaffConverter(),
          createdAt: raw['createdAt'],
        );

  @override
  Map<String, dynamic> toJson() => {
        'type': EventTransactionType.recharge.index,
        'amount': amount,
        'customer': customerRef,
        'staff': staffRef,
        'createdAt': createdAt,
      };
}

extension EventTransactionConverterD<T> on DocumentReference<T> {
  DocumentReference<EventTransaction> withEventTransactionConverter() =>
      withConverter(
        fromFirestore: (snapshot, _) {
          final raw = snapshot.data()!;
          final type = EventTransactionType.values[raw['type']];
          switch (type) {
            case EventTransactionType.drink:
              return EventTransactionDrink.fromJson(snapshot.id, raw);
            case EventTransactionType.recharge:
              return EventTransactionRecharge.fromJson(snapshot.id, raw);
          }
        },
        toFirestore: (transaction, _) => transaction.toJson(),
      );
}

extension EventTransactionConverterQ<T> on Query<T> {
  Query<EventTransaction> withEventTransactionConverter() => withConverter(
        fromFirestore: (snapshot, _) {
          final raw = snapshot.data()!;
          final type = EventTransactionType.values[raw['type']];
          switch (type) {
            case EventTransactionType.drink:
              return EventTransactionDrink.fromJson(snapshot.id, raw);
            case EventTransactionType.recharge:
              return EventTransactionRecharge.fromJson(snapshot.id, raw);
          }
        },
        toFirestore: (transaction, _) => transaction.toJson(),
      );
}
