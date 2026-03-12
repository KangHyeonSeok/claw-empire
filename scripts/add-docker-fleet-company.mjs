#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(__dirname, "..");
const configPath = path.join(rootDir, "deploy", "docker", "fleet.config.json");

function toSlug(name) {
  return name
    .trim()
    .replace(/([a-z0-9])([A-Z])/g, "$1-$2")
    .replace(/[^a-zA-Z0-9]+/g, "-")
    .replace(/-{2,}/g, "-")
    .replace(/^-|-$/g, "")
    .toLowerCase();
}

function readConfig() {
  return JSON.parse(fs.readFileSync(configPath, "utf8"));
}

function writeConfig(config) {
  fs.writeFileSync(configPath, `${JSON.stringify(config, null, 2)}\n`, "utf8");
}

function nextPort(companies) {
  const ports = companies.map((company) => Number(company.hostPort)).filter(Number.isFinite);
  return ports.length === 0 ? 8791 : Math.max(...ports) + 1;
}

function addCompanies(config, names) {
  const companies = Array.isArray(config.companies) ? [...config.companies] : [];
  const existingSlugs = new Set(companies.map((company) => String(company.slug)));
  const added = [];

  for (const rawName of names) {
    const name = rawName.trim();
    if (!name) continue;
    const slug = toSlug(name);
    if (!slug) {
      throw new Error(`Could not derive a slug from: ${rawName}`);
    }
    if (existingSlugs.has(slug)) {
      console.log(`[docker-fleet:add] skipped existing company: ${name} (${slug})`);
      continue;
    }

    const port = nextPort(companies);
    const company = {
      name,
      slug,
      hostPort: port,
      publicHost: "localhost",
    };
    companies.push(company);
    existingSlugs.add(slug);
    added.push(company);
    console.log(`[docker-fleet:add] added ${name} as ${slug} on port ${port}`);
  }

  return { ...config, companies, sharedCliAuth: config.sharedCliAuth !== false, added };
}

function runGenerator() {
  const result = spawnSync("node", [path.join(rootDir, "scripts", "generate-docker-fleet.mjs")], {
    cwd: rootDir,
    stdio: "inherit",
  });
  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
}

function main() {
  const names = process.argv.slice(2).filter((value) => value !== "--");
  if (names.length === 0) {
    console.error("Usage: pnpm run docker:fleet:add -- <CompanyName> [AnotherCompanyName ...]");
    process.exit(1);
  }

  const config = readConfig();
  const updated = addCompanies(config, names);
  delete updated.added;
  writeConfig(updated);
  runGenerator();
}

main();
