import 'package:flutter/material.dart';
import '../../../utils/helpers.dart';

class BuscarTab extends StatefulWidget {
  final String? userName;

  const BuscarTab({super.key, this.userName});

  @override
  State<BuscarTab> createState() => _BuscarTabState();
}

class _BuscarTabState extends State<BuscarTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101526),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181E2E),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            const Icon(Icons.search, color: Colors.blue, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Reconocer Aves',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              AppHelpers.showInfoSnackBar(context, 'Perfil - En desarrollo');
            },
            icon: CircleAvatar(
              backgroundColor: const Color(0xFF2196F3),
              child: Text(
                AppHelpers.getInitials(widget.userName ?? 'U'),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderText(),
            const SizedBox(height: 40),
            Expanded(
              child: Column(
                children: [
                  _buildSearchCard(
                    icon: Icons.camera_alt,
                    title: 'Reconocer por Foto',
                    subtitle: 'Toma una foto o selecciona una imagen del ave que quieres identificar',
                    isFirstCard: true,
                    onTap: () {
                      AppHelpers.showInfoSnackBar(context, 'Reconocer por Foto - En desarrollo');
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildSearchCard(
                    icon: Icons.mic,
                    title: 'Reconocer por Audio',
                    subtitle: 'Graba el canto del ave para identificar la especie por su sonido',
                    isFirstCard: false,
                    onTap: () {
                      AppHelpers.showInfoSnackBar(context, 'Reconocer por Audio - En desarrollo');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderText() {
    return const Center(
      child: Text(
        'Elige cómo quieres identificar el ave',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white70,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildSearchCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isFirstCard,
    required VoidCallback onTap,
  }) {
    // Colores como en la imagen
    final Color cardColor = isFirstCard 
        ? const Color(0xFF4CAF50).withOpacity(0.15)  // Verde claro para la primera
        : Colors.grey.withOpacity(0.15);              // Gris claro para la segunda
    
    final Color iconBgColor = isFirstCard 
        ? const Color(0xFF2E7D32)  // Verde oscuro para el ícono
        : const Color(0xFF424242); // Gris oscuro para el ícono

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isFirstCard 
                  ? const Color(0xFF4CAF50).withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}