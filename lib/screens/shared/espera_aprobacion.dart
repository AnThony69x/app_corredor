import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../guide/home_guia.dart';
import '../tourist/home_turista.dart';
import '../auth/login_screen.dart';
import '../../utils/helpers.dart';

class EsperaAprobacion extends StatefulWidget {
  final String userName;
  final String especialidad;

  const EsperaAprobacion({
    super.key,
    required this.userName,
    required this.especialidad,
  });

  @override
  State<EsperaAprobacion> createState() => _EsperaAprobacionState();
}

class _EsperaAprobacionState extends State<EsperaAprobacion> {
  String? estadoSolicitud;
  String? motivoRechazo;
  bool _loading = true;
  bool _verificando = false;
  late Stream<List<Map<String, dynamic>>> _solicitudStream;

  @override
  void initState() {
    super.initState();
    _configurarEscuchaEnTiempoReal();
    _verificarEstadoSolicitud();
  }

  void _configurarEscuchaEnTiempoReal() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      // Configurar stream en tiempo real de Supabase
      _solicitudStream = Supabase.instance.client
          .from('solicitudes_guia')
          .stream(primaryKey: ['id'])
          .eq('id_usuario', userId)
          .order('fecha_solicitud', ascending: false)
          .limit(1);

      // Escuchar cambios en tiempo real
      _solicitudStream.listen((data) {
        if (data.isNotEmpty && mounted) {
          final solicitud = data.first;
          final nuevoEstado = solicitud['estado'];
          
          print('🔔 REALTIME: Estado actualizado a: $nuevoEstado');
          
          setState(() {
            estadoSolicitud = nuevoEstado;
            motivoRechazo = solicitud['motivo_rechazo'];
            _loading = false;
            _verificando = false;
          });

          // Si cambió el estado a aprobada o rechazada, redirigir inmediatamente
          if (nuevoEstado == 'aprobada' || nuevoEstado == 'rechazada') {
            _mostrarNotificacionCambio(nuevoEstado);
            // Redirigir después de 2 segundos para que el usuario vea el mensaje
            Future.delayed(const Duration(seconds: 2), () {
              _redirigirSegunEstado();
            });
          }
        }
      });
    }
  }

  void _mostrarNotificacionCambio(String nuevoEstado) {
    if (nuevoEstado == 'aprobada') {
      AppHelpers.showSuccessSnackBar(
        context, 
        '¡Felicidades! Tu solicitud ha sido aprobada',
      );
    } else if (nuevoEstado == 'rechazada') {
      AppHelpers.showWarningSnackBar(
        context, 
        'Tu solicitud ha sido rechazada',
      );
    }
  }

  Future<void> _verificarEstadoSolicitud() async {
    setState(() => _verificando = true);
    
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        _redirigirALogin();
        return;
      }

      print('🔍 Verificando estado para usuario: $userId');

      final response = await Supabase.instance.client
          .from('solicitudes_guia')
          .select('estado, motivo_rechazo, fecha_respuesta')
          .eq('id_usuario', userId)
          .order('fecha_solicitud', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        print('❌ No se encontró solicitud para el usuario');
        _redirigirALogin();
        return;
      }

      setState(() {
        estadoSolicitud = response['estado'];
        motivoRechazo = response['motivo_rechazo'];
        _loading = false;
        _verificando = false;
      });

      print('📋 Estado actual: $estadoSolicitud');

      // Si fue aprobada o rechazada, redirigir después de mostrar el mensaje
      if (estadoSolicitud == 'aprobada' || estadoSolicitud == 'rechazada') {
        await Future.delayed(const Duration(seconds: 2));
        _redirigirSegunEstado();
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _verificando = false;
      });
      AppHelpers.showErrorSnackBar(context, 'Error al verificar estado: ${AppHelpers.parseAuthError(e.toString())}');
      print('❌ Error verificando estado: $e');
    }
  }

  void _redirigirSegunEstado() {
    if (!mounted) return;

    if (estadoSolicitud == 'aprobada') {
      // Redirigir a home de guía
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeGuia()),
        (route) => false,
      );
    } else if (estadoSolicitud == 'rechazada') {
      // Redirigir a home de turista
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeTurista()),
        (route) => false,
      );
    }
  }

  void _redirigirALogin() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _iniciarSesionComoGuia() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeGuia()),
      (route) => false,
    );
  }

  void _continuarComoTurista() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeTurista()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFF101526),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.orange),
              SizedBox(height: 16),
              Text(
                'Verificando estado...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF101526),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatusIcon(),
              const SizedBox(height: 24),
              _buildStatusText(),
              const SizedBox(height: 32),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (estadoSolicitud) {
      case 'aprobada':
        return const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 80,
        );
      case 'rechazada':
        return const Icon(
          Icons.cancel,
          color: Colors.red,
          size: 80,
        );
      default:
        return Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.hourglass_empty,
              color: Colors.orange,
              size: 80,
            ),
            // Añadir indicador de escucha en tiempo real
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildStatusText() {
    switch (estadoSolicitud) {
      case 'aprobada':
        return Column(
          children: [
            const Text(
              '¡Usted ha sido Aceptado como Guía!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.green,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Felicidades ${widget.userName}, su solicitud para ser guía de ${widget.especialidad} ha sido aprobada.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.celebration, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Ya puede acceder como Guía Turístico',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        );
      case 'rechazada':
        return Column(
          children: [
            const Text(
              'Usted ha sido Rechazado como Guía',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Lo sentimos ${widget.userName}, su solicitud para ser guía de ${widget.especialidad} ha sido rechazada por nuestro equipo.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            if (motivoRechazo != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Motivo del rechazo:',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      motivoRechazo!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: const Text(
                'Podrá continuar usando la aplicación como turista.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blue, fontSize: 14),
              ),
            ),
          ],
        );
      default:
        return Column(
          children: [
            const Text(
              'Solicitud en Revisión',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Hola ${widget.userName}, tu solicitud para ser guía de ${widget.especialidad} está siendo revisada por nuestro equipo.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Conectado en tiempo real - Se actualizará automáticamente',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.orange, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _buildActionButtons() {
    switch (estadoSolicitud) {
      case 'aprobada':
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _iniciarSesionComoGuia,
                icon: const Icon(Icons.login),
                label: const Text('Iniciar Sesión como Guía'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Redirigiendo automáticamente en 2 segundos...',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        );
      case 'rechazada':
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _continuarComoTurista,
                icon: const Icon(Icons.explore),
                label: const Text('Continuar como Turista'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Redirigiendo automáticamente en 2 segundos...',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        );
      default:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _verificando ? null : _verificarEstadoSolicitud,
                icon: _verificando 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh),
                label: Text(_verificando ? 'Verificando...' : 'Verificar Estado'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: const Text(
                '🔔 Actualización automática en tiempo real activada',
                style: TextStyle(color: Colors.green, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
    }
  }

  @override
  void dispose() {
    // Limpiar recursos del stream si es necesario
    super.dispose();
  }
}