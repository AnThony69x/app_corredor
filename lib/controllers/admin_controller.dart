import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tour.dart';
import '../utils/helpers.dart';

class AdminTourController extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<Tour> _allTours = [];
  Map<String, dynamic> _estadisticas = {};
  bool _loading = false;
  String? _error;

  // Getters
  List<Tour> get allTours => _allTours;
  Map<String, dynamic> get estadisticas => _estadisticas;
  bool get loading => _loading;
  String? get error => _error;

  // Cargar todos los tours del sistema
  Future<void> cargarTodosLosTours() async {
    _setLoading(true);
    try {
      final response = await _supabase
          .from('tours')
          .select('''
            *,
            guia:id_guia (
              nombre_guia,
              users:id_usuario (
                name,
                email
              )
            )
          ''')
          .order('fecha_creacion', ascending: false);

      _allTours = (response as List)
          .map((json) => Tour.fromJson(json))
          .toList();
      
      _calcularEstadisticas();
      _error = null;
      print('✅ Admin: Cargados ${_allTours.length} tours');
    } catch (e) {
      _error = 'Error al cargar tours: ${AppHelpers.parseAuthError(e.toString())}';
      print('❌ Error cargando tours admin: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Aprobar tour
  Future<bool> aprobarTour(int tourId, {String? comentarios}) async {
    _setLoading(true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      await _supabase
          .from('tours')
          .update({
            'estado': 'aprobado',
            'fecha_aprobacion': DateTime.now().toIso8601String(),
            'id_admin_revisor': userId,
          })
          .eq('id', tourId);

      // Actualizar en la lista local
      final index = _allTours.indexWhere((tour) => tour.id == tourId);
      if (index != -1) {
        _allTours[index] = _allTours[index].copyWith(
          estado: 'aprobado',
          fechaAprobacion: DateTime.now(),
          idAdminRevisor: userId,
        );
      }

      _calcularEstadisticas();
      _error = null;
      notifyListeners();
      print('✅ Tour aprobado: $tourId');
      return true;
    } catch (e) {
      _error = 'Error al aprobar tour: ${AppHelpers.parseAuthError(e.toString())}';
      print('❌ Error aprobando tour: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Rechazar tour
  Future<bool> rechazarTour(int tourId, {String? motivo}) async {
    _setLoading(true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      await _supabase
          .from('tours')
          .update({
            'estado': 'rechazado',
            'fecha_aprobacion': DateTime.now().toIso8601String(),
            'id_admin_revisor': userId,
          })
          .eq('id', tourId);

      // Actualizar en la lista local
      final index = _allTours.indexWhere((tour) => tour.id == tourId);
      if (index != -1) {
        _allTours[index] = _allTours[index].copyWith(
          estado: 'rechazado',
          fechaAprobacion: DateTime.now(),
          idAdminRevisor: userId,
        );
      }

      _calcularEstadisticas();
      _error = null;
      notifyListeners();
      print('✅ Tour rechazado: $tourId');
      return true;
    } catch (e) {
      _error = 'Error al rechazar tour: ${AppHelpers.parseAuthError(e.toString())}';
      print('❌ Error rechazando tour: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Eliminar tour (solo admin)
  Future<bool> eliminarTour(int tourId) async {
    _setLoading(true);
    try {
      await _supabase
          .from('tours')
          .delete()
          .eq('id', tourId);

      _allTours.removeWhere((tour) => tour.id == tourId);
      _calcularEstadisticas();
      _error = null;
      notifyListeners();
      print('✅ Tour eliminado por admin: $tourId');
      return true;
    } catch (e) {
      _error = 'Error al eliminar tour: ${AppHelpers.parseAuthError(e.toString())}';
      print('❌ Error eliminando tour: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Obtener tours por estado
  List<Tour> getToursPorEstado(String estado) {
    return _allTours.where((tour) => tour.estado == estado).toList();
  }

  // Obtener tours por guía
  List<Tour> getToursPorGuia(String guiaId) {
    return _allTours.where((tour) => tour.idGuia == guiaId).toList();
  }

  // Buscar tours por texto
  List<Tour> buscarTours(String query) {
    if (query.isEmpty) return _allTours;
    
    final queryLower = query.toLowerCase();
    return _allTours.where((tour) =>
      tour.titulo.toLowerCase().contains(queryLower) ||
      tour.descripcion.toLowerCase().contains(queryLower) ||
      tour.ubicacion.toLowerCase().contains(queryLower) ||
      tour.categoria.toLowerCase().contains(queryLower)
    ).toList();
  }

  // Filtrar tours por múltiples criterios
  List<Tour> filtrarTours({
    String? estado,
    String? categoria,
    double? precioMin,
    double? precioMax,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
  }) {
    var tours = List<Tour>.from(_allTours);

    if (estado != null && estado != 'todos') {
      tours = tours.where((tour) => tour.estado == estado).toList();
    }

    if (categoria != null && categoria != 'todas') {
      tours = tours.where((tour) => tour.categoria == categoria).toList();
    }

    if (precioMin != null) {
      tours = tours.where((tour) => tour.precio >= precioMin).toList();
    }

    if (precioMax != null) {
      tours = tours.where((tour) => tour.precio <= precioMax).toList();
    }

    if (fechaDesde != null) {
      tours = tours.where((tour) => 
        tour.fechaCreacion.isAfter(fechaDesde.subtract(const Duration(days: 1)))
      ).toList();
    }

    if (fechaHasta != null) {
      tours = tours.where((tour) => 
        tour.fechaCreacion.isBefore(fechaHasta.add(const Duration(days: 1)))
      ).toList();
    }

    return tours;
  }

  // Calcular estadísticas
  void _calcularEstadisticas() {
    final total = _allTours.length;
    final aprobados = getToursPorEstado('aprobado').length;
    final pendientes = getToursPorEstado('pendiente').length;
    final rechazados = getToursPorEstado('rechazado').length;
    final inactivos = getToursPorEstado('inactivo').length;

    // Estadísticas por categoría
    final Map<String, int> toursPorCategoria = {};
    for (final tour in _allTours) {
      toursPorCategoria[tour.categoria] = (toursPorCategoria[tour.categoria] ?? 0) + 1;
    }

    // Ingresos potenciales
    final ingresosPotenciales = _allTours
        .where((tour) => tour.estado == 'aprobado')
        .fold<double>(0, (sum, tour) => sum + tour.precio);

    // Tours por mes (últimos 12 meses)
    final Map<String, int> toursPorMes = {};
    final ahora = DateTime.now();
    for (int i = 11; i >= 0; i--) {
      final mes = DateTime(ahora.year, ahora.month - i);
      final mesKey = '${mes.year}-${mes.month.toString().padLeft(2, '0')}';
      toursPorMes[mesKey] = _allTours.where((tour) => 
        tour.fechaCreacion.year == mes.year && 
        tour.fechaCreacion.month == mes.month
      ).length;
    }

    _estadisticas = {
      'total': total,
      'aprobados': aprobados,
      'pendientes': pendientes,
      'rechazados': rechazados,
      'inactivos': inactivos,
      'porcentajeAprobacion': total > 0 ? ((aprobados / total) * 100).round() : 0,
      'toursPorCategoria': toursPorCategoria,
      'ingresosPotenciales': ingresosPotenciales,
      'toursPorMes': toursPorMes,
      'categoriaPopular': toursPorCategoria.isNotEmpty 
          ? toursPorCategoria.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : 'N/A',
    };
  }

  // Obtener estadísticas de un guía específico
  Map<String, dynamic> getEstadisticasGuia(String guiaId) {
    final toursGuia = getToursPorGuia(guiaId);
    final total = toursGuia.length;
    final aprobados = toursGuia.where((t) => t.estado == 'aprobado').length;
    final pendientes = toursGuia.where((t) => t.estado == 'pendiente').length;
    final rechazados = toursGuia.where((t) => t.estado == 'rechazado').length;

    return {
      'total': total,
      'aprobados': aprobados,
      'pendientes': pendientes,
      'rechazados': rechazados,
      'porcentajeAprobacion': total > 0 ? ((aprobados / total) * 100).round() : 0,
    };
  }

  // Métodos privados
  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  // Limpiar estado
  void limpiar() {
    _allTours.clear();
    _estadisticas.clear();
    _error = null;
    _loading = false;
    notifyListeners();
  }

  // Recargar datos
  Future<void> recargar() async {
    await cargarTodosLosTours();
  }
}