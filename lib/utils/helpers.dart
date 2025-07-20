import 'package:flutter/material.dart';
import 'constants.dart';
import 'dart:async';

class AppHelpers {
  // Validation helpers
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  static bool isValidPassword(String password) {
    return password.length >= AppConstants.minPasswordLength;
  }
  
  static bool isValidName(String name) {
    return name.trim().length >= AppConstants.minNameLength;
  }
  
  // Format helpers
  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
  
  static String getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  
  // 🔥 NUEVA FUNCIÓN: Auth error parser
  static String parseAuthError(String error) {
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
    } else if (error.contains('User already registered')) {
      return 'Este correo ya está registrado';
    } else if (error.contains('Password should be at least')) {
      return 'La contraseña debe tener al menos 6 caracteres';
    } else if (error.contains('Network')) {
      return 'Error de conexión. Verifica tu internet';
    } else if (error.contains('timeout')) {
      return 'Tiempo de espera agotado. Intenta nuevamente';
    } else if (error.contains('AuthApiException')) {
      return 'Error de autenticación. Verifica tus credenciales';
    } else {
      return 'Error al procesar la solicitud. Intenta nuevamente';
    }
  }
  
  // Color helpers
  static Color getStateColor(String state) {
    switch (state) {
      case AppConstants.approvedState:
        return const Color(AppConstants.successColor);
      case AppConstants.rejectedState:
        return const Color(AppConstants.errorColor);
      case AppConstants.pendingState:
      default:
        return const Color(AppConstants.warningColor);
    }
  }
  
  static String getStateText(String state) {
    switch (state) {
      case AppConstants.approvedState:
        return 'Aprobada';
      case AppConstants.rejectedState:
        return 'Rechazada';
      case AppConstants.pendingState:
      default:
        return 'Pendiente';
    }
  }
  
  // Snackbar helpers
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(AppConstants.successColor),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(AppConstants.errorColor),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }
  
  static void showWarningSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(AppConstants.warningColor),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  // 🔥 NUEVA FUNCIÓN: Info snackbar
  static void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(AppConstants.accentColor),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  // Loading dialog
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(AppConstants.secondaryColor),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Color(AppConstants.accentColor),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }
  
  // 🔥 NUEVA FUNCIÓN: Confirmation dialog
  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    Color? confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(AppConstants.secondaryColor),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelText,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? const Color(AppConstants.accentColor),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
  
  // Role helpers
  static String getRoleDisplayName(String role) {
    switch (role) {
      case AppConstants.touristRole:
        return 'Turista';
      case AppConstants.guideRole:
        return 'Guía';
      case AppConstants.adminRole:
        return 'Administrador';
      default:
        return 'Usuario';
    }
  }
  
  static Color getRoleColor(String role) {
    switch (role) {
      case AppConstants.touristRole:
        return const Color(AppConstants.accentColor);
      case AppConstants.guideRole:
        return const Color(AppConstants.successColor);
      case AppConstants.adminRole:
        return const Color(AppConstants.errorColor);
      default:
        return Colors.grey;
    }
  }
  
  // 🔥 NUEVA FUNCIÓN: Network connectivity helper
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }
  
  // 🔥 NUEVA FUNCIÓN: Safe navigation
  static void safeNavigate(BuildContext context, Widget page) {
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => page),
      );
    }
  }
  
  static void safeNavigateReplacement(BuildContext context, Widget page) {
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => page),
      );
    }
  }
  
  // 🔥 NUEVA FUNCIÓN: Debounce for search
  static void debounce(Function() action, Duration delay) {
    Timer? timer;
    timer?.cancel();
    timer = Timer(delay, action);
  }
  
  // 🔥 NUEVA FUNCIÓN: Generate random color
  static Color generateColorFromString(String text) {
    var hash = 0;
    for (var i = 0; i < text.length; i++) {
      hash = text.codeUnitAt(i) + ((hash << 5) - hash);
    }
    final hue = (hash % 360).abs();
    return HSVColor.fromAHSV(1.0, hue.toDouble(), 0.7, 0.9).toColor();
  }
}

// 🔥 NUEVA CLASE: Extensions útiles
extension StringExtensions on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
  
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }
  
  bool get isValidEmail {
    return AppHelpers.isValidEmail(this);
  }
}

extension DateTimeExtensions on DateTime {
  String get formattedDate => AppHelpers.formatDate(this);
  String get formattedDateTime => AppHelpers.formatDateTime(this);
  
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
  
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }
}