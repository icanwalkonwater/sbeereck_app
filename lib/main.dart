import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import 'package:routemaster/routemaster.dart';

import 'data/providers.dart';
import 'view/account_detail.dart';
import 'view/home.dart';
import 'view/login.dart';
import 'view/order_form.dart';

final _routes =
    RouteMap(onUnknownRoute: (route) => const Redirect('/'), routes: {
  '/': (_) => const MaterialPage(child: HomePage()),
  '/account/:id': (route) =>
      MaterialPage(child: AccountDetailPage(id: route.pathParameters['id']!)),
  '/account/:id/order': (route) =>
      MaterialPage(child: OrderPage(id: route.pathParameters['id']!)),
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => ThemeModel(), lazy: false),
    ChangeNotifierProvider(create: (_) => UpToDateModel(), lazy: false),
    ChangeNotifierProvider(create: (_) => AuthModel()),
    ChangeNotifierProvider(create: (_) => FirestoreDataModel()),
  ], child: const SbeereckApp()));
}

class SbeereckApp extends StatelessWidget {
  const SbeereckApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.select((ThemeModel theme) => theme.theme);
    final loggedIn = context.select((AuthModel auth) => auth.loggedIn);

    return Consumer<UpToDateModel>(
        builder: (context, upToDateModel, w) => MaterialApp.router(
              title: "S'Beer Eck",
              theme: ThemeData(brightness: theme),
              supportedLocales: const [Locale('fr'), Locale('en')],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                FormBuilderLocalizations.delegate
              ],
              routerDelegate: RoutemasterDelegate(routesBuilder: (ctx) {
                // If still checking for updates
                if (upToDateModel.upToDate == null) {
                  return RouteMap(routes: {
                    '/': (_) => const MaterialPage(
                        child: Center(child: CircularProgressIndicator())),
                  });

                  // If not up to date
                } else if (upToDateModel.upToDate == false) {
                  return RouteMap(routes: {
                    '/': (_) => const MaterialPage(child: NeedUpdatePage())
                  });

                  // If not logged in
                } else if (!loggedIn) {
                  return RouteMap(routes: {
                    '/': (_) => const MaterialPage(child: LoginPage())
                  });

                  // Finally, the real app
                } else {
                  return _routes;
                }
              }),
              routeInformationParser: const RoutemasterParser(),
            ));
  }
}

class NeedUpdatePage extends StatelessWidget {
  const NeedUpdatePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
          child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Please update !', style: theme.textTheme.headline4),
        ),
      )),
    );
  }
}
