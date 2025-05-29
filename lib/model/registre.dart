class Registre {
  final int id;
  final int contadorId;
  final DateTime fecha;
  final String uid;
  final double consumoLitros;
  final int alerta;

  Registre({
    required this.id,
    required this.contadorId,
    required this.fecha,
    required this.uid,
    required this.consumoLitros,
    required this.alerta,
  });

  factory Registre.fromJson(Map<String, dynamic> json) {
    return Registre(
      id: json['id'],
      contadorId: json['contador_id'],
      fecha: DateTime.parse(json['fecha']),
      uid: json['uid'] ?? 'sense-uid',
      consumoLitros: json['consumo_litros'].toDouble(),
      alerta: json['alerta'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contador_id': contadorId,
      'fecha': fecha.toIso8601String(),
      'uid': uid,
      'consumo_litros': consumoLitros,
      'alerta': alerta,
    };
  }
}
