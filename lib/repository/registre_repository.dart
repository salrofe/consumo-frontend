import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/registre.dart';

class RegistreRepository {
  final String baseUrl = 'http://192.168.56.1:3000';

  final String adminUID = 'HdXHS40ngcRZVJ1NsuEQPBunYx03';

  // Si l´usuari es l´administrador, no filtra
  Future<List<Registre>> fetchRegistres(String uid) async {
    final bool esAdmin = uid == adminUID;
    final Uri url = esAdmin
        ? Uri.parse('$baseUrl/registros?uid=$uid') // sense filtro
        : Uri.parse('$baseUrl/registros?uid=$uid'); // sols els seus

    final response = await http.get(url);

    //  final response =
    //      await http.get(Uri.parse('http://10.0.2.2:3000/registros?uid=$uid'));

    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Registre.fromJson(e)).toList();
    } else {
      throw Exception('Error al carregar els registres');
    }
  }

  Future<void> afegirRegistre(Registre nouRegistre) async {
    final response = await http.post(
      Uri.parse('$baseUrl/registros'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(nouRegistre.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Error al afegir registre');
    }
  }

  Future<void> actualitzarRegistre(Registre registre) async {
    final response = await http.put(
      Uri.parse('$baseUrl/registros/${registre.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(registre.toJson()),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al actualitzar registre');
    }
  }

  Future<void> eliminarRegistre(int id, String uid) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/registros/$id?uid=$uid'),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Error al eliminar registre');
    }
  }
}
