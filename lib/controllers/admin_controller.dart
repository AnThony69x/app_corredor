import 'package:supabase_flutter/supabase_flutter.dart';

class AsignarTourController {
  final _supabase = Supabase.instance.client;

  Future<bool> asignarTourAlTurista({required String idTurista, required int idTour}) async {
    // Verifica si el turista ya tiene un tour activo
    final existing = await _supabase
        .from('asignar_tours')
        .select()
        .eq('id_turista', idTurista)
        .eq('estado', 'activo')
        .maybeSingle();

    if (existing != null) {
      // Ya tiene un tour activo
      return false;
    }

    // Asigna el tour
    final now = DateTime.now();
    await _supabase
        .from('asignar_tours')
        .insert({
          'id_turista': idTurista,
          'id_tour': idTour,
          'fecha': now.toIso8601String(),
          'estado': 'activo',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        });

    return true;
  }
}