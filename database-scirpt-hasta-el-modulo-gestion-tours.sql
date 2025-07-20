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
-- 5. Tabla de tours
-- ===========================================
CREATE TABLE tours (
    id SERIAL PRIMARY KEY,
    id_guia UUID REFERENCES users(id),
    titulo TEXT NOT NULL,
    descripcion TEXT NOT NULL,
    precio DOUBLE PRECISION NOT NULL,
    duracion_horas INT NOT NULL,
    ubicacion TEXT NOT NULL,
    categoria TEXT NOT NULL,
    estado TEXT NOT NULL CHECK (estado IN ('pendiente', 'aprobado', 'rechazado', 'inactivo')),
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT now(),
    fecha_aprobacion TIMESTAMP WITH TIME ZONE,
    id_admin_revisor UUID REFERENCES users(id),
    max_personas INT NOT NULL,
    incluye TEXT[],           -- Array de textos
    no_incluye TEXT[],        -- Array de textos
    requisitos TEXT,
    punto_encuentro TEXT NOT NULL,
    imagenes TEXT[],          -- Array de textos (URLs de imágenes)
    red_social TEXT,
    telefono TEXT
);

-- ===========================================
-- 6. Tabla de asignación de turistas a tours
-- ===========================================
CREATE TABLE asignar_tours (
    id SERIAL PRIMARY KEY,
    id_turista UUID REFERENCES users(id) ON DELETE CASCADE,
    id_tour INT REFERENCES tours(id) ON DELETE CASCADE,
    fecha TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- ===========================================
-- 7. Tabla de recorridos (opcional, ejemplo)
-- ===========================================
CREATE TABLE recorrido (
    id SERIAL PRIMARY KEY,
    id_tour INT REFERENCES tours(id) ON DELETE CASCADE,
    nombre TEXT NOT NULL,
    descripcion TEXT,
    orden INT NOT NULL
);

-- ===========================================
-- 8. Índices sugeridos para búsquedas rápidas
-- ===========================================
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_solicitud_usuario_estado ON solicitudes_guia(id_usuario, estado);
CREATE INDEX idx_tours_categoria ON tours(categoria);
CREATE INDEX idx_asignar_tours_tour ON asignar_tours(id_tour);
CREATE INDEX idx_asignar_tours_turista ON asignar_tours(id_turista);

-- ===========================================
-- 9. Usuario administrador por defecto
-- ===========================================
INSERT INTO users (name, email, role)
VALUES ('Administrador', 'admin@email.com', 'admin');

-- ===========================================
-- 10. Habilitar Row Level Security (RLS)
-- ===========================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE turista ENABLE ROW LEVEL SECURITY;
ALTER TABLE guia ENABLE ROW LEVEL SECURITY;
ALTER TABLE solicitudes_guia ENABLE ROW LEVEL SECURITY;
ALTER TABLE tours ENABLE ROW LEVEL SECURITY;
ALTER TABLE asignar_tours ENABLE ROW LEVEL SECURITY;
ALTER TABLE recorrido ENABLE ROW LEVEL SECURITY;

-- ===========================================
-- 11. Políticas de seguridad recomendadas
-- ===========================================

-- USERS
CREATE POLICY "Users can manage own data" ON users
    FOR ALL USING (auth.uid() = id);

CREATE POLICY "Admin can manage users" ON users
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'
        )
    );

-- TURISTA
CREATE POLICY "Tourist can manage own profile" ON turista
    FOR ALL USING (auth.uid() = id_usuario);

CREATE POLICY "Admin can manage turista" ON turista
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'
        )
    );

-- GUIA
CREATE POLICY "Guide can manage own profile" ON guia
    FOR ALL USING (auth.uid() = id_usuario);

CREATE POLICY "Admin can manage guia" ON guia
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'
        )
    );

-- SOLICITUDES_GUIA
CREATE POLICY "User can create own solicitud" ON solicitudes_guia
    FOR INSERT WITH CHECK (auth.uid() = id_usuario);

CREATE POLICY "User can view own solicitud" ON solicitudes_guia
    FOR SELECT USING (auth.uid() = id_usuario);

CREATE POLICY "Admin can manage solicitudes" ON solicitudes_guia
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'
        )
    );

-- TOURS
CREATE POLICY "Guide can manage own tours" ON tours
    FOR ALL USING (auth.uid() = id_guia);

CREATE POLICY "Admin can manage tours" ON tours
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'
        )
    );

-- ASIGNAR_TOURS
CREATE POLICY "Tourist can view own assignments" ON asignar_tours
    FOR SELECT USING (auth.uid() = id_turista);

CREATE POLICY "Guide can view assignments for own tours" ON asignar_tours
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM tours t WHERE t.id = asignar_tours.id_tour AND t.id_guia = auth.uid()
        )
    );

CREATE POLICY "Admin can manage assignments" ON asignar_tours
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'
        )
    );

-- RECORRIDO
CREATE POLICY "Guide can manage recorridos of own tours" ON recorrido
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM tours t WHERE t.id = recorrido.id_tour AND t.id_guia = auth.uid()
        )
    );

CREATE POLICY "Admin can manage recorridos" ON recorrido
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users u WHERE u.id = auth.uid() AND u.role = 'admin'
        )
    );

-- ===========================================
-- 12. (Opcional) Ejemplo de revocación de acceso público
-- ===========================================
REVOKE ALL ON TABLE users FROM PUBLIC;
REVOKE ALL ON TABLE turista FROM PUBLIC;
REVOKE ALL ON TABLE guia FROM PUBLIC;
REVOKE ALL ON TABLE solicitudes_guia FROM PUBLIC;
REVOKE ALL ON TABLE tours FROM PUBLIC;
REVOKE ALL ON TABLE asignar_tours FROM PUBLIC;
REVOKE ALL ON TABLE recorrido FROM PUBLIC;