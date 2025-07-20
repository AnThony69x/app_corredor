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

  List<Tour> get allTours => _allTours;
  Map<String, dynamic> get estadisticas => _estadisticas;
  bool get loading => _loading;
  String? get error => _error;

  // ======================
  // Cargar todos los tours del sistema
  // ======================
  Future<void> cargarTodosLosTours() async {
    _setLoading(true);
    try {
      final response = await _supabase
          .from('tours')
          .select('*')
          .order('fecha_creacion', ascending: false);

      _allTours = (response as List).map((json) => Tour.fromJson(json)).toList();
      _calcularEstadisticas();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar tours: ${AppHelpers.parseAuthError(e.toString())}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ======================
  // Aprobar tour
  // ======================
  Future<bool> aprobarTour(int tourId) async {
    _setLoading(true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');
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
      return true;
    } catch (e) {
      _error = 'Error al aprobar tour: ${AppHelpers.parseAuthError(e.toString())}';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ======================
  // Rechazar tour
  // ======================
  Future<bool> rechazarTour(int tourId) async {
    _setLoading(true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuario no autenticado');
      await _supabase
          .from('tours')
          .update({
            'estado': 'rechazado',
            'fecha_aprobacion': DateTime.now().toIso8601String(),
            'id_admin_revisor': userId,
          })
          .eq('id', tourId);

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
      return true;
    } catch (e) {
      _error = 'Error al rechazar tour: ${AppHelpers.parseAuthError(e.toString())}';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ======================
  // Eliminar tour
  // ======================
  Future<bool> eliminarTour(int tourId) async {
    _setLoading(true);
    try {
      await _supabase.from('tours').delete().eq('id', tourId);
      _allTours.removeWhere((tour) => tour.id == tourId);
      _calcularEstadisticas();
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al eliminar tour: ${AppHelpers.parseAuthError(e.toString())}';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ======================
  // Utilidades de filtro y búsqueda
  // ======================
  List<Tour> getToursPorEstado(String estado) =>
      _allTours.where((tour) => tour.estado == estado).toList();

  List<Tour> getToursPorGuia(String guiaId) =>
      _allTours.where((tour) => tour.idGuia == guiaId).toList();

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

  // ======================
  // Estadísticas
  // ======================
  void _calcularEstadisticas() {
    final total = _allTours.length;
    final aprobados = getToursPorEstado('aprobado').length;
    final pendientes = getToursPorEstado('pendiente').length;
    final rechazados = getToursPorEstado('rechazado').length;
    final inactivos = getToursPorEstado('inactivo').length;

    final Map<String, int> toursPorCategoria = {};
    for (final tour in _allTours) {
      toursPorCategoria[tour.categoria] = (toursPorCategoria[tour.categoria] ?? 0) + 1;
    }

    final ingresosPotenciales = _allTours
        .where((tour) => tour.estado == 'aprobado')
        .fold<double>(0, (sum, tour) => sum + tour.precio);

    _estadisticas = {
      'total': total,
      'aprobados': aprobados,
      'pendientes': pendientes,
      'rechazados': rechazados,
      'inactivos': inactivos,
      'porcentajeAprobacion': total > 0 ? ((aprobados / total) * 100).round() : 0,
      'toursPorCategoria': toursPorCategoria,
      'ingresosPotenciales': ingresosPotenciales,
      'categoriaPopular': toursPorCategoria.isNotEmpty 
          ? toursPorCategoria.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : 'N/A',
    };
  }

  // ======================
  // Métodos privados
  // ======================
  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void limpiar() {
    _allTours.clear();
    _estadisticas.clear();
    _error = null;
    _loading = false;
    notifyListeners();
  }

  // Recargar datos
  Future<void> recargar() async => await cargarTodosLosTours();
}