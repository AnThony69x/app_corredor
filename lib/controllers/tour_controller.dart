import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tour.dart';
import '../utils/helpers.dart';

class TourController extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<Tour> _tours = [];
  bool _loading = false;
  String? _error;

  // Getters
  List<Tour> get tours => _tours;
  bool get loading => _loading;
  String? get error => _error;

// Cargar tours del guía actual
Future<void> cargarMisTours() async {
  _setLoading(true);
  try {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }

    final response = await _supabase
        .from('tours')
        .select()
        .eq('id_guia', userId)
        .order('fecha_creacion', ascending: false);

    _tours = (response as List)
        .map((json) => Tour.fromJson(json))
        .toList();
    
    _error = null;
    print('✅ Cargados ${_tours.length} tours');
  } catch (e) {
    _error = 'Error al cargar tours: ${AppHelpers.parseAuthError(e.toString())}';
    print('❌ Error cargando tours: $e');
  } finally {
    _setLoading(false);
    notifyListeners(); // <- Agrega esta línea
  }
}


  // Crear nuevo tour
  Future<bool> crearTour(Tour tour) async {
    _setLoading(true);
    try {
      final response = await _supabase
          .from('tours')
          .insert(tour.toJson())
          .select()
          .single();

      final nuevoTour = Tour.fromJson(response);
      _tours.insert(0, nuevoTour); // Agregar al inicio
      
      _error = null;
      notifyListeners();
      print('✅ Tour creado: ${nuevoTour.titulo}');
      return true;
    } catch (e) {
      _error = 'Error al crear tour: ${AppHelpers.parseAuthError(e.toString())}';
      print('❌ Error creando tour: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Actualizar tour
  Future<bool> actualizarTour(Tour tour) async {
    if (tour.id == null) return false;
    
    _setLoading(true);
    try {
      final response = await _supabase
          .from('tours')
          .update(tour.toJson())
          .eq('id', tour.id!)
          .select()
          .single();

      final tourActualizado = Tour.fromJson(response);
      final index = _tours.indexWhere((t) => t.id == tour.id);
      if (index != -1) {
        _tours[index] = tourActualizado;
      }
      
      _error = null;
      notifyListeners();
      print('✅ Tour actualizado: ${tourActualizado.titulo}');
      return true;
    } catch (e) {
      _error = 'Error al actualizar tour: ${AppHelpers.parseAuthError(e.toString())}';
      print('❌ Error actualizando tour: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Eliminar tour
  Future<bool> eliminarTour(int tourId) async {
    _setLoading(true);
    try {
      await _supabase
          .from('tours')
          .delete()
          .eq('id', tourId);

      _tours.removeWhere((tour) => tour.id == tourId);
      
      _error = null;
      notifyListeners();
      print('✅ Tour eliminado: $tourId');
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

  // Cambiar estado del tour (activo/inactivo)
  Future<bool> cambiarEstadoTour(int tourId, String nuevoEstado) async {
    _setLoading(true);
    try {
      await _supabase
          .from('tours')
          .update({'estado': nuevoEstado})
          .eq('id', tourId);

      final index = _tours.indexWhere((tour) => tour.id == tourId);
      if (index != -1) {
        _tours[index] = _tours[index].copyWith(estado: nuevoEstado);
      }
      
      _error = null;
      notifyListeners();
      print('✅ Estado cambiado: $tourId -> $nuevoEstado');
      return true;
    } catch (e) {
      _error = 'Error al cambiar estado: ${AppHelpers.parseAuthError(e.toString())}';
      print('❌ Error cambiando estado: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Métodos privados
  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  // Limpiar estado
  void limpiar() {
    _tours.clear();
    _error = null;
    _loading = false;
    notifyListeners();
  }

  // Obtener tours por estado
  List<Tour> getToursPorEstado(String estado) {
    return _tours.where((tour) => tour.estado == estado).toList();
  }

  // Obtener estadísticas básicas
  Map<String, int> getEstadisticas() {
    return {
      'total': _tours.length,
      'aprobados': getToursPorEstado('aprobado').length,
      'pendientes': getToursPorEstado('pendiente').length,
      'rechazados': getToursPorEstado('rechazado').length,
      'inactivos': getToursPorEstado('inactivo').length,
    };
  }
}