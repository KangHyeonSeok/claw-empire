#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const rootDir = path.resolve(__dirname, "..");
const indexPath = path.join(rootDir, "dist", "index.html");

if (!fs.existsSync(indexPath)) {
  console.error(`[strip-dist-crossorigin] dist index not found: ${indexPath}`);
  process.exit(1);
}

const original = fs.readFileSync(indexPath, "utf8");
const updated = original.replace(/\s+crossorigin(?=[\s>])/g, "");

if (updated !== original) {
  fs.writeFileSync(indexPath, updated, "utf8");
  console.log("[strip-dist-crossorigin] removed crossorigin attributes from dist/index.html");
} else {
  console.log("[strip-dist-crossorigin] no crossorigin attributes found");
}