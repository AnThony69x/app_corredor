import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'tabs/buscar_tab.dart';
import 'tabs/mapa_tab.dart';
import 'tabs/guias_tab.dart';
import 'tabs/consultar_tab.dart';
import '../auth/login_screen.dart';
import '../../utils/helpers.dart';

class HomeTurista extends StatefulWidget {
  const HomeTurista({super.key});

  @override
  State<HomeTurista> createState() => _HomeTuristaState();
}

class _HomeTuristaState extends State<HomeTurista> {
  int _currentIndex = 0;
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

  List<Widget> get _tabs => [
    BuscarTab(userName: userName),
    const MapaTab(),
    const GuiasTab(),
    ConsultarTab(userName: userName),
  ];

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF101526),
        body: Center(
          child: CircularProgressIndicator(color: Colors.blue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF101526),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF181E2E),
          border: Border(
            top: BorderSide(color: Colors.white12, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: const Color(0xFF2196F3),
          unselectedItemColor: Colors.white54,
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              activeIcon: Icon(Icons.search, size: 28),
              label: 'Buscar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              activeIcon: Icon(Icons.map, size: 28),
              label: 'Mapa',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              activeIcon: Icon(Icons.people, size: 28),
              label: 'Guías',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book),
              activeIcon: Icon(Icons.menu_book, size: 28),
              label: 'Consultar',
            ),
          ],
        ),
      ),
    );
  }
}