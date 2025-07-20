class AppConstants {
  // Colors
  static const primaryColor = 0xFF101526;
  static const secondaryColor = 0xFF181E2E;
  static const accentColor = 0xFF2196F3;
  static const successColor = 0xFF4CAF50;
  static const errorColor = 0xFFFF5252;
  static const warningColor = 0xFFFF9800;
  
  // Admin email
  static const String adminEmail = 'admin@email.com';
  
  // User roles
  static const String touristRole = 'tourist';
  static const String guideRole = 'guide';
  static const String adminRole = 'admin';
  
  // Request states
  static const String pendingState = 'pendiente';
  static const String approvedState = 'aprobada';
  static const String rejectedState = 'rechazada';
  
  // Default values
  static const String defaultSpecialty = 'General';
  
  // Validation
  static const int minPasswordLength = 6;
  static const int minNameLength = 2;
  
  // UI
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 10.0;
  static const double cardRadius = 12.0;
  
  // Messages
  static const String comingSoonMessage = 'Próximamente disponible';
  static const String networkErrorMessage = 'Error de conexión. Verifica tu internet.';
  static const String genericErrorMessage = 'Ha ocurrido un error inesperado.';
}

class ValidationMessages {
  static const String invalidEmail = 'Por favor ingresa un correo válido';
  static const String shortPassword = 'Mínimo 6 caracteres';
  static const String shortName = 'Ingresa tu nombre completo';
  static const String passwordMismatch = 'Las contraseñas no coinciden';
  static const String requiredField = 'Este campo es requerido';
  static const String acceptTerms = 'Debes aceptar los términos de servicio';
  static const String specialtyRequired = 'La especialidad es requerida para guías';
  static const String adminEmailReserved = 'Este correo está reservado para el administrador.';
}

class SuccessMessages {
  static const String registrationSuccess = 'Registro exitoso';
  static const String loginSuccess = 'Inicio de sesión exitoso';
  static const String requestSubmitted = 'Solicitud enviada correctamente';
  static const String requestApproved = 'Solicitud aprobada correctamente';
  static const String requestRejected = 'Solicitud rechazada';
  static const String profileUpdated = 'Perfil actualizado';
}