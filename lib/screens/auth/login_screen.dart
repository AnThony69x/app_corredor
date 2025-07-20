import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../admin/home_admin.dart';
import '../guide/home_guia.dart';
import '../tourist/home_turista.dart';
import '../shared/espera_aprobacion.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _showPassword = false;
  bool _loading = false;
  String? _loginError;

  Future<void> _login() async {
    setState(() {
      _loginError = null;
    });

    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _loading = true;
      });

      try {
        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim().toLowerCase(),
          password: _passwordController.text.trim(),
        );

        setState(() {
          _loading = false;
        });

        if (response.user != null) {
          final userId = response.user!.id;
          
          // Obtener información del usuario
          final profileResponse = await Supabase.instance.client
              .from('users')
              .select('name, role')
              .eq('id', userId)
              .single();

          final role = profileResponse['role'];
          final userName = profileResponse['name'] ?? 'Usuario';

          // Navegar según el rol
          if (role == 'guide') {
            // Verificar si tiene solicitudes pendientes
            final solicitudResponse = await Supabase.instance.client
                .from('solicitudes_guia')
                .select('estado, especialidad')
                .eq('id_usuario', userId)
                .eq('estado', 'pendiente')
                .maybeSingle();
            
            if (solicitudResponse != null) {
              // Aún tiene solicitud pendiente
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => EsperaAprobacion(
                  userName: userName,
                  especialidad: solicitudResponse['especialidad'] ?? 'General',
                )),
              );
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeGuia()),
              );
            }
          } else if (role == 'admin') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeAdmin()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeTurista()),
            );
          }
        }
      } catch (e) {
        setState(() {
          _loading = false;
          _loginError = _parseAuthError(e.toString());
        });
      }
    }
  }

  // 🔥 NUEVA FUNCIÓN: Convertir errores técnicos en mensajes amigables
  String _parseAuthError(String error) {
    if (error.contains('Invalid login credentials') || 
        error.contains('invalid_credentials') ||
        error.contains('Email not confirmed') ||
        error.contains('Invalid email or password')) {
      return 'Correo o contraseña incorrectos';
    } else if (error.contains('Email rate limit exceeded')) {
      return 'Demasiados intentos. Espera un momento antes de intentar nuevamente';
    } else if (error.contains('signup_disabled')) {
      return 'El registro está temporalmente deshabilitado';
    } else if (error.contains('email_address_not_authorized')) {
      return 'Esta dirección de correo no está autorizada';
    } else if (error.contains('Network')) {
      return 'Error de conexión. Verifica tu internet';
    } else if (error.contains('timeout')) {
      return 'Tiempo de espera agotado. Intenta nuevamente';
    } else {
      // Para cualquier otro error, mostrar mensaje genérico
      return 'Error al iniciar sesión. Verifica tus credenciales';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101526),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.eco, size: 60, color: Color(0xFF2196F3)),
                  ),
                  const SizedBox(height: 32),
                  
                  const Text(
                    'Bienvenido de vuelta',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Inicia sesión para continuar',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 48),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: 'tucorreo@email.com',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF181E2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      prefixIcon: const Icon(Icons.email, color: Colors.white54),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v != null && v.contains('@')
                        ? null
                        : 'Por favor ingresa un correo válido',
                  ),
                  const SizedBox(height: 20),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    style: const TextStyle(color: Colors.white),
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: '********',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF181E2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      prefixIcon: const Icon(Icons.lock, color: Colors.white54),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white38,
                        ),
                        onPressed: () {
                          setState(() {
                            _showPassword = !_showPassword;
                          });
                        },
                      ),
                    ),
                    validator: (v) => v != null && v.length >= 6
                        ? null
                        : 'Mínimo 6 caracteres',
                  ),

                  // 🔥 MEJORADO: Error message con mejor estilo
                  if (_loginError != null)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _loginError!,
                              style: const TextStyle(color: Colors.red, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF23A7F3),
                        disabledBackgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Iniciar Sesión'),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 🔥 NUEVO: Forgot password link
                  TextButton(
                    onPressed: () {
                      // TODO: Implementar recuperación de contraseña
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Función de recuperación próximamente disponible'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                    child: const Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ),
                  
                  const SizedBox(height: 8),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "¿No tienes una cuenta? ",
                        style: TextStyle(color: Colors.white60, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: const Text(
                          'Regístrate',
                          style: TextStyle(
                            color: Color(0xFFFE6D4E),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}