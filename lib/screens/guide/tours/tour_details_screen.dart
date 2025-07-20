import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/tour.dart';

class TourDetailsScreen extends StatefulWidget {
  final Tour tour;

  const TourDetailsScreen({super.key, required this.tour});

  @override
  State<TourDetailsScreen> createState() => _TourDetailsScreenState();
}

class _TourDetailsScreenState extends State<TourDetailsScreen> {
  Future<List<Map<String, String>>>? _asignadosFuture;

  @override
  void initState() {
    super.initState();
    _asignadosFuture = _cargarAsignados();
  }

  Future<List<Map<String, String>>> _cargarAsignados() async {
    final tourId = widget.tour.id ?? 0;
    final response = await Supabase.instance.client
        .from('asignar_tours')
        .select('id_turista, usuario:users!asignar_tours_id_turista_fkey(name, email)')
        .eq('id_tour', tourId);

    if (response is List) {
      return response.map<Map<String, String>>((json) {
        return {
          'nombre': json['usuario']?['name'] ?? 'Sin nombre',
          'email': json['usuario']?['email'] ?? 'Sin email',
        };
      }).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final tour = widget.tour;
    return Scaffold(
      backgroundColor: const Color(0xFF101526),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181E2E),
        title: const Text(
          'Detalles del Tour',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildBasicInfo(),
            const SizedBox(height: 24),
            _buildDescription(),
            const SizedBox(height: 24),
            _buildIncludes(),
            const SizedBox(height: 24),
            _buildContactInfo(),
            const SizedBox(height: 24),
            FutureBuilder<List<Map<String, String>>>(
              future: _asignadosFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF181E2E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.blueAccent),
                    ),
                  );
                }
                final asignados = snapshot.data ?? [];
                return _buildAssignedUsers(asignados);
              },
            ),
            const SizedBox(height: 24),
            _buildAdditionalInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final tour = widget.tour;
    Color statusColor;
    IconData statusIcon;

    switch (tour.estado) {
      case 'aprobado':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pendiente':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'rechazado':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'inactivo':
        statusColor = Colors.grey;
        statusIcon = Icons.pause_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF23A7F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
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
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      tour.estado.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text(
                tour.ubicacion,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.category, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text(
                tour.categoria,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    final tour = widget.tour;
    final info = [
      {'icon': Icons.attach_money, 'label': 'Precio', 'value': tour.precioFormateado},
      {'icon': Icons.access_time, 'label': 'Duración', 'value': tour.duracionFormateada},
      {'icon': Icons.people, 'label': 'Máx. Personas', 'value': '${tour.maxPersonas}'},
      {'icon': Icons.place, 'label': 'Punto de Encuentro', 'value': tour.puntoEncuentro},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF181E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información Básica',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...info.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(
                  item['icon'] as IconData,
                  color: const Color(0xFF23A7F3),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['label'] as String,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        item['value'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    final tour = widget.tour;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF181E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Descripción',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tour.descripcion,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncludes() {
    final tour = widget.tour;
    return Column(
      children: [
        if (tour.incluye.isNotEmpty)
          _buildIncludesList('Qué Incluye', tour.incluye, Colors.green),
        if (tour.incluye.isNotEmpty && tour.noIncluye.isNotEmpty)
          const SizedBox(height: 16),
        if (tour.noIncluye.isNotEmpty)
          _buildIncludesList('Qué NO Incluye', tour.noIncluye, Colors.red),
      ],
    );
  }

  Widget _buildIncludesList(String title, List<String> items, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF181E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.check, color: color, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    final tour = widget.tour;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF181E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contacto del Guía',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.person, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                tour.guiaNombre ?? 'Sin guía',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(width: 12),
              Text(
                tour.guiaEmail ?? 'Sin email',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.alternate_email, color: Color(0xFF23A7F3), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tour.redSocial ?? 'No disponible',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.phone, color: Color(0xFF23A7F3), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tour.telefono ?? 'No disponible',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedUsers(List<Map<String, String>> asignados) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF181E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Turistas Asignados',
            style: TextStyle(
              color: Colors.blueAccent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          asignados.isEmpty
              ? const Text(
                  'No hay turistas asignados aún.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: asignados.length,
                  itemBuilder: (context, index) {
                    final usuario = asignados[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Colors.blueAccent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              usuario['nombre']!,
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            usuario['email']!,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    final tour = widget.tour;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF181E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información Adicional',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (tour.requisitos != null && tour.requisitos!.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.rule, color: Color(0xFF23A7F3), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Requisitos',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        tour.requisitos!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.calendar_today, color: Color(0xFF23A7F3), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fecha de Creación',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${tour.fechaCreacion.day}/${tour.fechaCreacion.month}/${tour.fechaCreacion.year}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}