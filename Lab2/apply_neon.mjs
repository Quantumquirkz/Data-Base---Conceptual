#!/usr/bin/env node
/**
 * Aplica schema.sql (y opcionalmente seed.sql) contra Neon.
 * Uso:
 *   export DATABASE_URL='postgresql://...'
 *   npm install pg
 *   node apply_neon.mjs
 *   node apply_neon.mjs --seed
 *   node apply_neon.mjs --reset --seed   # borra tablas Lab2 y recrea + semilla
 *
 * Si la URL lleva channel_binding=require y falla el cliente, quita ese parámetro en Neon.
 */
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const url = process.env.DATABASE_URL;
if (!url) {
  console.error("Define DATABASE_URL (cadena URI de Neon).");
  process.exit(1);
}

let Client;
try {
  ({ Client } = await import("pg"));
} catch {
  console.error('Instala la dependencia: npm install pg  (en esta carpeta o en el proyecto)');
  process.exit(1);
}

const runSeed = process.argv.includes("--seed");
const runReset = process.argv.includes("--reset");

const client = new Client({
  connectionString: url,
  ssl: { rejectUnauthorized: true },
});

const execFile = async (name) => {
  const sql = readFileSync(join(__dirname, name), "utf8");
  await client.query(sql);
  console.log(`OK: ${name}`);
};

try {
  await client.connect();
  if (runReset) await execFile("schema_drop.sql");
  await execFile("schema.sql");
  if (runSeed) await execFile("seed.sql");
} catch (e) {
  console.error(e.message);
  process.exit(1);
} finally {
  await client.end();
}
