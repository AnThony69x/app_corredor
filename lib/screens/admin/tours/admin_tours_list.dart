import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/tour.dart';

class AdminToursList extends StatefulWidget {
  const AdminToursList({super.key});

  @override
  State<AdminToursList> createState() => _AdminToursListState();
}

class _AdminToursListState extends State<AdminToursList> {
  List<Tour> _tours = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTours();
  }

  Future<void> _fetchTours() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await Supabase.instance.client
          .from('tours')
          .select()
          .order('fecha_creacion', ascending: false);

      _tours = (response as List).map((json) => Tour.fromJson(json)).toList();
    } catch (e) {
      _error = 'Error al cargar tours';
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'aprobado':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'rechazado':
        return Colors.red;
      case 'inactivo':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101526),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181E2E),
        title: const Text(
          'Todos los Tours',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchTours,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tours.length,
                    itemBuilder: (context, index) {
                      final tour = _tours[index];
                      return Card(
                        color: const Color(0xFF181E2E),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      tour.titulo,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Chip(
                                    label: Text(
                                      tour.estado,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: _estadoColor(tour.estado).withOpacity(0.7),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                tour.descripcion,
                                style: const TextStyle(color: Colors.white70, fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, color: Colors.white54, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    tour.ubicacion,
                                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  ),
                                  const Spacer(),
                                  Text(
                                    tour.precioFormateado,
                                    style: const TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
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