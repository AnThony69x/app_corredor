import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_role.dart';
import '../tourist/home_turista.dart';
import '../shared/espera_aprobacion.dart';
import 'registration_success_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _especialidadController = TextEditingController();

  bool _acceptTerms = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _loading = false;

  UserRole _selectedRole = UserRole.tourist;
  String? _passwordError;
  String? _registerError;
  final String adminEmail = 'admin@email.com';

  Future<void> _register() async {
    setState(() {
      _passwordError = null;
      _registerError = null;
    });

    if (_formKey.currentState?.validate() ?? false) {
      if (!_acceptTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes aceptar los términos de servicio')),
        );
        return;
      }

      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text.trim();
      final confirmPassword = _confirmController.text.trim();

      if (email == adminEmail) {
        setState(() {
          _registerError = "Este correo está reservado para el administrador.";
        });
        return;
      }

      if (password != confirmPassword) {
        setState(() {
          _passwordError = "Las contraseñas no coinciden";
        });
        return;
      }

      setState(() {
        _loading = true;
      });

      try {
        final response = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
          data: {
            'name': _nameController.text.trim(),
          },
        );

        setState(() {
          _loading = false;
        });

        if (response.user == null) {
          setState(() {
            _registerError = 'Error al registrar usuario.';
          });
          return;
        }

        final userId = response.user!.id;
        final userName = _nameController.text.trim();

        if (_selectedRole == UserRole.guide) {
          // **PARA GUÍAS: Crear solicitud pendiente**
          
          // 1. Insertar usuario como turista temporalmente
          await Supabase.instance.client.from('users').insert({
            'id': userId,
            'name': userName,
            'email': email,
            'role': 'tourist', // Temporalmente como turista
          });

          await Supabase.instance.client.from('turista').insert({
            'id_usuario': userId,
          });

          // 2. Crear solicitud de guía pendiente
          final especialidad = _especialidadController.text.trim().isEmpty 
              ? 'General' 
              : _especialidadController.text.trim();

          await Supabase.instance.client.from('solicitudes_guia').insert({
            'id_usuario': userId,
            'nombre': userName,
            'email': email,
            'especialidad': especialidad,
            'estado': 'pendiente',
          });

          print('✅ Solicitud de guía creada correctamente');

          // Navegar a pantalla de espera
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => EsperaAprobacion(
                userName: userName,
                especialidad: especialidad,
              ),
            ),
          );

        } else {
          // **PARA TURISTAS: Registro normal**
          await Supabase.instance.client.from('users').insert({
            'id': userId,
            'name': userName,
            'email': email,
            'role': 'tourist',
          });

          await Supabase.instance.client.from('turista').insert({
            'id_usuario': userId,
          });

          print('✅ Turista registrado correctamente');

          // Navegar a pantalla de confirmación normal
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => RegistrationSuccessScreen(
                userName: userName,
                userRole: 'tourist',
              ),
            ),
          );
        }

      } catch (e) {
        setState(() {
          _loading = false;
          _registerError = e.toString();
        });
        print('❌ ERROR en registro: $e');
      }
    }
  }

  Widget _roleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tipo de usuario',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 16)),
        const SizedBox(height: 6),
        DropdownButton<UserRole>(
          value: _selectedRole,
          dropdownColor: const Color(0xFF181E2E),
          style: const TextStyle(color: Colors.white),
          items: [
            DropdownMenuItem(
                value: UserRole.tourist, child: Text(UserRole.tourist.displayName)),
            DropdownMenuItem(
                value: UserRole.guide, child: Text(UserRole.guide.displayName)),
          ],
          onChanged: (role) {
            setState(() => _selectedRole = role!);
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _especialidadField() {
    if (_selectedRole != UserRole.guide) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Especialidad',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 16)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _especialidadController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Ej: Turismo Cultural, Aventura, Gastronómico...',
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF181E2E),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
          validator: (v) {
            if (_selectedRole == UserRole.guide && (v == null || v.trim().isEmpty)) {
              return 'La especialidad es requerida para guías';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2C3E50),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tu solicitud será revisada por un administrador',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101526),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 38,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person_pin,
                              size: 48, color: Color(0xFF2196F3)),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          '¡Comienza tu registro!',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Crea tu nueva cuenta y descubre destinos increíbles',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),

                  // Nombre
                  const Text('Nombre',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 16)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Tu nombre',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF181E2E),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                    validator: (v) => v != null && v.trim().length > 2
                        ? null
                        : 'Ingresa tu nombre completo',
                  ),
                  const SizedBox(height: 16),

                  // Email
                  const Text('Correo electrónico',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 16)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'tucorreo@email.com',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF181E2E),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v != null && v.contains('@')
                        ? null
                        : 'Por favor ingresa un correo válido',
                  ),
                  const SizedBox(height: 16),

                  // Selector de rol
                  _roleSelector(),

                  // Campo de especialidad (solo para guías)
                  _especialidadField(),

                  // Contraseña
                  const Text('Contraseña',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 16)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passwordController,
                    style: const TextStyle(color: Colors.white),
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      hintText: '********',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF181E2E),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
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
                  const SizedBox(height: 16),

                  // Repetir Contraseña
                  const Text('Repetir contraseña',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 16)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _confirmController,
                    style: const TextStyle(color: Colors.white),
                    obscureText: !_showConfirmPassword,
                    decoration: InputDecoration(
                      hintText: '********',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF181E2E),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white38,
                        ),
                        onPressed: () {
                          setState(() {
                            _showConfirmPassword = !_showConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Repite la contraseña';
                      }
                      if (v != _passwordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                  if (_passwordError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 2),
                      child: Text(
                        _passwordError!,
                        style: const TextStyle(
                            color: Color(0xFFFF5252), fontSize: 13),
                      ),
                    ),
                  if (_registerError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 2),
                      child: Text(
                        _registerError!,
                        style: const TextStyle(
                            color: Color(0xFFFF5252), fontSize: 13),
                      ),
                    ),
                  const SizedBox(height: 10),

                  // Términos de servicio
                  Row(
                    children: [
                      Checkbox(
                        value: _acceptTerms,
                        activeColor: const Color(0xFF2196F3),
                        onChanged: (v) =>
                            setState(() => _acceptTerms = v ?? false),
                      ),
                      Expanded(
                        child: Text(
                          'Acepto los términos de servicio',
                          style: TextStyle(
                              color: _acceptTerms
                                  ? Colors.white70
                                  : const Color(0xFFFF5252)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Botón de registro
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF23A7F3),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            )
                          : Text(_selectedRole == UserRole.guide 
                              ? 'Enviar solicitud' 
                              : 'Registrarme'),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Link para iniciar sesión
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("¿Ya tienes una cuenta? ",
                            style: TextStyle(
                                color: Colors.white60, fontSize: 14)),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Inicia sesión',
                            style: TextStyle(
                                color: Color(0xFFFE6D4E),
                                fontWeight: FontWeight.w600,
                                fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}