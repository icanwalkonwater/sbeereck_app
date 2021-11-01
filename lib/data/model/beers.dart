import 'package:cloud_firestore/cloud_firestore.dart';

class Beer {
  final String id;
  final bool available;
  final String name;
  final String typeRef;

  Beer(
      {required this.id,
      required this.available,
      required this.name,
      required this.typeRef});

  Beer.fromJson(String id, Map<String, dynamic> raw)
      : this(
          id: id,
          available: raw['available'],
          name: raw['name'],
          typeRef: (raw['type'] as DocumentReference).id,
        );

  Map<String, dynamic> toJson() => {
        'available': available,
        'name': name,
        'type': typeRef,
      };
}

class BeerType {
  final String id;
  final String name;
  final num price;

  BeerType({required this.id, required this.name, required this.price});

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
