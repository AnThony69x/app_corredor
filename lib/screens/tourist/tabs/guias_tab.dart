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

  @override
  void initState() {
    super.initState();
    _fetchToursDeGuias();
  }

  Future<void> _fetchToursDeGuias() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Cambiado a tours y usando el nombre correcto de la relación y tabla users
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
            onPressed: _fetchToursDeGuias,
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
                      onRefresh: _fetchToursDeGuias,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _tours.length,
                        itemBuilder: (context, index) {
                          final tour = _tours[index];
                          return Card(
                            color: const Color(0xFF181E2E),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(
                                tour.titulo,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                "Guía: ${tour.guiaNombre ?? '(sin nombre)'}\n${tour.descripcion}",
                                style: const TextStyle(color: Colors.white70),
                                maxLines: 3,
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
                          );
                        },
                      ),
                    ),
    );
  }
}