# Laboratorio 2 — Modelado de datos para el sistema RENT A CAR

**Ámbito:** diseño de bases de datos relacionales.  
**Motor de implementación:** PostgreSQL (despliegue en Neon).  
**Artefactos asociados:** definición del esquema en [`schema.sql`](schema.sql), datos semilla en [`seed.sql`](seed.sql).

## Resumen

Este documento constituye la memoria técnica del laboratorio. Se expone el **caso de estudio RENT A CAR**, se distingue el **modelo conceptual**, el **modelo entidad–relación lógico** y el **modelo físico** implementado, se **fundamentan** las decisiones de diseño y se establece la **trazabilidad** entre el enunciado y el esquema relacional. Asimismo, se describen los archivos del repositorio y el procedimiento de despliegue contra el gestor.

## Índice de contenidos

1. [Caso de estudio](#caso-de-estudio)
2. [Introducción](#introducción)
3. [Marco teórico](#marco-teórico-tres-niveles-de-modelado)
4. [Modelo conceptual](#1-modelo-conceptual)
5. [Modelo ER lógico](#2-modelo-er-lógico)
6. [Fundamentación del modelo](#fundamentación-del-modelo-de-datos)
7. [Modelo físico](#3-modelo-físico-postgresql--neon)
8. [Trazabilidad: enunciado y modelo](#4-trazabilidad-enunciado-y-modelo)
9. [Archivos del repositorio](#archivos-del-repositorio)
10. [Metodología: del diseño al despliegue en Neon](#metodología-del-diseño-al-despliegue-en-neon)
11. [Despliegue y conexión a Neon](#despliegue-y-conexión-a-neon)

---

## Caso de estudio

A continuación se resume el planteamiento del problema tal como se formula en la actividad. Constituye la **especificación de requisitos** sobre la que se construyen los modelos posteriores.

La agencia **RENT A CAR** opera mediante **varias sucursales** distribuidas en el territorio. Un **cliente** puede efectuar su **reservación** (alquiler) en **cualquiera** de dichas sucursales. Cada sucursal dispone de una **flota** acotada de vehículos en condiciones de alquiler. Los **automóviles** se identifican de manera unívoca por su **placa** y **pertenecen** a una **agencia** determinada. El sistema debe registrar el **intervalo temporal** del alquiler: la duración mínima es de **un día**; no se establece, en el marco del enunciado, un límite máximo explícito.

---

## Introducción

Con el fin de separar el **qué** del dominio del **cómo** se materializa en el sistema gestor, el dominio **RENT A CAR** se documenta en **tres niveles**: **conceptual**, **entidad–relación lógico** y **físico**. Dicha estrategia es coherente con la práctica académica y profesional de refinamiento progresivo del diseño. La correspondencia con el producto implementado se verifica mediante el lenguaje de definición de datos (DDL) recogido en [`schema.sql`](schema.sql), ejecutable sobre PostgreSQL (p. ej., instancia Neon).

---

## Marco teórico: tres niveles de modelado

En ingeniería de datos, el diseño se suele **refinar de forma descendente** (*top-down*): desde la descripción del dominio aplicable hasta el esquema desplegable en un sistema gestor de bases de datos concreto.

*Tabla 1. Caracterización de los niveles de modelado empleados en este laboratorio.*

| Nivel | Enfoque | Incluye típicamente | Excluye o minimiza |
|--------|---------|----------------------|---------------------|
| **Conceptual** | Negocio y reglas | Entidades, relaciones, **cardinalidades** (1:1, 1:N, N:M), atributos esenciales en términos del dominio | Tipos SQL, claves sustitutas (`SERIAL`), índices, extensiones del motor |
| **ER lógico** | Estructura de datos (independiente del SGBD) | Entidades, atributos, identificadores, cardinalidades, **dominios genéricos** (texto, entero, fecha/hora, booleano) | `VARCHAR(120)`, `SERIAL`, políticas exactas `ON DELETE`, extensiones como `btree_gist` |
| **Físico** | Implementación en un motor (aquí **PostgreSQL**) | Nombres de tablas/columnas, tipos concretos, `PK`/`FK`/`UNIQUE`/`CHECK`/`EXCLUDE`, índices, extensiones | Detalle de procesos de negocio no persistidos |

**Nomenclatura.** En la literatura y en la docencia, el término **diagrama entidad–relación** suele asociarse al **modelo lógico** (entidades, relaciones, atributos e identificadores). El **modelo conceptual** permanece más próximo al léxico del negocio. El **modelo físico** es el que materializa el esquema mediante DDL y mecanismos propios del motor (tipos, índices, restricciones avanzadas).

**Relación entre niveles.** El nivel conceptual delimita *qué* entidades y vínculos son relevantes; el lógico especifica *atributos, cardinalidades y dominios* de forma relativamente independiente del SGBD; el físico concreta *tipos, integridad referencial, índices y optimizaciones* admisibles en PostgreSQL.

---

## 1. Modelo conceptual

### Objetivo del nivel conceptual

Representar las **reglas del dominio** y el **vocabulario de negocio** sin adscribir aún la solución a tablas, tipos SQL ni decisiones de implementación. Permite contrastar el modelo con el enunciado y con posibles interesados del dominio.

### Cardinalidades y relaciones (lenguaje natural)

- Una **Agencia** (sucursal) **posee** muchos **Autos** (1:N). Cada auto pertenece a **una** agencia.
- Un **Cliente** puede realizar **muchos Alquileres** (1:N); cada alquiler es de **un** cliente.
- Un **Auto** participa en **muchos Alquileres** a lo largo del tiempo (1:N); cada alquiler usa **un** auto.
- Un **Alquiler** se **formaliza** en **una** agencia (cualquiera de la red), reflejando que la reserva puede hacerse en cualquier sucursal: la relación **Agencia–Alquiler** es 1:N (una agencia formaliza muchos contratos).

### Reglas de negocio reflejadas conceptualmente

- El periodo de alquiler tiene **duración mínima de un día**; no se fija un máximo en el modelo.
- Un mismo vehículo **no** debería estar alquilado en dos periodos que se solapen (regla de integridad temporal, que en el físico se implementa con una restricción de exclusión).

### Diagrama conceptual

En la **Figura 1** (notación Mermaid, diagrama entidad–relación de alto nivel) se omiten detalles de implementación: los atributos son **reducidos** y las etiquetas de las asociaciones expresan la **semántica** del vínculo. Las anotaciones `string` y `datetime` aluden a **dominios informales** con fines ilustrativos, no a tipos del motor.

```mermaid
erDiagram
    Agencia ||--o{ Auto : posee
    Cliente ||--o{ Alquiler : realiza
    Auto ||--o{ Alquiler : incluye_en_contrato
    Agencia ||--o{ Alquiler : formaliza

    Agencia {
        string nombre_sucursal
        string ciudad
    }

    Cliente {
        string nombre
        string documento
    }

    Auto {
        string placa
    }

    Alquiler {
        datetime inicio_periodo
        datetime fin_periodo
    }
```

---

## 2. Modelo ER lógico

### Objetivo del modelo lógico

Especificar la **estructura de información** mediante entidades, atributos, identificadores y cardinalidades, utilizando **dominios genéricos**. El resultado debe ser **trasladable** a distintos sistemas relacionales conservando la semántica.

### Decisiones de diseño en este nivel

- **Agencia** y **Cliente** llevan un **identificador surrogate** (entero único) además de sus datos descriptivos, para simplificar referencias en **Alquiler** y **Auto**.
- **Auto** usa **placa** como identificador natural principal en el diagrama lógico (coincide con el enunciado).
- **Alquiler** vincula cliente, auto, agencia de formalización y el intervalo **inicio/fin** del alquiler.

### Diagrama ER lógico

La **Figura 2** recoge el modelo lógico. Los dominios se anotan como `int`, `string`, `datetime` y `boolean` por **compatibilidad con la herramienta de diagramación**; no deben confundirse con los tipos concretos de PostgreSQL del modelo físico.

```mermaid
erDiagram
    AGENCIA ||--o{ AUTO : posee
    CLIENTE ||--o{ ALQUILER : realiza
    AUTO ||--o{ ALQUILER : es_objeto_de
    AGENCIA ||--o{ ALQUILER : formaliza_contrato

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
        boolean activo
    }

    ALQUILER {
        int id_alquiler PK
        int id_cliente FK
        string placa FK
        int id_agencia_contrato FK
        datetime fecha_inicio
        datetime fecha_fin
        string notas
    }
```

---

## Fundamentación del modelo de datos

A continuación se argumenta la idoneidad de las entidades, claves y restricciones adoptadas, en coherencia con el enunciado y con los principios de modelado relacional.

1. **Entidad Agencia**  
   Modela cada **sucursal** como unidad operativa. Los atributos de ubicación y contacto permiten identificar el contexto geográfico de la flota. El identificador sustituto `id_agencia` reduce la complejidad de las referencias en el esquema físico.

2. **Entidad Cliente**  
   Se mantiene **ajena** a una agencia de pertenencia fija, dado que el enunciado permite reservar en **cualquier** sucursal. El atributo `documento_id` con unicidad asegura la **identificación lógica** de la persona frente a homónimos o registros duplicados.

3. **Entidad Auto**  
   La **placa** actúa como **identificador natural** y clave primaria, conforme al caso. La dependencia funcional respecto de la agencia propietaria se expresa mediante `id_agencia`. La política `ON DELETE RESTRICT` sobre la agencia preserva la **integridad referencial** ante bajas indebidas mientras existan vehículos o historial asociado.

4. **Entidad Alquiler**  
   Constituye la asociación reificada entre **cliente**, **vehículo** y **agencia de formalización del contrato** (`id_agencia_contrato`). Ello satisface el requisito de contratación en cualquier sucursal, **sin exigir** coincidencia entre la agencia propietaria del vehículo y la agencia que registra el contrato (escenario plausible en redes nacionales). Una variante de diseño, no impuesta aquí, podría restringir mediante `CHECK` que ambas coincidan.

5. **Reglas temporales y de concurrencia lógica del vehículo**  
   - **Duración mínima:** se formaliza con `fecha_fin >= fecha_inicio + INTERVAL '1 day'`.  
   - **Ausencia de duración máxima:** no se declara límite superior en el esquema.  
   - **No solapamiento de alquileres para un mismo vehículo:** se implementa mediante restricción de **exclusión** sobre rangos `tstzrange`, con soporte de la extensión `btree_gist`.

---

## 3. Modelo físico (PostgreSQL / Neon)

### Objetivo del modelo físico

Documentar la **realización concreta** del esquema en PostgreSQL: convención de nombres (`snake_case`, tablas en minúsculas), **tipos de datos**, **nulidad**, **integridad referencial**, **índices** y **restricciones declarativas** adicionales, según el artefacto [`schema.sql`](schema.sql).

### Extensiones y restricciones globales

- **`CREATE EXTENSION btree_gist`:** necesaria para la restricción de **exclusión** que evita solapamiento de alquileres del mismo auto sobre rangos de tiempo.
- **`chk_alquiler_duracion_minima`:** `fecha_fin >= fecha_inicio + INTERVAL '1 day'` — al menos 24 horas entre instantes (regla “mínimo un día” en el modelo físico).
- **`alquiler_sin_solapamiento`:** `EXCLUDE USING gist` con `placa` y `tstzrange(fecha_inicio, fecha_fin, '[)')` — el mismo `placa` no puede tener dos intervalos de alquiler que se intersecten (intervalo semiabierto coherente con el `CHECK` de duración).

### Diagrama físico (Figura 3 — vista ER con tipos PostgreSQL)

```mermaid
erDiagram
    agencia ||--o{ auto : ""
    cliente ||--o{ alquiler : ""
    auto ||--o{ alquiler : ""
    agencia ||--o{ alquiler : ""

    agencia {
        serial id_agencia PK
        varchar nombre
        varchar ciudad
        varchar direccion
        varchar telefono
        timestamptz creado_en
    }

    cliente {
        serial id_cliente PK
        varchar nombre_completo
        varchar documento_id UK
        varchar email
        varchar telefono
        timestamptz creado_en
    }

    auto {
        varchar placa PK
        integer id_agencia FK
        varchar marca
        varchar modelo
        smallint anio
        boolean activo
        timestamptz creado_en
    }

    alquiler {
        serial id_alquiler PK
        integer id_cliente FK
        varchar placa FK
        integer id_agencia_contrato FK
        timestamptz fecha_inicio
        timestamptz fecha_fin
        varchar notas
        timestamptz creado_en
    }
```

*Nota:* En Mermaid no se grafican todas las restricciones nombradas (`CHECK`, `EXCLUDE`, `UNIQUE` compuesto); el detalle completo está en las tablas siguientes y en el DDL.

### Tabla `agencia`

| Columna | Tipo | Nulidad | Restricciones / notas |
|---------|------|---------|------------------------|
| `id_agencia` | `SERIAL` | NOT NULL | PK (implícita) |
| `nombre` | `VARCHAR(120)` | NOT NULL | |
| `ciudad` | `VARCHAR(80)` | NOT NULL | |
| `direccion` | `VARCHAR(200)` | NULL | |
| `telefono` | `VARCHAR(40)` | NULL | |
| `creado_en` | `TIMESTAMPTZ` | NOT NULL | DEFAULT `now()` |

**Otras:** `UNIQUE (nombre, ciudad)` — `uq_agencia_nombre_ciudad`.

### Tabla `cliente`

| Columna | Tipo | Nulidad | Restricciones / notas |
|---------|------|---------|------------------------|
| `id_cliente` | `SERIAL` | NOT NULL | PK |
| `nombre_completo` | `VARCHAR(160)` | NOT NULL | |
| `documento_id` | `VARCHAR(32)` | NOT NULL | `UNIQUE` |
| `email` | `VARCHAR(160)` | NULL | |
| `telefono` | `VARCHAR(40)` | NULL | |
| `creado_en` | `TIMESTAMPTZ` | NOT NULL | DEFAULT `now()` |

### Tabla `auto`

| Columna | Tipo | Nulidad | Restricciones / notas |
|---------|------|---------|------------------------|
| `placa` | `VARCHAR(20)` | NOT NULL | PK |
| `id_agencia` | `INTEGER` | NOT NULL | FK → `agencia(id_agencia)`, `ON DELETE RESTRICT`, `ON UPDATE CASCADE` |
| `marca` | `VARCHAR(60)` | NOT NULL | |
| `modelo` | `VARCHAR(60)` | NOT NULL | |
| `anio` | `SMALLINT` | NULL | `CHECK`: NULL o entre 1980 y 2100 — `chk_auto_anio` |
| `activo` | `BOOLEAN` | NOT NULL | DEFAULT `true` |
| `creado_en` | `TIMESTAMPTZ` | NOT NULL | DEFAULT `now()` |

**Índice:** `idx_auto_agencia` en `(id_agencia)`.

### Tabla `alquiler`

| Columna | Tipo | Nulidad | Restricciones / notas |
|---------|------|---------|------------------------|
| `id_alquiler` | `SERIAL` | NOT NULL | PK |
| `id_cliente` | `INTEGER` | NOT NULL | FK → `cliente`, `RESTRICT` / `CASCADE` update |
| `placa` | `VARCHAR(20)` | NOT NULL | FK → `auto(placa)`, `RESTRICT` / `CASCADE` update |
| `id_agencia_contrato` | `INTEGER` | NOT NULL | FK → `agencia`, agencia donde se formaliza el contrato |
| `fecha_inicio` | `TIMESTAMPTZ` | NOT NULL | |
| `fecha_fin` | `TIMESTAMPTZ` | NOT NULL | |
| `notas` | `VARCHAR(500)` | NULL | |
| `creado_en` | `TIMESTAMPTZ` | NOT NULL | DEFAULT `now()` |

**Restricciones adicionales:**

- `chk_alquiler_duracion_minima`: `fecha_fin >= fecha_inicio + INTERVAL '1 day'`.
- `alquiler_sin_solapamiento`: exclusión GiST sobre `(placa, tstzrange(fecha_inicio, fecha_fin, '[)'))` para impedir solapamientos por el mismo vehículo.

**Índices:** `idx_alquiler_cliente`, `idx_alquiler_placa`, `idx_alquiler_agencia` (sobre `id_agencia_contrato`).

---

## 4. Trazabilidad: enunciado y modelo

*Tabla 2. Correspondencia entre requisitos del enunciado y elementos del esquema.*

| Requisito del caso de estudio | Dónde se refleja |
|------------------------------|------------------|
| Varias agencias / sucursales en el país | Entidad **Agencia** / tabla `agencia` |
| Reservación en cualquier agencia | `alquiler.id_agencia_contrato` (agencia que formaliza el contrato), sin vínculo obligatorio cliente–agencia fijo |
| Autos en cada sucursal en cantidad determinada (flota) | Relación 1:N **Agencia–Auto** / FK `auto.id_agencia` |
| Auto identificado por placa y perteneciente a una agencia | PK `auto.placa`, FK `auto.id_agencia` |
| Registrar tiempo de alquiler | `alquiler.fecha_inicio`, `alquiler.fecha_fin` (`TIMESTAMPTZ`) |
| Mínimo un día | `chk_alquiler_duracion_minima` |
| Sin máximo explícito | Ausencia de límite superior en `CHECK` o tipo enumerado |
| Un auto no alquilado dos veces a la vez | `alquiler_sin_solapamiento` + extensión `btree_gist` |

---

## Archivos del repositorio

*Tabla 3. Inventario de archivos relevantes en el directorio del laboratorio.*

| Archivo | Descripción |
|---------|-------------|
| `Doc_Lab2.md` | Memoria del laboratorio: caso de estudio, modelos, fundamentación, trazabilidad, metodología y despliegue |
| `schema.sql` | DDL: tablas, índices, comentarios y restricciones |
| `schema_drop.sql` | Script de eliminación de objetos del laboratorio (reinstalación limpia) |
| `seed.sql` | Conjunto de datos semilla para pruebas |
| `apply_neon.mjs` | Utilidad en Node.js para aplicar `schema.sql` y, opcionalmente, `seed.sql` |
| `package.json` | Manifiesto de dependencias (`pg`) del script anterior |
| `.env.example` | Plantilla de variable `DATABASE_URL` (no versionar credenciales) |

---

## Metodología: del diseño al despliegue en Neon

Esta sección describe **cómo se construyó la solución** en el laboratorio: desde el planteamiento del modelo hasta la base operativa en **Neon**, y en qué sentido se “sube” o **materializa** el esquema en la nube.

### 1. Del enunciado al modelo físico

El punto de partida es el **caso de estudio** (requisitos de negocio). A partir de ellos se elaboró, de forma **descendente**, la documentación en tres niveles (véanse las secciones anteriores):

1. **Modelo conceptual:** entidades, relaciones y reglas sin atarse a un gestor concreto.  
2. **Modelo ER lógico:** atributos, identificadores y cardinalidades con dominios genéricos.  
3. **Modelo físico:** correspondencia con tablas, tipos PostgreSQL, claves, índices y restricciones (`CHECK`, `EXCLUDE`, etc.).

El artefacto que **formaliza** el modelo físico en lenguaje ejecutable es el script [**`schema.sql`**](schema.sql): contiene el `CREATE EXTENSION`, las `CREATE TABLE`, las `REFERENCES`, los índices y las restricciones nombradas. El archivo [**`seed.sql`**](seed.sql) añade **datos semilla** opcionales para pruebas, no forma parte del requisito mínimo de estructura.

### 2. Por qué Neon y qué papel cumple

**Neon** es un servicio de **PostgreSQL alojado** (base de datos relacional en la nube, compatible con el protocolo y el dialecto habituales de PostgreSQL). En este laboratorio cumple dos funciones:

- **Motor objetivo:** el DDL fue escrito para PostgreSQL (tipos como `SERIAL`, `TIMESTAMPTZ`, extensión `btree_gist` para la restricción de exclusión temporal, etc.).  
- **Entorno accesible:** se obtiene una instancia sin instalar PostgreSQL localmente; la conexión se realiza mediante una **URI** (`DATABASE_URL`) con TLS (`sslmode=require`).

Neon **no** sustituye al modelo ni “interpreta” diagramas: solo **ejecuta** el SQL que se le envía. La “base de datos en Neon” es, por tanto, el **resultado de aplicar** `schema.sql` (y, si aplica, `seed.sql`) contra un **proyecto** y una **base** creados en el panel de Neon.

### 3. Qué significa “subir” la base de datos a Neon

En este contexto **no** se trata de subir un fichero `.sql` mediante un explorador de archivos como único paso, sino de **crear el esquema en el servidor** ejecutando el DDL por una **sesión de cliente** conectada a Neon.

En la práctica el flujo es:

1. **Crear** (o reutilizar) un proyecto en [Neon](https://neon.tech) y una **base de datos** (por ejemplo `rentacardb`).  
2. **Copiar** la cadena de conexión que ofrece el panel (formato URI PostgreSQL), con usuario, host, nombre de base y contraseña.  
3. **Configurar** localmente la variable `DATABASE_URL` (p. ej. en un archivo `.env` no versionado, a partir de `.env.example`).  
4. **Ejecutar** los scripts contra esa URI: el cliente (`psql` o `apply_neon.mjs`) envía las sentencias a Neon; el servidor crea extensiones, tablas, índices y restricciones **in situ**.

Así, la base “queda en Neon” porque **los objetos DDL se han aplicado** en esa instancia. Los datos de `seed.sql`, si se cargan, se insertan en las mismas tablas ya creadas.

### 4. Cómo se ejecutó y cómo repetirlo

Las dos vías usadas en el laboratorio son:

| Vía | Rol | Idea general |
|-----|-----|----------------|
| **`psql`** | Cliente oficial de línea de órdenes | Lee `schema.sql` / `seed.sql` y los envía por la conexión TLS a Neon. |
| **`apply_neon.mjs`** | Script Node.js con la librería `pg` | Lee los mismos ficheros y ejecuta su contenido programáticamente; admite `--seed` y `--reset` (este último ejecuta antes `schema_drop.sql` para vaciar tablas del laboratorio). |

En ambos casos el **orden lógico** es: (0) opcionalmente `schema_drop.sql` si se desea partir de cero; (1) `schema.sql`; (2) `seed.sql` si se desean datos de prueba.

Tras la ejecución, en el **SQL Editor** del panel de Neon (o con cualquier cliente SQL) pueden listarse las tablas (`\dt` en `psql`) y ejecutarse consultas `SELECT` para **verificar** la carga.

### 5. Relación entre repositorio y nube

El **repositorio Git** conserva la **fuente de verdad** del diseño (`Doc_Lab2.md`, `schema.sql`, etc.). La instancia en Neon es el **estado desplegado** de ese esquema en un momento dado: si se altera solo en la nube sin actualizar el repo, o viceversa, ambos pueden **divergir**. La práctica recomendada es aplicar siempre los scripts versionados para reproducir el despliegue.

---

## Despliegue y conexión a Neon

Para reproducir el esquema en un servicio PostgreSQL (p. ej., Neon), se recomienda parametrizar la conexión mediante variable de entorno.

1. Duplicar `.env.example` como `.env` y asignar `DATABASE_URL` según la cadena facilitada por el proveedor.  
2. Excluir `.env` del control de versiones (el repositorio ya contempla `.gitignore` a tal efecto).  
3. Si el cliente `psql` rechaza `channel_binding=require`, utilizar una cadena sin dicho parámetro o actualizar el cliente.

**Ejecución mediante cliente `psql`:**

```bash
cd Lab2
export $(grep -v '^#' .env | xargs)
psql "$DATABASE_URL" -f schema.sql
psql "$DATABASE_URL" -f seed.sql
```

**Ejecución mediante entorno Node.js** (alternativa cuando no se dispone de `psql`; requiere intérprete Node accesible en el sistema):

```bash
cd Lab2
npm install
export DATABASE_URL='postgresql://USER:PASS@HOST/DB?sslmode=require'
node apply_neon.mjs          # solo DDL
node apply_neon.mjs --seed   # DDL + datos de ejemplo
node apply_neon.mjs --reset --seed   # DROP de tablas del lab, luego DDL + semilla
```

Para **reinstalar** el laboratorio desde un estado limpio: ejecutar `schema_drop.sql` y, a continuación, `schema.sql` (o emplear `node apply_neon.mjs --reset --seed`).
