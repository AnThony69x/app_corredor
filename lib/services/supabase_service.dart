import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  
  // Auth methods
  static User? get currentUser => client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;
  
  // Authentication
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }
  
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  static Future<void> signOut() async {
    await client.auth.signOut();
  }
  
  // User Profile methods
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await client
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }
  
  static Future<bool> createUserProfile({
    required String id,
    required String name,
    required String email,
    required String role,
  }) async {
    try {
      await client.from('users').insert({
        'id': id,
        'name': name,
        'email': email,
        'role': role,
      });
      return true;
    } catch (e) {
      print('Error creating user profile: $e');
      return false;
    }
  }
  
  // Solicitudes de guías
  static Future<bool> createGuideRequest({
    required String userId,
    required String name,
    required String email,
    required String especialidad,
  }) async {
    try {
      await client.from('solicitudes_guia').insert({
        'id_usuario': userId,
        'nombre': name,
        'email': email,
        'especialidad': especialidad,
        'estado': 'pendiente',
      });
      return true;
    } catch (e) {
      print('Error creating guide request: $e');
      return false;
    }
  }
  
  static Future<List<Map<String, dynamic>>> getGuideRequests({
    String estado = 'pendiente',
  }) async {
    try {
      final response = await client
          .from('solicitudes_guia')
          .select()
          .eq('estado', estado)
          .order('fecha_solicitud', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting guide requests: $e');
      return [];
    }
  }
  
  static Future<bool> approveGuideRequest({
    required int requestId,
    required String userId,
    required String especialidad,
    required String adminId,
  }) async {
    try {
      // Transacción simulada
      // 1. Actualizar solicitud
      await client.from('solicitudes_guia').update({
        'estado': 'aprobada',
        'fecha_respuesta': DateTime.now().toIso8601String(),
        'id_admin_revisor': adminId,
      }).eq('id', requestId);
      
      // 2. Cambiar rol del usuario
      await client.from('users').update({
        'role': 'guide'
      }).eq('id', userId);
      
      // 3. Eliminar de turista
      await client.from('turista').delete().eq('id_usuario', userId);
      
      // 4. Insertar en guía
      await client.from('guia').insert({
        'id_usuario': userId,
        'especialidad': especialidad,
      });
      
      return true;
    } catch (e) {
      print('Error approving guide request: $e');
      return false;
    }
  }
  
  static Future<bool> rejectGuideRequest({
    required int requestId,
    required String motivo,
    required String adminId,
  }) async {
    try {
      await client.from('solicitudes_guia').update({
        'estado': 'rechazada',
        'motivo_rechazo': motivo,
        'fecha_respuesta': DateTime.now().toIso8601String(),
        'id_admin_revisor': adminId,
      }).eq('id', requestId);
      return true;
    } catch (e) {
      print('Error rejecting guide request: $e');
      return false;
    }
  }
  
  // Specialized profiles
  static Future<bool> createTouristProfile(String userId) async {
    try {
      await client.from('turista').insert({
        'id_usuario': userId,
      });
      return true;
    } catch (e) {
      print('Error creating tourist profile: $e');
      return false;
    }
  }
  
  static Future<bool> createGuideProfile({
    required String userId,
    required String especialidad,
  }) async {
    try {
      await client.from('guia').insert({
        'id_usuario': userId,
        'especialidad': especialidad,
      });
      return true;
    } catch (e) {
      print('Error creating guide profile: $e');
      return false;
    }
  }
  
  // Check pending requests
  static Future<Map<String, dynamic>?> getPendingGuideRequest(String userId) async {
    try {
      final response = await client
          .from('solicitudes_guia')
          .select('estado, especialidad')
          .eq('id_usuario', userId)
          .eq('estado', 'pendiente')
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error checking pending request: $e');
      return null;
    }
  }
}