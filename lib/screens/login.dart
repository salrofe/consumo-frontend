import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tasca_comarques/screens/pantalla_registres.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasca_comarques/screens/pantalla_nova_alta.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final TextEditingController _usuariController = TextEditingController();
  final TextEditingController _contrasenyaController = TextEditingController();

  String _error = '';
  bool _visible = true;
  bool _loading = false;

  void _toggleVisibility() {
    setState(() {
      _visible = !_visible;
    });
  }

  Future<void> _login() async {
    final email = _usuariController.text.trim();
    final password = _contrasenyaController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Per favor, ompli tots els camps.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

//      if (!credential.user!.emailVerified) {
//        setState(() {
//          _error = 'Compte no verificat. Comprova el teu correu electrònic.';
//          _loading = false;
//        });
//        return;
//      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('uid', credential.user!.uid);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PantallaRegistres()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _loading = false;
        switch (e.code) {
          case 'user-not-found':
            _error = 'Usuari no registrat.';
            break;
          case 'wrong-password':
            _error = 'Contrasenya incorrecta.';
            break;
          case 'invalid-email':
            _error = 'Correu electrònic no vàlid.';
            break;
          case 'invalid-credential':
            _error = 'Usuari o contrasenya no vàlids.';
            break;
          case 'network-request-failed':
            _error = 'Error de connexió a la xarxa.';
            break;
          default:
            _error = 'Error d’autenticació: ${e.message}';
        }
      });
    }
  }

  Future<void> _register() async {
    final email = _usuariController.text.trim();
    final password = _contrasenyaController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Introdueix un correu i contrasenya per registrar-te.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user!.sendEmailVerification();

      setState(() {
        _loading = false;
        _error =
            'Compte creat. Comprova el teu correu per verificar-lo abans d’accedir.';
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message ?? 'Error en el registre';
      });
    }
  }

  Future<void> _reenviarVerificacio() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();
      setState(() {
        _error = 'Correu de verificació reenviat.';
      });
    } catch (e) {
      setState(() {
        _error = 'Error en reenviar la verificació.';
      });
    }
  }

  @override
  void initState() {
    super.initState();

    // ARA ES FORÇA SEMPRE A INICIAR SESSIÓ (si volem que recorde que
    //si esta logat no demane iniciar sessió descomentar,
    // tindria sentit en un movil usat sols per un usuari):
    /*
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.emailVerified) {
      // Si ja està loguejat i verificat, anem directament a la pantalla principal
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PantallaRegistres()),
        );
      });
    }
    */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[50],
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedOpacity(
                    opacity: _visible ? 1.0 : 0.0,
                    duration: const Duration(seconds: 2),
                    child: GestureDetector(
                      onTap: _toggleVisibility,
                      child: Column(
                        children: [
                          SizedBox(
                            width: 150,
                            height: 150,
                            child: Image.asset('assets/img/water-tap.png'),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Sistema de Supervisió de Consum d\'Aigua',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 26,
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _usuariController,
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      labelText: 'Usuari (correu)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _contrasenyaController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      labelText: 'Contrasenya',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_error.isNotEmpty)
                    Text(
                      _error,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _loading ? null : _login,
                    child: const Text('Accedir'),
                  ),
                  TextButton(
                    //             onPressed: _loading ? null : _register,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const PantallaNovaAlta()),
                      );
                    },
                    child: const Text('Registrar-se'),
                  ),
                  TextButton(
                    onPressed: _loading ? null : _reenviarVerificacio,
                    child: const Text('Reenviar correu de verificació'),
                  ),
                ],
              ),
            ),
          ),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
