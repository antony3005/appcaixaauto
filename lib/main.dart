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
 Widget build(BuildContext context) {
 return MaterialApp(
 title: 'Flutter Demo',
 theme: ThemeData(primarySwatch: Colors.blue),
 home: LoginPage(),
 );
 }
 
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    throw UnimplementedError();
  }
}

class DashboardPage extends StatelessWidget {
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
