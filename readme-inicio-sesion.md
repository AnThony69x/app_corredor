# 🔐 Módulo de Inicio de Sesión

Sistema de autenticación completo con gestión de roles (turista, guía, administrador) y aprobación de guías turísticos.

---

## 👥 Tipos de Usuario

| Tipo         | Registro              | Acceso           | Estado                  |
|--------------|----------------------|------------------|-------------------------|
| 🏖️ Turista   | Inmediato            | Directo          | Activo                  |
| 🎯 Guía      | Requiere aprobación  | Pendiente/Aprob. | Pendiente/Aprobado      |
| 👨‍💼 Admin   | Manual (email admin) | Directo          | Activo                  |

---

## 🔄 Flujo Principal

### **Registro**
- Turista: Formulario → Cuenta creada → Home Turista
- Guía: Formulario → Solicitud → Espera → Aprobación → Home Guía

### **Inicio de Sesión**
- Usuario ingresa credenciales
- Verificación de rol:
  - Admin → Home Admin
  - Turista → Home Turista
  - Guía → Verifica estado solicitud:
    - Pendiente → Pantalla Espera
    - Aprobado → Home Guía

---

## 🗄️ Base de Datos

- **users:** id, name, email, role
- **turista:** id_usuario
- **guia:** id_usuario, especialidad
- **solicitudes_guia:** id_usuario, nombre, email, especialidad, estado (pendiente/aprobada/rechazada), motivo_rechazo, fechas

---

## 🔧 Características

- Seguridad Row Level Security (RLS)
- Validación frontend/backend
- Manejo de errores amigables
- Pantalla de espera con refresh manual y automático (cada 30s)
- UI responsive con dark theme
- Panel admin para gestión de solicitudes
- Redirección automática según rol y estado

---

## 📁 Estructura Básica

```
lib/
├── screens/auth/login_screen.dart
├── screens/auth/register_screen.dart
├── screens/shared/espera_aprobacion.dart
├── screens/admin/admin_solicitudes_screen.dart
├── screens/guide/home_guia.dart
├── screens/tourist/home_turista.dart
├── utils/helpers.dart
├── utils/constants.dart
├── services/supabase_service.dart
```

---

## 🎯 Funciones Clave

- **Login:** Validación, manejo de errores y redirección por rol
- **Registro:** Creación de cuenta, perfil y solicitud de guía
- **Gestión de solicitudes:** Aprobación/Rechazo por admin, cambio de rol y actualización de estado
- **Pantalla de espera:** Verificar estado manual y automático, mensajes personalizados por estado

---

## 🚀 Estado Actual

- [x] Registro turistas/guías
- [x] Login con roles
- [x] Panel admin solicitudes
- [x] Aprobación/rechazo guías
- [x] Pantalla espera con refresh
- [x] Manejo de errores amigables
- [x] UI responsive

**Desarrollado por:** AnThony69x  
**Fecha:** 19 Jul 2025  

admin@gmail.com
admin123