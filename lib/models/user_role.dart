enum UserRole { 
  tourist, 
  guide, 
  admin 
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.tourist:
        return 'Turista';
      case UserRole.guide:
        return 'Guía';
      case UserRole.admin:
        return 'Administrador';
    }
  }

  String get value {
    switch (this) {
      case UserRole.tourist:
        return 'tourist';
      case UserRole.guide:
        return 'guide';
      case UserRole.admin:
        return 'admin';
    }
  }
}