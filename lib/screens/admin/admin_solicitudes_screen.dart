import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/helpers.dart';

class AdminSolicitudesScreen extends StatefulWidget {
  const AdminSolicitudesScreen({super.key});

  @override
  State<AdminSolicitudesScreen> createState() => _AdminSolicitudesScreenState();
}

class _AdminSolicitudesScreenState extends State<AdminSolicitudesScreen> {
  List<Map<String, dynamic>> solicitudes = [];
  bool _loading = true;
  String filtroEstado = 'pendiente';

  @override
  void initState() {
    super.initState();
    _cargarSolicitudes();
  }

  Future<void> _cargarSolicitudes() async {
    setState(() => _loading = true);
    try {
      print('🔍 Cargando solicitudes con estado: $filtroEstado');
      
      final response = await Supabase.instance.client
          .from('solicitudes_guia')
          .select()
          .eq('estado', filtroEstado)
          .order('fecha_solicitud', ascending: false);

      setState(() {
        solicitudes = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
      
      _debugPrintSolicitudes();
    } catch (e) {
      setState(() => _loading = false);
      AppHelpers.showErrorSnackBar(context, 'Error al cargar solicitudes: $e');
      print('❌ Error cargando solicitudes: $e');
    }
  }

  void _debugPrintSolicitudes() {
    print('📋 DEBUG - Estado actual: $filtroEstado');
    print('📋 DEBUG - Solicitudes en lista: ${solicitudes.length}');
    for (var sol in solicitudes) {
      print('   - ${sol['nombre']}: ${sol['estado']} (ID: ${sol['id']})');
    }
  }

  Future<void> _aprobarSolicitud(Map<String, dynamic> solicitud) async {
    // Mostrar confirmación
    final confirmed = await AppHelpers.showConfirmationDialog(
      context,
      title: 'Aprobar Solicitud',
      message: '¿Estás seguro de aprobar la solicitud de ${solicitud['nombre']} como guía de ${solicitud['especialidad']}?',
      confirmText: 'Aprobar',
      confirmColor: Colors.green,
    );

    if (!confirmed) return;

    AppHelpers.showLoadingDialog(context, message: 'Aprobando solicitud...');

    try {
      final userId = solicitud['id_usuario'];
      final especialidad = solicitud['especialidad'];
      final adminId = Supabase.instance.client.auth.currentUser?.id;
      final solicitudId = solicitud['id'];

      print('🔄 Iniciando aprobación para usuario: $userId');

      // 1. Actualizar estado de la solicitud
      print('📝 Actualizando estado de solicitud...');
      await Supabase.instance.client
          .from('solicitudes_guia')
          .update({
            'estado': 'aprobada',
            'fecha_respuesta': DateTime.now().toIso8601String(),
            'id_admin_revisor': adminId,
          })
          .eq('id', solicitudId);

      // 2. Cambiar rol del usuario de tourist a guide
      print('👤 Cambiando rol de usuario...');
      await Supabase.instance.client
          .from('users')
          .update({'role': 'guide'})
          .eq('id', userId);

      // 3. Eliminar de tabla turista
      print('🗑️ Eliminando de tabla turista...');
      await Supabase.instance.client
          .from('turista')
          .delete()
          .eq('id_usuario', userId);

      // 4. Insertar en tabla guia (con verificación para evitar duplicados)
      print('➕ Insertando en tabla guía...');
      try {
        await Supabase.instance.client
            .from('guia')
            .insert({
              'id_usuario': userId,
              'especialidad': especialidad,
            });
        print('✅ Guía insertado correctamente');
      } catch (e) {
        // Si ya existe, actualizar en lugar de insertar
        if (e.toString().contains('duplicate key') || 
            e.toString().contains('23505') || 
            e.toString().contains('guia_pkey')) {
          print('🔄 Guía ya existe, actualizando especialidad...');
          await Supabase.instance.client
              .from('guia')
              .update({'especialidad': especialidad})
              .eq('id_usuario', userId);
          print('✅ Especialidad actualizada correctamente');
        } else {
          throw e; // Si es otro error, relanzarlo
        }
      }

      AppHelpers.hideLoadingDialog(context);
      AppHelpers.showSuccessSnackBar(context, 'Solicitud aprobada correctamente');
      
      // 🔥 DELAY AGREGADO AQUÍ:
      await Future.delayed(const Duration(milliseconds: 700));
      
      // Recargar solicitudes
      await _cargarSolicitudes();
      
      print('✅ Aprobación completada exitosamente');

    } catch (e) {
      AppHelpers.hideLoadingDialog(context);
      AppHelpers.showErrorSnackBar(context, 'Error al aprobar solicitud: ${AppHelpers.parseAuthError(e.toString())}');
      print('❌ Error detallado en aprobación: $e');
    }
  }

  Future<void> _rechazarSolicitud(Map<String, dynamic> solicitud, String motivo) async {
    AppHelpers.showLoadingDialog(context, message: 'Rechazando solicitud...');

    try {
      final adminId = Supabase.instance.client.auth.currentUser?.id;
      final solicitudId = solicitud['id'];

      print('🔄 Rechazando solicitud ID: $solicitudId');

      await Supabase.instance.client
          .from('solicitudes_guia')
          .update({
            'estado': 'rechazada',
            'motivo_rechazo': motivo,
            'fecha_respuesta': DateTime.now().toIso8601String(),
            'id_admin_revisor': adminId,
          })
          .eq('id', solicitudId);

      AppHelpers.hideLoadingDialog(context);
      AppHelpers.showSuccessSnackBar(context, 'Solicitud rechazada correctamente');
      
      // 🔥 DELAY AGREGADO AQUÍ:
      await Future.delayed(const Duration(milliseconds: 700));
      
      // Recargar solicitudes
      await _cargarSolicitudes();
      
      print('✅ Rechazo completado exitosamente');

    } catch (e) {
      AppHelpers.hideLoadingDialog(context);
      AppHelpers.showErrorSnackBar(context, 'Error al rechazar solicitud: ${AppHelpers.parseAuthError(e.toString())}');
      print('❌ Error detallado en rechazo: $e');
    }
  }

  void _mostrarDialogoRechazo(Map<String, dynamic> solicitud) {
    final motivoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF181E2E),
        title: const Text(
          'Rechazar Solicitud',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '¿Estás seguro de rechazar la solicitud de ${solicitud['nombre']}?',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Motivo del rechazo',
                labelStyle: TextStyle(color: Colors.white70),
                hintText: 'Explica por qué se rechaza la solicitud...',
                hintStyle: TextStyle(color: Colors.white54),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final motivo = motivoController.text.trim();
              if (motivo.isNotEmpty) {
                Navigator.of(context).pop();
                _rechazarSolicitud(solicitud, motivo);
              } else {
                AppHelpers.showWarningSnackBar(context, 'Debes escribir un motivo');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101526),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181E2E),
        title: const Text(
          'Gestión de Solicitudes',
          style: TextStyle(color: Colors.white),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFiltroButton('pendiente', 'Pendientes'),
                const SizedBox(width: 8),
                _buildFiltroButton('aprobada', 'Aprobadas'),
                const SizedBox(width: 8),
                _buildFiltroButton('rechazada', 'Rechazadas'),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _cargarSolicitudes,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : solicitudes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox,
                        size: 64,
                        color: Colors.white38,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay solicitudes ${AppHelpers.getStateText(filtroEstado).toLowerCase()}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _cargarSolicitudes,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Actualizar'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarSolicitudes,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: solicitudes.length,
                    itemBuilder: (context, index) {
                      final solicitud = solicitudes[index];
                      return _buildSolicitudCard(solicitud);
                    },
                  ),
                ),
    );
  }

  Widget _buildFiltroButton(String estado, String texto) {
    final isActive = filtroEstado == estado;
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() => filtroEstado = estado);
          _cargarSolicitudes();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? const Color(0xFF2196F3) : Colors.grey[700],
          foregroundColor: Colors.white,
        ),
        child: Text(texto),
      ),
    );
  }

  Widget _buildSolicitudCard(Map<String, dynamic> solicitud) {
    final fechaSolicitud = DateTime.parse(solicitud['fecha_solicitud']);
    final fechaFormateada = AppHelpers.formatDate(fechaSolicitud);

    return Card(
      color: const Color(0xFF181E2E),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF2196F3),
                  child: Text(
                    AppHelpers.getInitials(solicitud['nombre']),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        solicitud['nombre'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        solicitud['email'],
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                _buildEstadoBadge(solicitud['estado']),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow(Icons.star, 'Especialidad', solicitud['especialidad']),
            _buildInfoRow(Icons.calendar_today, 'Fecha solicitud', fechaFormateada),
            _buildInfoRow(Icons.tag, 'ID Solicitud', solicitud['id'].toString()),
            
            if (solicitud['estado'] == 'rechazada' && solicitud['motivo_rechazo'] != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.info, 'Motivo rechazo', solicitud['motivo_rechazo']),
            ],

            if (solicitud['fecha_respuesta'] != null) ...[
              const SizedBox(height: 4),
              _buildInfoRow(Icons.schedule, 'Fecha respuesta', 
                AppHelpers.formatDate(DateTime.parse(solicitud['fecha_respuesta']))),
            ],

            if (solicitud['estado'] == 'pendiente') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _aprobarSolicitud(solicitud),
                      icon: const Icon(Icons.check),
                      label: const Text('Aprobar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _mostrarDialogoRechazo(solicitud),
                      icon: const Icon(Icons.close),
                      label: const Text('Rechazar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 16),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoBadge(String estado) {
    final color = AppHelpers.getStateColor(estado);
    final texto = AppHelpers.getStateText(estado);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        texto,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}