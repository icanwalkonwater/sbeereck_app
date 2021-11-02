import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers.dart';

class Beer {
  final String id;
  final bool available;
  final String name;
  final DocumentReference<BeerType> typeRef;

  const Beer(
      {required this.id,
      required this.available,
      required this.name,
      required this.typeRef});

  // Assume its already in the cache
  Future<BeerType> get type async =>
      (await typeRef.get(optionFromCache)).data()!;

  DocumentReference<Beer> get asRef => FirebaseFirestore.instance
      .doc('${FirestoreDataModel.beersCol}/$id')
      .withBeerConverter();

  Beer.fromJson(String id, Map<String, dynamic> raw)
      : this(
            id: id,
            available: raw['available'],
            name: raw['name'],
            typeRef:
                (raw['type'] as DocumentReference).withBeerTypeConverter());

  Map<String, dynamic> toJson() => {
        'available': available,
        'name': name,
        'type': typeRef,
      };
}

extension BeerConverterR<T> on DocumentReference<T> {
  DocumentReference<Beer> withBeerConverter() => withConverter(
        fromFirestore: (snapshot, _) =>
            Beer.fromJson(snapshot.id, snapshot.data()!),
        toFirestore: (beer, _) => beer.toJson(),
      );
}

extension BeerConverterQ<T> on Query<T> {
  Query<Beer> withBeerConverter() => withConverter(
        fromFirestore: (snapshot, _) =>
            Beer.fromJson(snapshot.id, snapshot.data()!),
        toFirestore: (beer, _) => beer.toJson(),
      );
}

class BeerType {
  final String id;
  final String name;
  final num price;

  const BeerType({required this.id, required this.name, required this.price});

  BeerType.fromJson(String id, Map<String, dynamic> raw)
      : this(
          id: id,
          name: raw['name'],
          price: raw['price'],
        );

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
      };
}

extension BeerTypeConverterR<T> on DocumentReference<T> {
  DocumentReference<BeerType> withBeerTypeConverter() => withConverter(
        fromFirestore: (snapshot, _) =>
            BeerType.fromJson(snapshot.id, snapshot.data()!),
        toFirestore: (ty, _) => ty.toJson(),
      );
}

extension BeerTypeConverterQ<T> on Query<T> {
  Query<BeerType> withBeerTypeConverter() => withConverter(
        fromFirestore: (snapshot, _) =>
            BeerType.fromJson(snapshot.id, snapshot.data()!),
        toFirestore: (ty, _) => ty.toJson(),
      );
}
