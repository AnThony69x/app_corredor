class Tour {
  final int? id;
  final String idGuia;
  final String titulo;
  final String descripcion;
  final double precio;
  final int duracionHoras;
  final String ubicacion;
  final String categoria;
  final String estado; // pendiente, aprobado, rechazado, inactivo
  final DateTime fechaCreacion;
  final DateTime? fechaAprobacion;
  final String? idAdminRevisor;
  final int maxPersonas;
  final List<String> incluye;
  final List<String> noIncluye;
  final String? requisitos;
  final String puntoEncuentro;
  final List<String> imagenes;

  const Tour({
    this.id,
    required this.idGuia,
    required this.titulo,
    required this.descripcion,
    required this.precio,
    required this.duracionHoras,
    required this.ubicacion,
    required this.categoria,
    this.estado = 'pendiente',
    required this.fechaCreacion,
    this.fechaAprobacion,
    this.idAdminRevisor,
    required this.maxPersonas,
    required this.incluye,
    required this.noIncluye,
    this.requisitos,
    required this.puntoEncuentro,
    required this.imagenes,
  });

  // Convertir de JSON (desde Supabase)
  factory Tour.fromJson(Map<String, dynamic> json) {
    return Tour(
      id: json['id'],
      idGuia: json['id_guia'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      precio: double.parse(json['precio'].toString()),
      duracionHoras: json['duracion_horas'],
      ubicacion: json['ubicacion'],
      categoria: json['categoria'],
      estado: json['estado'] ?? 'pendiente',
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
      fechaAprobacion: json['fecha_aprobacion'] != null 
          ? DateTime.parse(json['fecha_aprobacion']) 
          : null,
      idAdminRevisor: json['id_admin_revisor'],
      maxPersonas: json['max_personas'],
      incluye: List<String>.from(json['incluye'] ?? []),
      noIncluye: List<String>.from(json['no_incluye'] ?? []),
      requisitos: json['requisitos'],
      puntoEncuentro: json['punto_encuentro'],
      imagenes: List<String>.from(json['imagenes'] ?? []),
    );
  }

  // Convertir a JSON (para Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id_guia': idGuia,
      'titulo': titulo,
      'descripcion': descripcion,
      'precio': precio,
      'duracion_horas': duracionHoras,
      'ubicacion': ubicacion,
      'categoria': categoria,
      'estado': estado,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_aprobacion': fechaAprobacion?.toIso8601String(),
      'id_admin_revisor': idAdminRevisor,
      'max_personas': maxPersonas,
      'incluye': incluye,
      'no_incluye': noIncluye,
      'requisitos': requisitos,
      'punto_encuentro': puntoEncuentro,
      'imagenes': imagenes,
    };
  }

  // Método para copiar con cambios
  Tour copyWith({
    int? id,
    String? idGuia,
    String? titulo,
    String? descripcion,
    double? precio,
    int? duracionHoras,
    String? ubicacion,
    String? categoria,
    String? estado,
    DateTime? fechaCreacion,
    DateTime? fechaAprobacion,
    String? idAdminRevisor,
    int? maxPersonas,
    List<String>? incluye,
    List<String>? noIncluye,
    String? requisitos,
    String? puntoEncuentro,
    List<String>? imagenes,
  }) {
    return Tour(
      id: id ?? this.id,
      idGuia: idGuia ?? this.idGuia,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      precio: precio ?? this.precio,
      duracionHoras: duracionHoras ?? this.duracionHoras,
      ubicacion: ubicacion ?? this.ubicacion,
      categoria: categoria ?? this.categoria,
      estado: estado ?? this.estado,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaAprobacion: fechaAprobacion ?? this.fechaAprobacion,
      idAdminRevisor: idAdminRevisor ?? this.idAdminRevisor,
      maxPersonas: maxPersonas ?? this.maxPersonas,
      incluye: incluye ?? this.incluye,
      noIncluye: noIncluye ?? this.noIncluye,
      requisitos: requisitos ?? this.requisitos,
      puntoEncuentro: puntoEncuentro ?? this.puntoEncuentro,
      imagenes: imagenes ?? this.imagenes,
    );
  }

  // Getters útiles
  bool get estaAprobado => estado == 'aprobado';
  bool get estaPendiente => estado == 'pendiente';
  bool get estaRechazado => estado == 'rechazado';
  bool get estaActivo => estado == 'aprobado';
  
  String get precioFormateado => '\$${precio.toStringAsFixed(2)}';
  String get duracionFormateada => '${duracionHoras}h';
}