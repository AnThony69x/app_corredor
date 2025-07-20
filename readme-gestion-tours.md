# Gestión de Tours - AppCorredorEcologico

Este módulo gestiona la creación, administración y asignación de tours ecológicos en la plataforma. Incluye la relación entre usuarios (turistas, guías y administradores), tours, asignación de turistas y la gestión de recorridos.

## Estructura principal

- **Usuarios:**  
  Los roles principales son `tourist`, `guide` y `admin`. Los usuarios pueden registrarse y, según su rol, acceder a diferentes funcionalidades.
- **Tours:**  
  Los tours son creados por guías y pueden ser gestionados y aprobados por administradores. Incluyen información detallada como descripción, precio, duración, ubicación, etc.
- **Asignación de turistas:**  
  Los turistas pueden ser asignados a tours. El guía y el administrador pueden ver la lista de turistas asignados a cada tour.
- **Recorridos:**  
  Cada tour puede tener uno o más recorridos (puntos de interés).

## Funcionalidades principales

- **Creación y edición de tours:**  
  Los guías pueden crear y editar sus propios tours. Los administradores pueden aprobar, rechazar o revisar los tours.
- **Asignación de turistas a tours:**  
  Los turistas pueden ser asignados a tours por el administrador (o automáticamente). Los guías ven la lista de turistas en sus tours.
- **Gestión de perfiles y roles:**  
  Sistema de perfiles para turistas y guías, solicitudes para ser guía, con revisión por parte del administrador.
- **Seguridad y acceso:**  
  Uso de Row Level Security (RLS) y políticas para que cada usuario acceda solo a la información relevante para su rol.

## Estructura de tablas

- `users`: Usuarios del sistema (roles: turist, guide, admin)
- `tours`: Información básica y avanzada de los tours
- `asignar_tours`: Relación entre usuarios turistas y tours
- `guia`, `turista`: Perfiles extendidos según rol
- `recorrido`: Puntos de interés de cada tour
- `solicitudes_guia`: Solicitudes de usuarios para ser guías

## Consultas frecuentes

- **Turistas asignados a un tour:**
  ```sql
  SELECT id_turista, id_tour FROM asignar_tours WHERE id_tour = <id>;
  ```
- **Detalles de los turistas (nombre/correo):**
  ```sql
  SELECT u.name, u.email
  FROM asignar_tours a
  JOIN users u ON a.id_turista = u.id
  WHERE a.id_tour = <id>;
  ```
- **Tours creados por un guía:**
  ```sql
  SELECT * FROM tours WHERE id_guia = '<id_guia>';
  ```

## Seguridad

- **RLS y políticas:**  
  Los datos están protegidos para que solo los usuarios autorizados (guía, turista, admin) puedan ver o modificar la información relevante.
- **Acceso a la información:**  
  - El turista ve solo sus asignaciones.
  - El guía ve los turistas asignados a sus tours.
  - El admin puede gestionar todos los tours y usuarios.

## Requisitos

- Supabase configurado con las tablas y las políticas mostradas en `database_schema.sql`.
- Flutter (o cualquier frontend) puede consultar y mostrar la información usando los roles y relaciones de las tablas.

## Ejemplo de flujo

1. El guía crea un tour.
2. El administrador aprueba el tour.
3. Se asignan turistas al tour.
4. El guía consulta los turistas asignados en la pantalla de detalles del tour.
5. El turista ve sus tours asignados en su propio panel.

---

**¿Preguntas, sugerencias o necesitas ejemplos de consultas adicionales? Abre un issue o contacta a los administradores del repositorio.**