import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/tour.dart';

class GuiasTab extends StatefulWidget {
  const GuiasTab({super.key});

  @override
  State<GuiasTab> createState() => _GuiasTabState();
}

class _GuiasTabState extends State<GuiasTab> {
  List<Tour> _tours = [];
  bool _loading = true;
  String? _error;
  bool _yaAsignado = false;
  int? _tourAsignadoId;

  @override
  void initState() {
    super.initState();
    _fetchToursDeGuias();
    _verificarAsignacion();
  }

  // Obtiene tours con información de guía
  Future<void> _fetchToursDeGuias() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await Supabase.instance.client
          .from('tours')
          .select('*, guia:users!tours_id_guia_fkey(name, email)')
          .order('fecha_creacion', ascending: false);

      _tours = (response as List).map((json) => Tour.fromJson(json)).toList();
    } catch (e) {
      print('Supabase error: $e');
      setState(() {
        _error = 'Error al cargar tours de guías: ${e.toString()}';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // Verifica si el usuario ya está asignado a un tour
  Future<void> _verificarAsignacion() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      // Busca el id_usuario en la tabla turista
      final turista = await Supabase.instance.client
          .from('turista')
          .select('id_usuario')
          .eq('id_usuario', userId)
          .maybeSingle();

      final idTurista = turista != null ? turista['id_usuario'] : null;
      if (idTurista == null) return;

      final asignacion = await Supabase.instance.client
          .from('asignar_tours')
          .select('id_tour')
          .eq('id_turista', idTurista)
          .maybeSingle();

      setState(() {
        _yaAsignado = asignacion != null;
        _tourAsignadoId = asignacion != null ? asignacion['id_tour'] as int : null;
      });
    } catch (e) {
      print('Error verificando asignación: $e');
    }
  }

  // Asigna el tour al usuario
  Future<void> _asignarTourAlUsuario(Tour tour) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // Busca id_usuario en turista
    final turista = await Supabase.instance.client
        .from('turista')
        .select('id_usuario')
        .eq('id_usuario', userId)
        .maybeSingle();

    final idTurista = turista != null ? turista['id_usuario'] : null;
    if (idTurista == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No eres un usuario turista')));
      return;
    }

    // Verifica que no esté asignado
    final asignacion = await Supabase.instance.client
        .from('asignar_tours')
        .select('id')
        .eq('id_turista', idTurista)
        .maybeSingle();

    if (asignacion != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya tienes un tour asignado')));
      return;
    }

    try {
      await Supabase.instance.client.from('asignar_tours').insert({
        'id_turista': idTurista,
        'id_tour': tour.id,
        // Puedes agregar otros campos si quieres (estado, fecha, etc.)
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Te asignaste exitosamente!')));
      setState(() {
        _yaAsignado = true;
        _tourAsignadoId = tour.id;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al asignar: ${e.toString()}')));
    }
  }

  String _formatearFecha(DateTime fecha) {
    return "${fecha.day.toString().padLeft(2, '0')}/"
        "${fecha.month.toString().padLeft(2, '0')}/"
        "${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:"
        "${fecha.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101526),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181E2E),
        title: const Text(
          'Tours de Guías',
          style: TextStyle(color: Colors.white),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Actualizar',
            onPressed: () {
              _fetchToursDeGuias();
              _verificarAsignacion();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _tours.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay tours disponibles de guías.',
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await _fetchToursDeGuias();
                        await _verificarAsignacion();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _tours.length,
                        itemBuilder: (context, index) {
                          final tour = _tours[index];
                          final asignadoEste = _tourAsignadoId == tour.id;
                          return Card(
                            color: asignadoEste
                                ? Colors.green.withOpacity(0.25)
                                : const Color(0xFF181E2E),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ListTile(
                                    title: Text(
                                      tour.titulo,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      "Guía: ${tour.guiaNombre ?? '(sin nombre)'}\n${tour.guiaEmail ?? '(sin correo)'}",
                                      style: const TextStyle(color: Colors.white70),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Chip(
                                      label: Text(
                                        tour.categoria,
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      backgroundColor: Colors.blue.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Descripción: ${tour.descripcion}',
                                      style: const TextStyle(color: Colors.white)),
                                  Text('Precio: ${tour.precioFormateado}',
                                      style: const TextStyle(color: Colors.white)),
                                  Text('Duración: ${tour.duracionFormateada}',
                                      style: const TextStyle(color: Colors.white)),
                                  Text('Máx. personas: ${tour.maxPersonas}',
                                      style: const TextStyle(color: Colors.white)),
                                  Text('Punto de encuentro: ${tour.puntoEncuentro}',
                                      style: const TextStyle(color: Colors.white)),
                                  Text('Fecha creación: ${_formatearFecha(tour.fechaCreacion)}',
                                      style: const TextStyle(color: Colors.white)),
                                  const SizedBox(height: 8),
                                  asignadoEste
                                      ? const Text(
                                          '¡Este es tu tour asignado!',
                                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                        )
                                      : !_yaAsignado
                                          ? ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.blue.shade700),
                                              onPressed: () => _asignarTourAlUsuario(tour),
                                              child: const Text('Asignarme a este tour'),
                                            )
                                          : const SizedBox.shrink(),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}