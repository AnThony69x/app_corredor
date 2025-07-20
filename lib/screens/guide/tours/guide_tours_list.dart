import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/tour_controller.dart';
import '../../../models/tour.dart';
import '../../../utils/helpers.dart';
import 'create_tour_screen.dart';
import 'edit_tour_screen.dart';
import 'tour_details_screen.dart';

class GuideToursList extends StatefulWidget {
  const GuideToursList({super.key});

  @override
  State<GuideToursList> createState() => _GuideToursListState();
}

class _GuideToursListState extends State<GuideToursList> {
  late TourController tourController;

  @override
  void initState() {
    super.initState();
    // Usamos Provider para obtener la instancia compartida
    Future.delayed(Duration.zero, () {
      tourController = Provider.of<TourController>(context, listen: false);
      _cargarTours();
    });
  }

  Future<void> _cargarTours() async {
    await tourController.cargarMisTours();
  }

  Future<void> _eliminarTour(Tour tour) async {
    final confirmed = await AppHelpers.showConfirmationDialog(
      context,
      title: 'Eliminar Tour',
      message:
          '¿Estás seguro de que quieres eliminar "${tour.titulo}"?\n\nEsta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      confirmColor: Colors.red,
    );

    if (confirmed && tour.id != null) {
      final success = await tourController.eliminarTour(tour.id!);
      if (success) {
        AppHelpers.showSuccessSnackBar(context, 'Tour eliminado exitosamente');
      } else {
        AppHelpers.showErrorSnackBar(context, tourController.error ?? 'Error al eliminar tour');
      }
    }
  }

  Future<void> _cambiarEstado(Tour tour, String nuevoEstado) async {
    if (tour.id != null) {
      final success = await tourController.cambiarEstadoTour(tour.id!, nuevoEstado);
      if (success) {
        AppHelpers.showSuccessSnackBar(context, 'Estado actualizado');
      } else {
        AppHelpers.showErrorSnackBar(context, tourController.error ?? 'Error al cambiar estado');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TourController>(
      builder: (context, controller, child) {
        final tours = controller.tours;

        return Scaffold(
          backgroundColor: const Color(0xFF101526),
          appBar: AppBar(
            backgroundColor: const Color(0xFF181E2E),
            automaticallyImplyLeading: false,
            title: const Text('Mis Tours', style: TextStyle(color: Colors.white)),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Actualizar',
                onPressed: _cargarTours,
              ),
            ],
          ),
          body: controller.loading && tours.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF23A7F3)),
                )
              : controller.error != null
                  ? Center(
                      child: Text(
                        controller.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : tours.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.tour, color: Colors.white54, size: 64),
                              const SizedBox(height: 16),
                              const Text(
                                'No tienes tours creados.',
                                style: TextStyle(color: Colors.white70, fontSize: 18),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Crea tu primer tour para empezar',
                                style: TextStyle(color: Colors.white54),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _cargarTours,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Actualizar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2196F3),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _cargarTours,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: tours.length,
                            itemBuilder: (context, index) {
                              final tour = tours[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildTourCard(tour),
                              );
                            },
                          ),
                        ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const CreateTourScreen()),
              );
              if (result == true) _cargarTours();
            },
            backgroundColor: const Color(0xFF2196F3),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Nuevo Tour',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTourCard(Tour tour) {
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

    return GestureDetector(
      onTap: () async {
        final updated = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => TourDetailsScreen(tour: tour),
          ),
        );
        if (updated == true) _cargarTours();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF181E2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withOpacity(0.3)),
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        tour.estado.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
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
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.white54, size: 16),
                const SizedBox(width: 4),
                Text(
                  tour.ubicacion,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  tour.precioFormateado,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.white54, size: 16),
                const SizedBox(width: 4),
                Text(
                  tour.duracionFormateada,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(Icons.people, color: Colors.white54, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Max ${tour.maxPersonas}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const Spacer(),
                _buildActionButtons(tour),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Tour tour) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => EditTourScreen(tour: tour),
              ),
            );
            if (result == true) _cargarTours();
          },
          icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
          tooltip: 'Editar',
        ),
        if (tour.estado == 'aprobado')
          IconButton(
            onPressed: () => _cambiarEstado(tour, 'inactivo'),
            icon: const Icon(Icons.pause, color: Colors.orange, size: 20),
            tooltip: 'Desactivar',
          ),
        if (tour.estado == 'inactivo')
          IconButton(
            onPressed: () => _cambiarEstado(tour, 'pendiente'),
            icon: const Icon(Icons.play_arrow, color: Colors.green, size: 20),
            tooltip: 'Activar',
          ),
        IconButton(
          onPressed: () => _eliminarTour(tour),
          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
          tooltip: 'Eliminar',
        ),
      ],
    );
  }
}