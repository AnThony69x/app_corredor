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

  // Datos del guía (solo para consultas con JOIN)
  final String? guiaNombre;
  final String? guiaEmail;

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
    this.guiaNombre,
    this.guiaEmail,
  });

  // Convertir de JSON (desde Supabase, con JOIN de guía)
  factory Tour.fromJson(Map<String, dynamic> json) {
    return Tour(
      id: _parseInt(json['id']),
      idGuia: json['id_guia']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      precio: _parseDouble(json['precio']),
      duracionHoras: _parseInt(json['duracion_horas']),
      ubicacion: json['ubicacion']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? '',
      estado: json['estado']?.toString() ?? 'pendiente',
      fechaCreacion: DateTime.parse(json['fecha_creacion'].toString()),
      fechaAprobacion: json['fecha_aprobacion'] != null && json['fecha_aprobacion'].toString().isNotEmpty
          ? DateTime.parse(json['fecha_aprobacion'].toString())
          : null,
      idAdminRevisor: json['id_admin_revisor']?.toString(),
      maxPersonas: _parseInt(json['max_personas']),
      incluye: _parseStringList(json['incluye']),
      noIncluye: _parseStringList(json['no_incluye']),
      requisitos: json['requisitos']?.toString(),
      puntoEncuentro: json['punto_encuentro']?.toString() ?? '',
      imagenes: _parseStringList(json['imagenes']),
      guiaNombre: json['guia'] != null ? json['guia']['name']?.toString() : null,
      guiaEmail: json['guia'] != null ? json['guia']['email']?.toString() : null,
    );
  }

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
      // No incluyas guiaNombre/guiaEmail aquí; solo en fromJson para la vista
    };
  }

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
    String? guiaNombre,
    String? guiaEmail,
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
      guiaNombre: guiaNombre ?? this.guiaNombre,
      guiaEmail: guiaEmail ?? this.guiaEmail,
    );
  }

  bool get estaAprobado => estado == 'aprobado';
  bool get estaPendiente => estado == 'pendiente';
  bool get estaRechazado => estado == 'rechazado';
  bool get estaActivo => estado == 'aprobado';

  String get precioFormateado => '\$${precio.toStringAsFixed(2)}';
  String get duracionFormateada => '${duracionHoras}h';

  // Métodos auxiliares para parsear datos
  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String && value.isNotEmpty) {
      // Si viene como un string tipo JSON o texto separado por comas
      try {
        // Si viene como JSON array en string
        if (value.trim().startsWith('[') && value.trim().endsWith(']')) {
          final arr = value.trim().substring(1, value.length - 1).split(',');
          return arr.map((e) => e.replaceAll('"', '').replaceAll("'", '').trim())
                    .where((e) => e.isNotEmpty).toList();
        }
        // Si viene separado por comas
        return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      } catch (_) {
        return [value];
      }
    }
    return [];
  }
}