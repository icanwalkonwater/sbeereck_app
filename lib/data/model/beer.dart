import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';

import '../providers.dart';

class Beer {
  final String id;
  final bool available;
  final String name;
  final DocumentReference<BeerType> typeRef;
  final String? image;

  const Beer(
      {required this.id,
      required this.available,
      required this.name,
      required this.typeRef,
      this.image});

  // Assume its already in the cache
  Future<BeerType> get type async =>
      (await typeRef.get(optionFromCache)).data()!;

  DocumentReference<Beer> get asRef => FirebaseFirestore.instance
      .doc('${FirestoreDataModel.beersCol}/$id')
      .withBeerConverter();

  BeerType typeCached(FirestoreDataModel model) =>
      model.beerTypes.firstWhere((ty) => ty.id == typeRef.id);

  String? get assetFile => image != null ? 'assets/beers/$image' : null;

  Beer.fromJson(String id, Map<String, dynamic> raw)
      : this(
          id: id,
          available: raw['available'],
          name: raw['name'],
          typeRef: (raw['type'] as DocumentReference).withBeerTypeConverter(),
          image: raw['image'],
        );

  Map<String, dynamic> toJson() => {
        'available': available,
        'name': name,
        'type': typeRef,
        'image': image,
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
  final int price;
  final List<BeerTypeAddon> addons;

  num get priceReal => price.toDouble() / 100.0;

  BeerType(
      {required this.id,
      required this.name,
      required this.price,
      required this.addons});

  BeerType.fromJson(String id, Map<String, dynamic> raw)
      : this(
          id: id,
          name: raw['name'],
          price: raw['price'],
          addons: (raw['addons'] as List<dynamic>)
              .mapIndexed((index, raw) => BeerTypeAddon(
                  id: index, name: raw['name'], price: raw['price']))
              .toList(growable: false),
        );

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
      };
}

class BeerTypeAddon {
  final int id;
  final String name;
  final int price;

  num get priceReal => price.toDouble() / 100.0;

  const BeerTypeAddon(
      {required this.id, required this.name, required this.price});
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
        fromFirestore: (snapshot, _) {
          log(snapshot.data().toString());
          return BeerType.fromJson(snapshot.id, snapshot.data()!);
        },
        toFirestore: (ty, _) => ty.toJson(),
      );
}

class BeerWithType {
  final Beer beer;
  final BeerType type;

  BeerWithType(this.beer, this.type);
}
