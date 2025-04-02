import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { config } from "../src/embed/config";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const outDir = path.join(__dirname, "..", "json-schemas");
fs.mkdirSync(outDir, { recursive: true });

fs.writeFileSync(
	path.join(outDir, "embed-config.json"),
	JSON.stringify(config.toJsonSchema(), null, 2),
);
