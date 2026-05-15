import 'package:app_links/app_links.dart';
import 'package:appcaixaauto/src/page/carrinho_compra.dart';
import 'package:appcaixaauto/src/page/dashboard_page.dart';
import 'package:appcaixaauto/src/page/login.dart';
import 'package:flutter/material.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppLinks appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    initDeepLink();
  }

  void initDeepLink() {
    appLinks.uriLinkStream.listen((Uri uri) {
      print(uri);
      print(uri.host);
      print(uri.pathSegments);

      if (uri.host == "session" && uri.pathSegments.isNotEmpty) {
        final sessionId = uri.pathSegments.first;

        print("SESSION -> $sessionId");

        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => CarrinhoCompra(session: sessionId)),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: DashboardPage(),
    );
  }
}