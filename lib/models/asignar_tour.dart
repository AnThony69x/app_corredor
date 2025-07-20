class AsignarTour {
  final int? id;
  final String idTurista;
  final int idTour;
  final DateTime fecha;
  final String estado;
  final DateTime createdAt;
  final DateTime updatedAt;

  AsignarTour({
    this.id,
    required this.idTurista,
    required this.idTour,
    required this.fecha,
    required this.estado,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AsignarTour.fromJson(Map<String, dynamic> json) {
    return AsignarTour(
      id: json['id'] as int?,
      idTurista: json['id_turista'] as String,
      idTour: json['id_tour'] as int,
      fecha: DateTime.parse(json['fecha']),
      estado: json['estado'] as String,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_turista': idTurista,
      'id_tour': idTour,
      'fecha': fecha.toIso8601String(),
      'estado': estado,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}