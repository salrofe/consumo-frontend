import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasca_comarques/screens/login.dart';
import 'package:tasca_comarques/screens/pantalla_registres.dart';
import 'package:tasca_comarques/providers/registre_provider.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // Sols si utlitzem AuthWrapper

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RegistreProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registres consum d’aigua',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),

      // Sempre comencem en PantallaLogin
      home: const PantallaLogin(),

      //Si volguerem detectar sesió ja iniciada automàticament, cambiariem el home per este altre:
      // home: const AuthWrapper(),

      routes: {
        '/login': (context) => const PantallaLogin(),
        '/registres': (context) => const PantallaRegistres(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Lògica de autenticació, per detectar sesió iniciada (comentada)

    // final user = FirebaseAuth.instance.currentUser;

    // if (user == null) {
    //   return const PantallaLogin();
    // } else {
    //   return const PantallaRegistres();
    // }

    // Sempre forcem login:
    return const PantallaLogin();
  }
}
