import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/registre.dart';
import '../repository/registre_repository.dart';

class RegistreProvider with ChangeNotifier {
  final RegistreRepository _repo = RegistreRepository();
  List<Registre> _totsElsRegistres = []; // Tots els registres
  List<Registre> _registresFiltrats = []; // Registres filtrats per usuari
  bool _loading = false;

  // UID del administrador
  static const String _adminUid = 'HdXHS40ngcRZVJ1NsuEQPBunYx03';

  List<Registre> get registres => _registresFiltrats;
  bool get loading => _loading;

  Future<void> carregarRegistres() async {
    _loading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('uid');

      if (uid == null) {
        throw Exception('No s\'ha trobat cap UID');
      }

      // Carrega els registres (el repo filtra segons l´UID internament)
      _totsElsRegistres = await _repo.fetchRegistres(uid);

      // Filtrar visualment els registres
      _filtrarRegistresPerUid(uid);
    } catch (e) {
      debugPrint('❌ Error al carregar registres: $e');
      _totsElsRegistres = [];
      _registresFiltrats = [];
    }

    _loading = false;
    notifyListeners();
  }

  void _filtrarRegistresPerUid(String uid) {
    print(uid);
    print(_adminUid);
    if (uid == _adminUid) {
      print("vore");
      _registresFiltrats = [..._totsElsRegistres];
    } else {
      _registresFiltrats =
          _totsElsRegistres.where((registre) => registre.uid == uid).toList();
    }

    debugPrint('✅ Total registres carregats: ${_totsElsRegistres.length}');
    debugPrint('✅ Registres després de filtrar: ${_registresFiltrats.length}');
  }

  Future<void> afegirRegistre(Registre registre) async {
    try {
      await _repo.afegirRegistre(registre);
      await carregarRegistres();
    } catch (e) {
      debugPrint('❌ Error al afegir registre: $e');
      rethrow;
    }
  }

  Future<void> actualitzarRegistre(Registre registreActualitzat) async {
    try {
      await _repo.actualitzarRegistre(registreActualitzat);
      await carregarRegistres();
    } catch (e) {
      debugPrint('❌ Error al actualitzar registre: $e');
      rethrow;
    }
  }

  Future<void> eliminarRegistre(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('uid');

      if (uid == null) throw Exception('No s\'ha trobat l\'usuari');

      await _repo.eliminarRegistre(id, uid);

      _totsElsRegistres.removeWhere((r) => r.id == id);
      _filtrarRegistresPerUid(uid);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error al eliminar registre: $e');
      throw Exception('No s\'ha pogut eliminar el registre');
    }
  }
}
