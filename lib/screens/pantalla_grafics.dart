import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../model/registre.dart';

/*class PantallaGrafics extends StatelessWidget {
  final List<Registre> registres;
  const PantallaGrafics({Key? key, required this.registres}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // final registres = Provider.of<RegistreProvider>(context).registres;

    if (registres.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Gràfica de consum')),
        body: Center(child: Text('No hi ha registres per mostrar')),
      );
    }

    // Ordenar por fecha
    final dadesOrdenades = [...registres]
      ..sort((a, b) => a.fecha.compareTo(b.fecha));

    // Crear puntos para la gráfica
    final List<FlSpot> punts = [];
    for (int i = 0; i < dadesOrdenades.length; i++) {
      final consum = dadesOrdenades[i].consumoLitros.toDouble();
      punts.add(FlSpot(i.toDouble(), consum));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Gràfica de consum')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: LineChart(
          LineChartData(
            titlesData: FlTitlesData(show: false),
            borderData: FlBorderData(show: true),
            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                spots: punts,
                barWidth: 3,
                color: Colors.blue,
                dotData: FlDotData(show: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/

/*
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:tasca_comarques/model/registre.dart';
import 'package:intl/intl.dart';

class PantallaGrafics extends StatelessWidget {
  final List<Registre> registres;

  const PantallaGrafics({super.key, required this.registres});

  @override
  Widget build(BuildContext context) {
    // Ordenamos por fecha
    registres.sort((a, b) => a.fecha.compareTo(b.fecha));

    // Generamos los puntos del gráfico
    List<FlSpot> spots = [];
    List<String> dates = [];

    for (int i = 0; i < registres.length; i++) {
      spots.add(FlSpot(i.toDouble(), registres[i].consumoLitros.toDouble()));
      dates.add(DateFormat('dd/MM').format(registres[i].fecha));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Gràfica de Consums')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: registres.isEmpty
            ? const Center(child: Text('No hi ha registres per mostrar'))
            : LineChart(
                LineChartData(
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, _) {
                          return Text('${value.toInt()} L',
                              style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, _) {
                          int index = value.toInt();
                          if (index >= 0 && index < dates.length) {
                            return Text(dates[index],
                                style: const TextStyle(fontSize: 10));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  gridData: FlGridData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: Colors.blue,
                      dotData: FlDotData(show: true),
                      spots: spots,
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.black87,
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((spot) {
                          final fecha = dates[spot.x.toInt()];
                          final litros = spot.y;
                          return LineTooltipItem(
                            '$fecha\n${litros.toStringAsFixed(1)} L',
                            const TextStyle(color: Colors.white),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
*/

import 'package:intl/intl.dart';

class PantallaGrafics extends StatefulWidget {
  final List<Registre> registres;

  const PantallaGrafics({super.key, required this.registres});

  @override
  State<PantallaGrafics> createState() => _PantallaGraficsState();
}

class _PantallaGraficsState extends State<PantallaGrafics> {
  bool mostrarLinea = true; // Para alternar entre línea y barras

  @override
  Widget build(BuildContext context) {
    final registres = widget.registres;
    registres.sort((a, b) => a.fecha.compareTo(b.fecha));

    if (registres.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gràfica de Consums')),
        body: const Center(child: Text('No hi ha registres per mostrar')),
      );
    }

    List<FlSpot> spots = [];
    List<BarChartGroupData> bars = [];
    List<String> dates = [];

    double valorMaximo = registres
        .map((r) => r.consumoLitros.toDouble())
        .reduce((a, b) => a > b ? a : b);

    for (int i = 0; i < registres.length; i++) {
      double valor = registres[i].consumoLitros.toDouble();
      spots.add(FlSpot(i.toDouble(), valor));
      bars.add(
        BarChartGroupData(x: i, barRods: [
          BarChartRodData(toY: valor, color: Colors.green),
        ]),
      );
      dates.add(DateFormat('dd/MM').format(registres[i].fecha));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gràfica de Consums'),
        actions: [
          IconButton(
            icon: Icon(mostrarLinea ? Icons.bar_chart : Icons.show_chart),
            tooltip: 'Canviar tipus de gràfica',
            onPressed: () {
              setState(() {
                mostrarLinea = !mostrarLinea;
              });
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: registres.isEmpty
            ? const Center(child: Text('No hi ha registres per mostrar'))
            : mostrarLinea
                ? LineChart(
                    LineChartData(
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, _) => Text(
                              '${value.toInt()} L',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, _) {
                              int index = value.toInt();
                              return index >= 0 && index < dates.length
                                  ? Text(dates[index],
                                      style: const TextStyle(fontSize: 10))
                                  : const Text('');
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true),
                      gridData: FlGridData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          color: Colors.blue,
                          dotData: FlDotData(show: true),
                          spots: spots,
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: Colors.black87,
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final fecha = dates[spot.x.toInt()];
                              final litros = spot.y;
                              return LineTooltipItem(
                                '$fecha\n${litros.toStringAsFixed(1)} L',
                                const TextStyle(color: Colors.white),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      maxY: valorMaximo + 25,
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, _) => Text(
                              '${value.toInt()} L',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, _) {
                              int index = value.toInt();
                              return index >= 0 && index < dates.length
                                  ? Text(dates[index],
                                      style: const TextStyle(fontSize: 10))
                                  : const Text('');
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true),
                      gridData: FlGridData(show: true),
                      barGroups: bars,
                    ),
                  ),
      ),
    );
  }
}
