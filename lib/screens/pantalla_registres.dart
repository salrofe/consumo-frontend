import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasca_comarques/model/registre.dart';
import 'package:tasca_comarques/providers/registre_provider.dart';
import 'package:tasca_comarques/screens/pantalla_afegirRegistre.dart';
import 'package:tasca_comarques/screens/pantalla_grafics.dart';

class PantallaRegistres extends StatefulWidget {
  const PantallaRegistres({super.key});

  @override
  State<PantallaRegistres> createState() => _PantallaRegistresState();
}

class _PantallaRegistresState extends State<PantallaRegistres> {
  List<Registre> _registresFiltrats = [];

  final TextEditingController _filtroContadorController =
      TextEditingController();
  String _filtroAlerta = 'Tots';

  static const String adminUid = 'HdXHS40ngcRZVJ1NsuEQPBunYx03';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _carregarIAplicar());
  }

  Future<void> _carregarIAplicar() async {
    final provider = Provider.of<RegistreProvider>(context, listen: false);
    await provider.carregarRegistres();

    _aplicarFiltres();
  }

  void _aplicarFiltres() {
    final provider = Provider.of<RegistreProvider>(context, listen: false);
    final registres = provider.registres;

    final filtreContador = _filtroContadorController.text.trim();
    final numFiltreContador = int.tryParse(filtreContador);
    final filtreAlerta = _filtroAlerta;

    setState(() {
      _registresFiltrats = registres.where((r) {
        final coincideixContador = filtreContador.isEmpty ||
            (numFiltreContador != null && r.contadorId == numFiltreContador);

        final coincideixAlerta = filtreAlerta == 'Tots' ||
            (filtreAlerta == 'Amb alerta' && r.alerta == 1) ||
            (filtreAlerta == 'Sense alerta' && r.alerta == 0);

        return coincideixContador && coincideixAlerta;
      }).toList();
    });
  }

  Future<void> _updateRegistres() async {
    final provider = Provider.of<RegistreProvider>(context, listen: false);
    await provider.carregarRegistres();
    _aplicarFiltres();
  }

  @override
  Widget build(BuildContext context) {
    final registreProvider = Provider.of<RegistreProvider>(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Column(
          children: [
            Container(
              color: Colors.blue,
              height: 60,
              alignment: Alignment.center,
              child: const Text(
                'Registres',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // botons
            Container(
              color: Colors.grey.shade200,
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Botó: Comptadors
                  TextButton.icon(
                    icon: const Icon(Icons.format_list_numbered),
                    label: const Text('Per comptador'),
                    onPressed: () {},
                  ),
                  // Botó: Gràfica
                  TextButton.icon(
                    icon: const Icon(Icons.show_chart),
                    label: const Text('Gràfica'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PantallaGrafics(registres: _registresFiltrats),
                        ),
                      );
                    },
                  ),
                  // Botó: Tancar sessió
                  TextButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Tancar Sessió'),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: registreProvider.loading
          ? const Center(child: CircularProgressIndicator())
          : registreProvider.registres.isEmpty
              ? const Center(child: Text('No hi ha registres'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _filtroContadorController,
                            decoration: const InputDecoration(
                              labelText: 'Filtra per ID de contador',
                              prefixIcon: Icon(Icons.filter_alt),
                            ),
                            onChanged: (_) => _aplicarFiltres(),
                          ),
                          const SizedBox(height: 10),
                          DropdownButton<String>(
                            value: _filtroAlerta,
                            isExpanded: true,
                            items: ['Tots', 'Amb alerta', 'Sense alerta']
                                .map((valor) {
                              return DropdownMenuItem(
                                value: valor,
                                child: Text(valor),
                              );
                            }).toList(),
                            onChanged: (nouValor) {
                              setState(() {
                                _filtroAlerta = nouValor!;
                              });
                              _aplicarFiltres();
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _registresFiltrats.length,
                        itemBuilder: (context, index) {
                          final r = _registresFiltrats[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            child: ListTile(
                              leading: const Icon(Icons.water_drop,
                                  color: Colors.blue),
                              title: Text('${r.fecha} - ${r.consumoLitros} L',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('🆔 ID: ${r.id}'),
                                  Text('🔢 Contador: ${r.contadorId}'),
                                  Text(r.alerta == 1
                                      ? '⚠️ Alerta activada'
                                      : '✅ Sense alerta'),
                                ],
                              ),
                              onTap: () async {
                                final resultat = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PantallaAfegirRegistre(registre: r),
                                  ),
                                );

                                if (resultat == true) {
                                  final messenger = ScaffoldMessenger.of(
                                      context); // guardem el context abans del await
                                  await _updateRegistres();
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Registre afegit, modificat o eliminat correctament.'),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final resultat = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PantallaAfegirRegistre(),
            ),
          );

          if (resultat == true && mounted) {
            await _updateRegistres();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Afegir Registre'),
      ),
    );
  }
}
