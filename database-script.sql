-- ===========================================
-- 1. Tabla principal de usuarios
-- ===========================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    role TEXT NOT NULL CHECK (role IN ('tourist', 'guide', 'admin')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ===========================================
-- 2. Tabla de perfil turista
-- ===========================================
CREATE TABLE turista (
    id SERIAL PRIMARY KEY,
    id_usuario UUID REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ===========================================
-- 3. Tabla de perfil guía
-- ===========================================
CREATE TABLE guia (
    id SERIAL PRIMARY KEY,
    id_usuario UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    especialidad TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- ===========================================
-- 4. Tabla de solicitudes para ser guía
-- ===========================================
CREATE TABLE solicitudes_guia (
    id SERIAL PRIMARY KEY,
    id_usuario UUID REFERENCES users(id) ON DELETE CASCADE,
    nombre TEXT NOT NULL,
    email TEXT NOT NULL,
    especialidad TEXT NOT NULL,
    estado TEXT NOT NULL CHECK (estado IN ('pendiente', 'aprobada', 'rechazada')),
    motivo_rechazo TEXT,
    fecha_solicitud TIMESTAMP WITH TIME ZONE DEFAULT now(),
    fecha_respuesta TIMESTAMP WITH TIME ZONE,
    id_admin_revisor UUID REFERENCES users(id)
);

-- ===========================================
-- 5. Índices sugeridos para búsquedas rápidas
-- ===========================================
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_solicitud_usuario_estado ON solicitudes_guia(id_usuario, estado);

-- ===========================================
-- 6. Usuario administrador por defecto
-- ===========================================
INSERT INTO users (name, email, role)
VALUES ('Administrador', 'admin@email.com', 'admin');

-- ===========================================
-- 7. Habilitar Row Level Security (RLS)
-- ===========================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE turista ENABLE ROW LEVEL SECURITY;
ALTER TABLE guia ENABLE ROW LEVEL SECURITY;
ALTER TABLE solicitudes_guia ENABLE ROW LEVEL SECURITY;

-- ===========================================
-- 8. Políticas de seguridad recomendadas
-- ===========================================

-- USERS
-- Cada usuario puede gestionar su propio registro
CREATE POLICY "Users can manage own data" ON users
    FOR ALL USING (auth.uid() = id);

-- El admin puede gestionar todos los usuarios
CREATE POLICY "Admin can manage users" ON users
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'
        )
    );

-- TURISTA
-- El usuario puede gestionar su propio perfil de turista
CREATE POLICY "Tourist can manage own profile" ON turista
    FOR ALL USING (auth.uid() = id_usuario);

-- El admin puede gestionar todos los perfiles de turista
CREATE POLICY "Admin can manage turista" ON turista
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'
        )
    );

-- GUIA
-- El usuario puede gestionar su propio perfil de guía
CREATE POLICY "Guide can manage own profile" ON guia
    FOR ALL USING (auth.uid() = id_usuario);

-- El admin puede gestionar todos los perfiles de guía
CREATE POLICY "Admin can manage guia" ON guia
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'
        )
    );

-- SOLICITUDES_GUIA
-- El usuario puede crear su propia solicitud
CREATE POLICY "User can create own solicitud" ON solicitudes_guia
    FOR INSERT WITH CHECK (auth.uid() = id_usuario);

-- El usuario puede ver sus propias solicitudes
CREATE POLICY "User can view own solicitud" ON solicitudes_guia
    FOR SELECT USING (auth.uid() = id_usuario);

-- El admin puede gestionar todas las solicitudes
CREATE POLICY "Admin can manage solicitudes" ON solicitudes_guia
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'
        )
    );

-- ===========================================
-- 9. (Opcional) Ejemplo de revocación de acceso público
-- ===========================================
REVOKE ALL ON TABLE users FROM PUBLIC;
REVOKE ALL ON TABLE turista FROM PUBLIC;
REVOKE ALL ON TABLE guia FROM PUBLIC;
REVOKE ALL ON TABLE solicitudes_guia FROM PUBLIC;