import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/registration_success_screen.dart';
import '../screens/admin/home_admin.dart';
import '../screens/admin/admin_solicitudes_screen.dart';
import '../screens/guide/home_guia.dart';
import '../screens/tourist/home_turista.dart';
import '../screens/shared/espera_aprobacion.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String registrationSuccess = '/registration_success';
  static const String homeAdmin = '/home_admin';
  static const String adminSolicitudes = '/admin_solicitudes';
  static const String homeGuia = '/home_guia';
  static const String homeTurista = '/home_turista';
  static const String esperaAprobacion = '/espera_aprobacion';

  static Map<String, WidgetBuilder> get routes => {
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    homeAdmin: (context) => const HomeAdmin(),
    adminSolicitudes: (context) => const AdminSolicitudesScreen(),
    homeGuia: (context) => const HomeGuia(),
    homeTurista: (context) => const HomeTurista(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case registrationSuccess:
        final args = settings.arguments as Map<String, String>?;
        return MaterialPageRoute(
          builder: (context) => RegistrationSuccessScreen(
            userName: args?['userName'] ?? 'Usuario',
            userRole: args?['userRole'] ?? 'tourist',
          ),
        );
      
      case esperaAprobacion:
        final args = settings.arguments as Map<String, String>?;
        return MaterialPageRoute(
          builder: (context) => EsperaAprobacion(
            userName: args?['userName'] ?? 'Usuario',
            especialidad: args?['especialidad'] ?? 'General',
          ),
        );
      
      default:
        return MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        );
    }
  }
}