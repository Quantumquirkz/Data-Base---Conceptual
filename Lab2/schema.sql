-- RENT A CAR — modelo relacional (PostgreSQL / Neon)
-- Caso de estudio Lab2: agencias nacionales, reservas en cualquier sucursal,
-- autos por placa pertenecientes a una agencia, duración mínima 1 día.

CREATE EXTENSION IF NOT EXISTS btree_gist;

-- Sucursales en el país
CREATE TABLE agencia (
    id_agencia   SERIAL PRIMARY KEY,
    nombre       VARCHAR(120) NOT NULL,
    ciudad       VARCHAR(80)  NOT NULL,
    direccion    VARCHAR(200),
    telefono     VARCHAR(40),
    creado_en    TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_agencia_nombre_ciudad UNIQUE (nombre, ciudad)
);

-- Clientes que pueden alquilar en cualquier agencia
CREATE TABLE cliente (
    id_cliente        SERIAL PRIMARY KEY,
    nombre_completo   VARCHAR(160) NOT NULL,
    documento_id      VARCHAR(32)  NOT NULL UNIQUE,
    email             VARCHAR(160),
    telefono          VARCHAR(40),
    creado_en         TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Un auto por placa; pertenece a una agencia concreta
CREATE TABLE auto (
    placa        VARCHAR(20) PRIMARY KEY,
    id_agencia   INTEGER NOT NULL REFERENCES agencia (id_agencia) ON DELETE RESTRICT ON UPDATE CASCADE,
    marca        VARCHAR(60)  NOT NULL,
    modelo       VARCHAR(60)  NOT NULL,
    anio         SMALLINT,
    activo       BOOLEAN NOT NULL DEFAULT true,
    creado_en    TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_auto_anio CHECK (anio IS NULL OR (anio >= 1980 AND anio <= 2100))
);

CREATE INDEX idx_auto_agencia ON auto (id_agencia);

-- Alquiler/reserva: cliente + vehículo + agencia donde se gestiona el contrato
CREATE TABLE alquiler (
    id_alquiler        SERIAL PRIMARY KEY,
    id_cliente         INTEGER NOT NULL REFERENCES cliente (id_cliente) ON DELETE RESTRICT ON UPDATE CASCADE,
    placa              VARCHAR(20) NOT NULL REFERENCES auto (placa) ON DELETE RESTRICT ON UPDATE CASCADE,
    id_agencia_contrato INTEGER NOT NULL REFERENCES agencia (id_agencia) ON DELETE RESTRICT ON UPDATE CASCADE,
    fecha_inicio       TIMESTAMPTZ NOT NULL,
    fecha_fin          TIMESTAMPTZ NOT NULL,
    notas              VARCHAR(500),
    creado_en          TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_alquiler_duracion_minima
        CHECK (fecha_fin >= fecha_inicio + INTERVAL '1 day')
);

CREATE INDEX idx_alquiler_cliente ON alquiler (id_cliente);
CREATE INDEX idx_alquiler_placa ON alquiler (placa);
CREATE INDEX idx_alquiler_agencia ON alquiler (id_agencia_contrato);

-- Mismo auto no puede estar alquilado en intervalos que se solapen
ALTER TABLE alquiler
    ADD CONSTRAINT alquiler_sin_solapamiento
    EXCLUDE USING gist (
        placa WITH =,
        tstzrange(fecha_inicio, fecha_fin, '[)') WITH &&
    );

COMMENT ON TABLE agencia IS 'Sucursales RENT A CAR en distintas ciudades del país.';
COMMENT ON TABLE cliente IS 'Personas que pueden reservar en cualquier agencia.';
COMMENT ON TABLE auto IS 'Vehículo identificado por placa; siempre asignado a una agencia.';
COMMENT ON TABLE alquiler IS 'Contrato de alquiler: duración mínima 24h; sin límite superior en el modelo.';
COMMENT ON COLUMN alquiler.id_agencia_contrato IS 'Agencia donde se formaliza el alquiler (cualquier sucursal del país).';
