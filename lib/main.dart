
import 'package:client_info/Screens/general_info.dart';
import 'package:client_info/Screens/invoices.dart';
import 'package:client_info/Screens/main_screen.dart';
import 'package:client_info/Screens/postdate.dart';
import 'package:client_info/sql/mysql_services.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Client Info',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}
