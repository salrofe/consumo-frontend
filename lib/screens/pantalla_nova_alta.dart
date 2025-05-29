import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PantallaNovaAlta extends StatefulWidget {
  const PantallaNovaAlta({super.key});

  @override
  State<PantallaNovaAlta> createState() => _PantallaNovaAltaState();
}

class _PantallaNovaAltaState extends State<PantallaNovaAlta> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _error = '';
  String _missatge = '';
  bool _verificacioEnviada = false;
  bool _loading = false;

  Future<void> _registrar() async {
    setState(() {
      _error = '';
      _missatge = '';
      _loading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Introdueix un correu i una contrasenya.';
        _loading = false;
      });
      return;
    }

    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await cred.user!.sendEmailVerification();

      setState(() {
        _verificacioEnviada = true;
        _missatge = 'Compte creat! S\'ha enviat un correu de verificació.';
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? 'Error inesperat.';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _reenviarVerificacio() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
//        await user.sendEmailVerification();
        setState(() {
          _missatge = 'Correu de verificació reenviat!';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'No s\'ha pogut reenviar la verificació.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nou registre')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correu electrònic',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contrasenya',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (_loading) const CircularProgressIndicator(),
              if (_error.isNotEmpty)
                Text(_error, style: const TextStyle(color: Colors.red)),
              if (_missatge.isNotEmpty)
                Text(_missatge, style: const TextStyle(color: Colors.green)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loading ? null : _registrar,
                child: const Text('Registrar-se'),
              ),
              if (_verificacioEnviada)
                TextButton(
                  onPressed: _reenviarVerificacio,
                  child: const Text('Reenviar correu de verificació'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
