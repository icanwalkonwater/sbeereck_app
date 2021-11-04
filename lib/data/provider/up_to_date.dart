import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:version/version.dart';

class UpToDateModel extends ChangeNotifier {
  static const metaCol = 'meta';

  bool? _upToDate;

  bool? get upToDate => _upToDate;

  UpToDateModel() {
    FirebaseFirestore.instance
        .collection(metaCol)
        .doc('0')
        .get(const GetOptions(source: Source.server))
        .then((snapshot) async =>
            Version.parse(snapshot.data()!['version']) <=
            Version.parse((await PackageInfo.fromPlatform()).version))
        .then((res) {
      _upToDate = res;
      notifyListeners();
    });
  }
}
