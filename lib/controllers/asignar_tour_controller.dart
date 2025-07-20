import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AsignacionTourController extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _asignados = [];

  bool get loading => _loading;
  String? get error => _error;
  List<Map<String, dynamic>> get asignados => _asignados;

  // ======================
  // Asignar usuario al tour (turista se asigna)
  // ======================
  Future<bool> asignarUsuarioATour({required int tourId, required String userId}) async {
    _setLoading(true);
    try {
      // Verifica que no esté asignado ya
      final existe = await _supabase
        .from('asignar_tours')
        .select()
        .eq('tour_id', tourId)
        .eq('user_id', userId)
        .maybeSingle();

      if (existe != null) {
        _error = 'Ya estás asignado a este tour.';
        _setLoading(false);
        return false;
      }

      await _supabase
        .from('asignar_tours')
        .insert({'tour_id': tourId, 'user_id': userId});

      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al asignar: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ======================
  // Obtener turistas asignados a un tour
  // ======================
  Future<void> cargarAsignados(int tourId) async {
    _setLoading(true);
    try {
      final response = await _supabase
        .from('asignar_tours')
        .select('user_id, usuario:users(name, email)')
        .eq('tour_id', tourId);

      // response es List<Map>
      _asignados = (response as List).map<Map<String, dynamic>>((json) {
        return {
          'user_id': json['user_id'],
          'nombre': json['usuario']?['name'] ?? 'Sin nombre',
          'email': json['usuario']?['email'] ?? 'Sin email',
        };
      }).toList();

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Error al cargar asignados: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ======================
  // Cancelar asignación (turista cancela su asignación)
  // ======================
  Future<bool> cancelarAsignacion({required int tourId, required String userId}) async {
    _setLoading(true);
    try {
      await _supabase
        .from('asignar_tours')
        .delete()
        .eq('tour_id', tourId)
        .eq('user_id', userId);

      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al cancelar asignación: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void limpiar() {
    _asignados.clear();
    _error = null;
    _loading = false;
    notifyListeners();
  }
}