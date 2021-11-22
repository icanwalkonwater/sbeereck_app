import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:mdi/mdi.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../data/models.dart';
import '../data/providers.dart';
import '../utils.dart';

const _messages = [
  'Reviens staff',
  'TOI BAR MAINTENANT',
  'T\'es viré',
  'T pa bo',
];

class StaffList extends StatelessWidget {
  final Random _random = Random();

  StaffList({Key? key}) : super(key: key);

  void _onSensSms(Staff staff) async {
    if (await canSendSMS()) {
      await sendSMS(
          message: _messages[_random.nextInt(_messages.length)],
          recipients: [staff.tel]);
    }
  }

  void _onEdit(BuildContext context, Staff staff) {
    final l10n = AppLocalizations.of(context)!;
    showSimpleDialog(
        context: context,
        title: l10n.staffChangeAvailability,
        popOnAction: true,
        onOk: (ctx) => ctx
            .read<FirestoreDataModel>()
            .setStaffAvailability(staff, !staff.isAvailable));
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = context.read<FirestoreDataModel>().isAdmin;
    return Selector<FirestoreDataModel, List<Staff>>(
      selector: (_, model) => model.staffs.toList(growable: false),
      builder: (_, staffs, __) {
        final children = staffs
            .map((staff) => _StaffItem(
                  editable: canEdit,
                  staff: staff,
                  color: Colors
                      .primaries[_random.nextInt(Colors.primaries.length)],
                  onSendSms: () => _onSensSms(staff),
                  onEdit: () => _onEdit(context, staff),
                ))
            .toList(growable: false);

        return _StaffListWrapper(
          children: children,
        );
      },
    );
  }
}

class _StaffListWrapper extends StatelessWidget {
  final List<Widget> children;

  const _StaffListWrapper({Key? key, required this.children}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Column(children: children),
      ),
    );
  }
}

class _StaffItem extends StatelessWidget {
  final bool editable;
  final Color color;
  final Staff staff;
  final VoidCallback? onSendSms;
  final VoidCallback? onEdit;

  const _StaffItem(
      {Key? key,
      required this.staff,
      required this.color,
      this.onSendSms,
      required this.editable,
      this.onEdit})
      : super(key: key);

  bool _showSmsAction() {
    return staff.isAvailable &&
        staff.tel.length == 10 &&
        (staff.tel.startsWith("06") || staff.tel.startsWith("07"));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor =
        staff.isAvailable ? Colors.green : theme.colorScheme.surface;

    final avatarName = staff.name[0].toUpperCase();
    final actionButton = _showSmsAction()
        ? IconButton(
            onPressed: onSendSms, icon: const Icon(Mdi.androidMessages))
        : null;

    final tile = ListTile(
      leading: CircleAvatar(
        backgroundColor: color,
        child: Text(avatarName),
      ),
      title: Text(staff.name),
      trailing: actionButton,
    );

    if (editable) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: ElevatedButton(
          onPressed: onEdit,
          style: ElevatedButton.styleFrom(primary: bgColor),
          child: tile,
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Card(color: bgColor, child: tile),
      );
    }
  }
}
