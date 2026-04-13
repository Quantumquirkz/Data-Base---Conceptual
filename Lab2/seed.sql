-- Datos de ejemplo (opcional) — ejecutar después de schema.sql

INSERT INTO agencia (nombre, ciudad, direccion, telefono) VALUES
    ('RENT A CAR Centro', 'San José', 'Av. Central 100', '2222-1111'),
    ('RENT A CAR Pacífico', 'Puntarenas', 'Malecón 45', '2666-2222'),
    ('RENT A CAR Atlántico', 'Limón', 'Calle 3, local 8', '2755-3333');

INSERT INTO cliente (nombre_completo, documento_id, email, telefono) VALUES
    ('María Fernández Solano', '1-2345-6789', 'maria.f@example.com', '8888-1001'),
    ('José Mora Rojas', '2-9876-5432', 'jose.m@example.com', '8888-1002');

INSERT INTO auto (placa, id_agencia, marca, modelo, anio) VALUES
    ('ABC-123', 1, 'Toyota', 'Corolla', 2022),
    ('XYZ-789', 1, 'Hyundai', 'Creta', 2023),
    ('LMN-456', 2, 'Nissan', 'Versa', 2021);

-- Alquiler de al menos 1 día (intervalo semicerrado [inicio, fin) en la exclusión)
INSERT INTO alquiler (id_cliente, placa, id_agencia_contrato, fecha_inicio, fecha_fin, notas) VALUES
    (1, 'ABC-123', 1, '2026-04-10 08:00:00+00', '2026-04-12 08:00:00+00', 'Cliente recoge en Centro'),
    (2, 'LMN-456', 2, '2026-05-01 10:00:00+00', '2026-05-15 10:00:00+00', 'Temporada alta — Pacífico');
