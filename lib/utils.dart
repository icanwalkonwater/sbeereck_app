import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final moneyFormatter = NumberFormat.currency(symbol: '€');
final beerQuantityFormatter = NumberFormat('0.00 L');

void Function(T) debounce<T>(Duration timeout, void Function(T) handler) {
  Timer? timer;

  return (val) {
    if (timer?.isActive ?? false) {
      timer!.cancel();
    }

    timer = Timer(timeout, () => handler(val));
  };
}

void showSimpleDialog(
    {required BuildContext context,
    required String title,
    bool popOnAction = false,
    String? btnOkLabel,
    String? btnCancelLabel,
    void Function(BuildContext)? onOk,
    void Function(BuildContext)? onCancel}) {
  final gInt = MaterialLocalizations.of(context);
  showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: Text(title),
            actions: [
              TextButton(
                child: Text(btnCancelLabel ?? gInt.cancelButtonLabel),
                onPressed: () {
                  if (popOnAction) Navigator.pop(context);
                  if (onCancel != null) onCancel(context);
                },
              ),
              TextButton(
                child: Text(btnOkLabel ?? gInt.okButtonLabel),
                onPressed: () {
                  if (popOnAction) Navigator.pop(context);
                  if (onOk != null) onOk(context);
                },
              )
            ],
          ));
}
