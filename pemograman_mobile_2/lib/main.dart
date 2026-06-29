import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pemograman_mobile_2/signIn.dart';
import 'package:pemograman_mobile_2/app_theme.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const Latihan());
}


String iduser = '';

class Latihan extends StatelessWidget {
  const Latihan({super.key});

  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Aplikasi CRUD",
      theme: AppTheme.themeData,
      home: FutureBuilder(
        future: _saveUser(),
        builder: ((context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting){
            return Scaffold(
              backgroundColor: AppTheme.background,
              body: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.gold),
                ),
              ),
            );
          } else {
            // return iduser == '' ? signIn() : Home();
            return signIn();
          } 
        })),
    );
  }
}



Future<void> _saveUser() async {
  final prefs = await SharedPreferences.getInstance();
  iduser = prefs.getString('userid') ?? '';
  print(iduser);

}