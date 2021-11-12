import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:mdi/mdi.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/providers.dart';
import '../utils.dart';

class BeerList extends StatelessWidget {
  const BeerList({Key? key}) : super(key: key);

  void _onClickItem(BuildContext context, BeerWithType beer) {
    final l10n = AppLocalizations.of(context)!;
    showSimpleDialog(
        context: context,
        title: beer.beer.isAvailable
            ? l10n.beerMakeUnavailable
            : l10n.beerMakeAvailable,
        popOnAction: true,
        onOk: (ctx) => ctx
            .read<FirestoreDataModel>()
            .setAvailability(beer.beer.id, !beer.beer.isAvailable));
  }

  @override
  Widget build(BuildContext context) {
    return Selector<FirestoreDataModel, List<BeerWithType>>(
      selector: (_, model) => model.beers
          .map((b) => BeerWithType(b, b.typeCached(model)))
          .toList(growable: false),
      builder: (_, beers, __) => _BeerListWrapper(
          children: beers
              .map((beer) => _BeerItem(
                  beer: beer, onPressed: (b) => _onClickItem(context, b)))
              .toList(growable: false)),
    );
  }
}

class _BeerListWrapper extends StatelessWidget {
  final List<Widget> children;

  const _BeerListWrapper({Key? key, required this.children}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
          children: children
              .map((e) => Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    child: e,
                  ))
              .toList(growable: false)),
    );
  }
}

class _BeerItem extends StatelessWidget {
  final BeerWithType beer;
  final void Function(BeerWithType) onPressed;

  const _BeerItem({Key? key, required this.beer, required this.onPressed})
      : super(key: key);

  Widget get _avatar {
    if (beer.beer.assetFile != null) {
      return CircleAvatar(foregroundImage: AssetImage(beer.beer.assetFile!));
    } else {
      return CircleAvatar(child: Text(beer.beer.name[0].toUpperCase()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final btnTheme = beer.beer.isAvailable
        ? ElevatedButton.styleFrom(
            primary: Colors.green, onPrimary: theme.colorScheme.onSurface)
        : ElevatedButton.styleFrom(
            primary: theme.colorScheme.surface,
            onPrimary: theme.colorScheme.onSurface);

    final iconColor = beer.beer.isAvailable ? Colors.white : theme.errorColor;
    final icon = beer.beer.isAvailable ? Mdi.checkCircle : Mdi.closeCircle;
    final textStyle = beer.beer.isAvailable
        ? null
        : const TextStyle(decoration: TextDecoration.lineThrough);

    return ElevatedButton(
      onPressed: () => onPressed(beer),
      style: btnTheme,
      child: ListTile(
        leading: _avatar,
        title: Text(beer.beer.name, style: textStyle),
        subtitle: Text(beer.type.name),
        trailing: Icon(icon, color: iconColor),
      ),
    );
  }
}
