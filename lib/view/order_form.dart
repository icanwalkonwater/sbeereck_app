import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:mdi/mdi.dart';
import 'package:provider/provider.dart';

import '../data/models.dart';
import '../data/providers.dart';
import '../utils.dart';

class OrderPage extends StatelessWidget {
  final String id;

  const OrderPage({Key? key, required this.id}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.orderFormTitle),
        actions: [
          IconButton(
              icon: const Icon(Mdi.brightness6),
              onPressed: () async =>
                  await context.read<ThemeModel>().switchTheme())
        ],
      ),
      body: SingleChildScrollView(
          child: Selector<FirestoreDataModel, CustomerAccount>(
              selector: (_, model) => model.accountById(id),
              builder: (_, account, __) => OrderForm(account: account))),
    );
  }
}

class OrderForm extends StatefulWidget {
  final CustomerAccount account;

  const OrderForm({Key? key, required this.account}) : super(key: key);

  @override
  _OrderFormState createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  final _formKey = GlobalKey<FormBuilderState>();

  Beer? get _beer => _formKey.currentState?.value['beer'];

  BeerTypeAddon? get _addon => _formKey.currentState?.value['addon'];

  int get _qty => _formKey.currentState?.value['quantity'] ?? 1;

  // Extra ugly
  void _invalidateWidget() {
    _formKey.currentState?.save();
    setState(() {});
  }

  void _onSubmit(FirestoreDataModel model, int total) async {
    final beer = _beer!;
    final transaction = EventTransactionDrink.blueprint(widget.account, beer,
        _addon != null ? [_addon!.id] : [], _qty, total, model.currentStaff);

    await model.handleTransaction(widget.account, transaction);
    Navigator.pop(context);
  }

  List<BeerWithType> _beerSelector(
          BuildContext ctx, FirestoreDataModel model) =>
      model.beers
          .where((beer) => beer.available)
          .map((beer) => BeerWithType(beer, beer.typeCached(model)))
          .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    log('Rebuild order form');
    // Only react to changes on beers
    final model = context.read<FirestoreDataModel>();

    final l10n = AppLocalizations.of(context)!;

    // Bit ugly but hey
    final beerType = _beer?.typeCached(model);
    final total = ((beerType?.price ?? 0) * _qty) + (_addon?.price ?? 0);

    return FormBuilder(
      key: _formKey,
      onChanged: () => _invalidateWidget(),
      autovalidateMode: AutovalidateMode.always,
      child: _OrderFormWrapper(children: [
        Selector<FirestoreDataModel, List<BeerWithType>>(
          selector: _beerSelector,
          builder: (ctx, beers, _) {
            return _OrderBeerField(
                name: 'beer',
                beers: beers,
                validator: FormBuilderValidators.required(context),
                onChanged: (_) =>
                    _formKey.currentState?.patchValue({'addon': null}),
                decoration: InputDecoration(
                    border: InputBorder.none,
                    labelText: l10n.orderFormChooseBeer));
          },
        ),
        if (beerType?.addons.isNotEmpty ?? false)
          _OrderAddonField(
              name: 'addon',
              decoration: InputDecoration(
                  labelText: l10n.orderFormChooseAddon,
                  border: InputBorder.none),
              type: beerType!),
        _OrderQuantityField(
          name: 'quantity',
          decoration: InputDecoration(
              border: InputBorder.none,
              labelText: l10n.orderFormChooseQuantity),
          validator: FormBuilderValidators.required(context),
          initialValue: _qty,
        ),
        _OrderSubmitButton(
          total: total,
          onPressed: _formKey.currentState?.validate() ?? false
              ? () => _onSubmit(model, total)
              : null,
        ),
      ]),
    );
  }
}

class _OrderFormWrapper extends StatelessWidget {
  final List<Widget> children;

  const _OrderFormWrapper({Key? key, required this.children}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
        children: children
            .map((child) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: child,
                ))
            .toList(growable: false));
  }
}

class _OrderBeerField extends StatelessWidget {
  final String name;
  final List<BeerWithType> beers;
  final FormFieldValidator<Beer>? validator;
  final ValueChanged<Beer?> onChanged;
  final InputDecoration decoration;

