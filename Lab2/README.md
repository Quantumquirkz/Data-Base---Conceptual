# Lab 2 — RENT A CAR (modelo entidad–relación en PostgreSQL / Neon)

## Caso de estudio

La agencia **RENT A CAR** tiene varias agencias en el país. Un cliente puede hacer su reservación en **cualquier** sucursal. Cada sucursal dispone de un conjunto de autos; cada auto se identifica por **placa** y **pertenece a una agencia**. Debe registrarse el **tiempo de alquiler**: mínimo **un día** y **sin máximo** explícito en las reglas de negocio.

## Diagrama entidad–relación (conceptual)

```mermaid
erDiagram
    AGENCIA ||--o{ AUTO : "posee"
    CLIENTE ||--o{ ALQUILER : "realiza"
    AUTO    ||--o{ ALQUILER : "es_alquilado_en"
    AGENCIA ||--o{ ALQUILER : "formaliza_contrato"

    AGENCIA {
        int id_agencia PK
        string nombre
        string ciudad
        string direccion
        string telefono
    }

    CLIENTE {
        int id_cliente PK
        string nombre_completo
        string documento_id UK
        string email
        string telefono
    }

    AUTO {
        string placa PK
        int id_agencia FK
        string marca
        string modelo
        int anio
        bool activo
    }

    ALQUILER {
        int id_alquiler PK
        int id_cliente FK
        string placa FK
        int id_agencia_contrato FK
        timestamptz fecha_inicio
        timestamptz fecha_fin
        string notas
    }
```

## Justificación del modelo

1. **Agencia**  
   Representa cada sucursal en distintas partes del país. Atributos como ciudad y dirección permiten ubicar la flota y los puntos de atención. La clave sustituta `id_agencia` simplifica las referencias desde otras tablas.

2. **Cliente**  
   Independiente de la agencia: el enunciado indica que el cliente puede reservar en cualquier sucursal, por lo que **no** se modela una pertenencia fija del cliente a una sola agencia. `documento_id` único evita duplicados lógicos de persona.

3. **Auto**  
   La **placa** es el identificador natural y se usa como clave primaria, alineado con el caso. `id_agencia` implementa “pertenece a una agencia en particular”. `ON DELETE RESTRICT` evita borrar una agencia que aún tiene autos o historial vinculado sin antes reasignar o dar de baja vehículos.

4. **Alquiler**  
   Une cliente, vehículo y la **agencia donde se formaliza el contrato** (`id_agencia_contrato`), reflejando que la operación puede hacerse en cualquier sucursal aunque el auto “pertenezca” a otra agencia en la flota (caso típico de red nacional con contrato centralizado o traslado de flota; si en tu curso exigen que el auto solo se alquile en su agencia, se puede añadir una restricción `CHECK` o validación aplicativa).

5. **Tiempo de alquiler (mínimo un día, sin máximo)**  
   - **Mínimo un día**: restricción `fecha_fin >= fecha_inicio + INTERVAL '1 day'` (al menos 24 horas entre instantes).  
   - **Sin máximo**: no hay `CHECK` superior ni tipo enumerado que limite la duración.  
   - **Sin solapamiento del mismo auto**: restricción de exclusión con `tstzrange` (fechas con zona horaria) y extensión `btree_gist`, para que un vehículo no tenga dos alquileres concurrentes.

## Archivos en esta carpeta

| Archivo        | Descripción                                      |
|----------------|--------------------------------------------------|
| `schema.sql`   | DDL: tablas, índices, comentarios, restricciones |
| `seed.sql`     | Datos de ejemplo opcionales                      |
| `.env.example` | Plantilla para `DATABASE_URL` (no subir secretos)|

## Conexión a Neon (local)

1. Copia `.env.example` a `.env` y define `DATABASE_URL` con tu cadena de Neon.  
2. **No** subas `.env` al repositorio (está en `.gitignore`).  
3. Si la cadena incluye `channel_binding=require` y tu cliente `psql` falla, prueba la misma URL sin ese parámetro o actualiza el cliente.

Ejemplo de aplicación del esquema con **psql**:

```bash
cd Lab2
export $(grep -v '^#' .env | xargs)
psql "$DATABASE_URL" -f schema.sql
psql "$DATABASE_URL" -f seed.sql
```

Alternativa con **Node** (útil si no tienes `psql`; requiere Node instalado en tu sistema, no solo `npm` de Windows mezclado con rutas WSL):

```bash
cd Lab2
npm install
export DATABASE_URL='postgresql://USER:PASS@HOST/DB?sslmode=require'
node apply_neon.mjs          # solo DDL
node apply_neon.mjs --seed   # DDL + datos de ejemplo
node apply_neon.mjs --reset --seed   # DROP de tablas del lab, luego DDL + semilla
```

Para reinstalar desde cero en un entorno de prueba: `psql "$DATABASE_URL" -f schema_drop.sql` y luego vuelve a ejecutar `schema.sql`, o usa `node apply_neon.mjs --reset --seed`.

## Seguridad

Si la cadena de conexión con contraseña se compartió en un chat o documento público, **rota la contraseña** en el panel de Neon y actualiza tu `.env`.
