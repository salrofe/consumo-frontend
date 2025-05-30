import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../model/registre.dart';
import '../providers/registre_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PantallaAfegirRegistre extends StatefulWidget {
  final Registre? registre;

  const PantallaAfegirRegistre({super.key, this.registre});

  @override
  State<PantallaAfegirRegistre> createState() => _PantallaAfegirRegistreState();
}

class _PantallaAfegirRegistreState extends State<PantallaAfegirRegistre> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _contadorIdController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _consumoLitrosController =
      TextEditingController();
  final TextEditingController _uidController = TextEditingController();

  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.registre != null) {
      // Si estem editant, cumplimentem les dades
      _contadorIdController.text = widget.registre!.contadorId.toString();
      _fechaController.text =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(widget.registre!.fecha);
      _selectedDate = widget.registre!.fecha;

      _consumoLitrosController.text = widget.registre!.consumoLitros.toString();
    }
  }

  @override
  void dispose() {
    _contadorIdController.dispose();
    _fechaController.dispose();
    _consumoLitrosController.dispose();
    _uidController.dispose();
    super.dispose();
  }

  Future<String?> obtenerUidContador(int contadorId) async {
    try {
      final url = Uri.parse('http://192.168.56.1:3000/contadors/$contadorId');
      final response = await http.get(url);

      print('Status code obtenerUidContador: ${response.statusCode}');
      print('Body obtenerUidContador: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        if (jsonData.isEmpty) {
          return null;
        }

        if (jsonData.containsKey('uid')) {
          return jsonData['uid'];
        } else {
          throw Exception('La respuesta no contiene el campo uid');
        }
      } else {
        throw Exception(
            'Error HTTP al obtener contador: Código ${response.statusCode}');
      }
    } catch (e, stacktrace) {
      print('Error en obtenerUidContador: $e');
      print('StackTrace: $stacktrace');
      throw Exception('Error consultando el contador: $e');
    }
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final DateTime finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          _selectedDate = finalDateTime;
          _fechaController.text =
              DateFormat('yyyy-MM-dd HH:mm:ss').format(finalDateTime);
        });
      } else {
        setState(() {
          _selectedDate = pickedDate;
          _fechaController.text =
              DateFormat('yyyy-MM-dd 00:00:00').format(pickedDate);
        });
      }
    }
  }

  bool _guardando = false;

  void _guardarRegistre() async {
    if (_guardando) return;
    if (_formKey.currentState!.validate()) {
      setState(() {
        _guardando = true;
      });

      final contadorId = int.parse(_contadorIdController.text);
      final uidActual = FirebaseAuth.instance.currentUser?.uid ?? '';

      try {
        final uidContador = await obtenerUidContador(contadorId);

        if (uidContador != null && uidContador != uidActual) {
          // El comptador està asignat a altre usuari
          _mostrarTiraError(
              'Aquest número de comptador ja està assignat a un altre usuari.');
          setState(() {
            _guardando = false;
          });
          return;
        }
        /* if (uidContador == null) {
          // Crear nou contador per a este usuari
          final crearResponse = await http.post(
            Uri.parse('http://192.168.56.1:3000/contadors'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'id': contadorId, 'uid': uidActual}),
          );
*/
        if (uidContador == null) {
          // Mostrar diàleg de confirmació
          final confirmat = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Nou comptador'),
              content: const Text(
                  'Aquest número de comptador no existeix. Vols donar-lo d\'alta?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel·lar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Sí, donar d\'alta'),
                ),
              ],
            ),
          );

          if (confirmat != true) {
            setState(() {
              _guardando = false;
            });
            return; // Cancel·lat per l’usuari
          }

          // Crear nou comptador per a este usuari
          final crearResponse = await http.post(
            Uri.parse('http://192.168.56.1:3000/contadors'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'contador_id': contadorId, 'uid': uidActual}),
          );

          print('Status code crear contador: ${crearResponse.statusCode}');
          print('Body crear contador: ${crearResponse.body}');

          if (crearResponse.statusCode != 201) {
            if (mounted) {
              _mostrarTiraError('Error al crear un nou comptador');
            }
            setState(() {
              _guardando = false;
            });
            return;
          }
          print('⚙️ Comptador creat. Continuant...');
        }

        final nouRegistre = Registre(
          id: widget.registre?.id ?? 0, // Nou si no existeix
          contadorId: contadorId,
          fecha: DateFormat('yyyy-MM-dd HH:mm:ss').parse(_fechaController.text),
          uid: uidActual,
          consumoLitros: double.parse(_consumoLitrosController.text),
          alerta: double.parse(_consumoLitrosController.text) > 100 ? 1 : 0,
        );

        final provider = Provider.of<RegistreProvider>(context, listen: false);

        // Obtenim la llista de registres actuals
        final registresExistents = provider.registres;

        // Comprovem si ja hi ha un registre per al mateix dia (i mateix contador)
        final jaExisteix = registresExistents.any((r) =>
            r.contadorId == nouRegistre.contadorId &&
            widget.registre == null && // Només si és un registre nou
            r.fecha.year == nouRegistre.fecha.year &&
            r.fecha.month == nouRegistre.fecha.month &&
            r.fecha.day == nouRegistre.fecha.day);

        if (jaExisteix) {
          // Mostrem un avís
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Registre duplicat'),
              content: const Text(
                  'Ja existeix un registre per a aquest dia i contador.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('D\'acord'),
                ),
              ],
            ),
          );
          setState(() {
            _guardando = false;
          });
          return; // Parem la funció açí
        }

        if (widget.registre == null) {
          // Alerta per consum elevat per als nous registres
          final registresOrdenats = registresExistents
              .where((r) => r.contadorId == nouRegistre.contadorId)
              .toList()
            ..sort((a, b) => a.fecha.compareTo(b.fecha));

          Registre? registreAnterior;
          for (int i = registresOrdenats.length - 1; i >= 0; i--) {
            if (registresOrdenats[i].fecha.isBefore(nouRegistre.fecha)) {
              registreAnterior = registresOrdenats[i];
              break;
            }
          }

          if (registreAnterior != null) {
            final int dies =
                nouRegistre.fecha.difference(registreAnterior.fecha).inDays;
            if (dies > 0) {
              final double consumDiari =
                  (nouRegistre.consumoLitros - registreAnterior.consumoLitros) /
                      dies;

              if (consumDiari >= 100) {
                await showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Consum elevat'),
                    content: Text(
                      'Consum mitjà de ${consumDiari.toStringAsFixed(2)} L/dia entre '
                      '${DateFormat('dd/MM/yyyy').format(registreAnterior!.fecha)} i '
                      '${DateFormat('dd/MM/yyyy').format(nouRegistre.fecha)}',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Entesos'),
                      ),
                    ],
                  ),
                );
              }
            }
          }
          // Afegir nou registre

          await provider.afegirRegistre(nouRegistre);
        } else {
          // Actualitzar registre existent
          await provider.actualitzarRegistre(nouRegistre);
        }
        if (mounted) {
          setState(() {
            _guardando = false;
          });
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Registre afegit, modificat o eliminat correctament.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.pop(
              context, true); // Tornar a pantalla anterior amb resultat OK
        }
      } catch (e, stackTrace) {
        print('Error al guardar el registre: $e');
        print('StackTrace: $stackTrace');

        if (mounted) {
          _mostrarTiraError('Error al guardar el registre');
        }
      } finally {
        if (mounted) {
          setState(() {
            _guardando = false;
          });
        }
      }
    }
  }

  void _mostrarTiraError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.registre == null ? 'Afegir Registre' : 'Editar Registre'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _contadorIdController,
                decoration: const InputDecoration(
                  labelText: 'ID del Contador',
                  hintText: 'Ex: 123',
                  helperText: 'Introdueix l\'identificador del contador',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Introdueix l\'ID del contador';
                  }

                  final trimmed = value.trim();
                  final parsed = int.tryParse(trimmed);
                  if (parsed == null) {
                    return 'L\'ID ha de ser un número sencer';
                  }
                  if (parsed < 0) {
                    return 'L\'ID no pot ser negatiu';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _fechaController,
                decoration: const InputDecoration(
                  labelText: 'Fecha',
                  hintText: 'Selecciona una data',
                  helperText: 'Obligatori: YYYY-MM-DD',
                ),
                readOnly: true,
                onTap: () => _seleccionarFecha(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecciona la data';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _consumoLitrosController,
                decoration: const InputDecoration(
                  labelText: 'Consum (Litres)',
                  hintText: 'Ex: 125.50',
                  helperText: 'Introdueix el consum en litres',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Introdueix el consum';
                  }
                  final trimmed = value.trim();

                  final parsed = double.tryParse(trimmed);
                  if (parsed == null) {
                    return 'Format no vàlid';
                  }
                  if (parsed < 0) {
                    return 'El consum no pot ser negatiu';
                  }
                  return null;
                },
              ),
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _guardando ? null : _guardarRegistre,
                    child: const Text('Guardar'),
                  ),
                  if (widget.registre !=
                      null) // Mostra el botó eliminar sols al editar
                    const SizedBox(height: 10),
                  if (widget.registre != null)
                    ElevatedButton(
                      onPressed: _confirmarEliminacio,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white),
                      child: const Text('Eliminar'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmarEliminacio() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminació'),
          content: const Text('Estàs segur que vols eliminar aquest registre?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel·lar'),
              onPressed: () {
                Navigator.of(context).pop(); // Tanca el dialeg
              },
            ),
            TextButton(
              child:
                  const Text('Eliminar', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop(); // Tanca el dialeg
                await Provider.of<RegistreProvider>(context, listen: false)
                    .eliminarRegistre(widget.registre!.id);
                Navigator.of(context)
                    .pop(true); // Tanca la pantalla despres de borrar
              },
            ),
          ],
        );
      },
    );
  }
}