  const _OrderBeerField(
      {Key? key,
      required this.name,
      required this.beers,
      this.validator,
      required this.onChanged,
      required this.decoration})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<Beer>(
        name: name,
        validator: validator,
        onChanged: onChanged,
        builder: (field) => InputDecorator(
              decoration: decoration,
              child: Column(
                children: beers
                    .map((beer) => _OrderBeerFieldItem(
                        beer: beer.beer,
                        type: beer.type,
                        selected: field.value?.id == beer.beer.id,
                        onTap: () => field.didChange(beer.beer)))
                    .toList(growable: false),
              ),
            ));
  }
}

class _OrderBeerFieldItem extends StatelessWidget {
  final Beer beer;
  final BeerType type;
  final bool selected;
  final VoidCallback onTap;

  const _OrderBeerFieldItem(
      {Key? key,
      required this.beer,
      required this.type,
      required this.selected,
      required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    final imageAvailable = beer.image != null;
    final image = imageAvailable ? AssetImage(beer.assetFile!) : null;
    final imageReplacement = beer.name[0].toUpperCase();
    final name = beer.name;
    final price = '${type.name} ${moneyFormatter.format(type.priceReal)}';

    return Card(
      elevation: selected ? 5.0 : null,
      color: selected ? color : null,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          foregroundImage: image,
          child: imageAvailable ? Text(imageReplacement) : null,
        ),
        title: Text(name),
        subtitle: Align(
          alignment: Alignment.centerLeft,
          child: Chip(label: Text(price)),
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _OrderAddonField extends StatelessWidget {
  final String name;
  final InputDecoration decoration;
  final BeerType type;
  final ValueChanged<BeerTypeAddon?>? onChanged;

  const _OrderAddonField(
      {Key? key,
      required this.name,
      required this.decoration,
      required this.type,
      this.onChanged})
      : super(key: key);

  String _textForAddon(BeerTypeAddon addon) =>
      '${addon.name} +${moneyFormatter.format(addon.priceReal)}';

  @override
  Widget build(BuildContext context) {
    return FormBuilderChoiceChip(
        name: name,
        decoration: decoration,
        onChanged: onChanged,
        options: type.addons
            .map((addon) => FormBuilderFieldOption(
                value: addon, child: Text(_textForAddon(addon))))
            .toList());
  }
}

class _OrderQuantityField extends StatelessWidget {
  final String name;
  final InputDecoration decoration;
  final FormFieldValidator<int?>? validator;
  final ValueChanged<int?>? onChanged;
  final int? initialValue;

  const _OrderQuantityField(
      {Key? key,
      required this.name,
      required this.decoration,
      this.validator,
      this.onChanged,
      this.initialValue})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FormBuilderField<int>(
      name: name,
      initialValue: initialValue,
      onChanged: onChanged,
      validator: validator,
      builder: (field) => InputDecorator(
        decoration: decoration,
        child: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Expanded(
                  child: _OrderQuantityFieldOption(
                label: l10n.orderFormQuantityOne,
                icon: Mdi.beer,
                value: 1,
                fieldValue: field.value,
                onPressed: () => field.didChange(1),
              )),
              const SizedBox(
                width: 8.0,
              ),
              Expanded(
                  child: _OrderQuantityFieldOption(
                label: l10n.orderFormQuantityTwo,
                icon: Mdi.glassMug,
                value: 2,
                fieldValue: field.value,
                onPressed: () => field.didChange(2),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderQuantityFieldOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final int value;
  final int? fieldValue;
  final VoidCallback? onPressed;

  const _OrderQuantityFieldOption(
      {Key? key,
      required this.label,
      required this.icon,
      required this.value,
      this.fieldValue,
      this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = ElevatedButton.styleFrom(
        primary: theme.colorScheme.surface,
        onPrimary: theme.colorScheme.onSurface);

    return ElevatedButton(
        onPressed: onPressed,
        style: fieldValue != value ? style : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            children: [
              Icon(icon, size: 64.0),
              Text(label),
            ],
          ),
        ));
  }
}

class _OrderSubmitButton extends StatelessWidget {
  final int total;
  final VoidCallback? onPressed;

  const _OrderSubmitButton({Key? key, required this.total, this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final label = l10n.orderFormTotal
        .replaceFirst('%total', moneyFormatter.format(total / 100.0));

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: theme.textTheme.headline5),
              const Icon(
                Mdi.chevronRightCircle,
                size: 32.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
