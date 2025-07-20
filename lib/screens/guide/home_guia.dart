import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/login_screen.dart';
import '../../utils/helpers.dart';
import 'tours/guide_tours_list.dart';
import 'tours/create_tour_screen.dart';

class HomeGuia extends StatefulWidget {
  const HomeGuia({super.key});

  @override
  State<HomeGuia> createState() => _HomeGuiaState();
}

class _HomeGuiaState extends State<HomeGuia> {
  String? userName;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        _redirigirALogin();
        return;
      }
      final response = await Supabase.instance.client
          .from('users')
          .select('name')
          .eq('id', userId)
          .single();
      setState(() {
        userName = response['name'];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      AppHelpers.showErrorSnackBar(context, 'Error al cargar datos del usuario');
    }
  }

  void _redirigirALogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _cerrarSesion() async {
    final confirmed = await AppHelpers.showConfirmationDialog(
      context,
      title: 'Cerrar Sesión',
      message: '¿Estás seguro de que quieres cerrar sesión?',
      confirmText: 'Cerrar Sesión',
      confirmColor: Colors.red,
    );
    if (confirmed) {
      try {
        await Supabase.instance.client.auth.signOut();
        _redirigirALogin();
      } catch (e) {
        AppHelpers.showErrorSnackBar(context, 'Error al cerrar sesión');
      }
    }
  }

  void _navegarAPerfil() {
    // Mantenemos el placeholder de perfil
    AppHelpers.showInfoSnackBar(context, 'Perfil - En desarrollo');
  }

Future<void> _crearNuevoTour() async {
  final creado = await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const CreateTourScreen()),
  );

  if (creado == true) {
    setState(() {}); // Solo recarga si se creó un nuevo tour
  }
}


  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF101526),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF23A7F3)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF101526),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181E2E),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.tour, color: Color(0xFF23A7F3), size: 24),
            const SizedBox(width: 8),
            const Text(
              'Mis Tours',
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
            onPressed: _navegarAPerfil,
            icon: CircleAvatar(
              backgroundColor: const Color(0xFF23A7F3),
              child: Text(
                AppHelpers.getInitials(userName ?? 'G'),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
          IconButton(
            onPressed: _cerrarSesion,
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: 12),
          Expanded(
            child: GuideToursList(), // Aquí va tu lista sin filtros ni resumen
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF23A7F3),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Tour'),
        onPressed: _crearNuevoTour,
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF23A7F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Bienvenido${userName != null ? ', $userName' : ''}!\nGestiona y crea tus tours.',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
