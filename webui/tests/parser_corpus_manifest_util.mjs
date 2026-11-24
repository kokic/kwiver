import { readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export const PARSER_TEX_PATH = path.join(__dirname, "parser.tex");
export const PARSER_EXTERNAL_TEX_PATH = path.join(__dirname, "parser_external.tex");
export const PARSER_EXTERNAL_INVALID_TEX_PATH = path.join(
  __dirname,
  "parser_external_invalid.tex",
);
export const PARSER_CORPUS_MANIFEST_PATH = path.join(
  __dirname,
  "parser_corpus_manifest.json",
);
const PARSER_FIXTURE_PATHS = Object.freeze({
  "parser.tex": PARSER_TEX_PATH,
  "parser_external.tex": PARSER_EXTERNAL_TEX_PATH,
  "parser_external_invalid.tex": PARSER_EXTERNAL_INVALID_TEX_PATH,
});

function parseParserTexCaseMap(content, fixtureName) {
  const lines = content.replace(/\r\n/g, "\n").split("\n");
  const caseMap = new Map();
  let section = null;

  for (let i = 0; i < lines.length; i += 1) {
    const line = lines[i];
    const trimmed = line.trim();
    if (trimmed === "%%% Valid diagrams %%%") {
      section = "valid";
      continue;
    }
    if (trimmed === "%%% Invalid diagrams %%%") {
      section = "invalid";
      continue;
    }
    // Only treat column-0 `%` lines as case titles.
    // Indented `% ...` lines inside a tikzcd snippet are inline comments, not new cases.
    if (!line.startsWith("%") || line.startsWith("%%%")) {
      continue;
    }

    const title = trimmed.replace(/^%\s?/, "").trim();
    if (title === "") {
      continue;
    }

    let j = i + 1;
    while (j < lines.length && lines[j].trim() === "") {
      j += 1;
    }
    if (j >= lines.length) {
      continue;
    }
    if (lines[j].trim().startsWith("%")) {
      continue;
    }

    const snippetLines = [];
    for (; j < lines.length; j += 1) {
      const snippetLine = lines[j];
      if (snippetLine.trim() === "") {
        break;
      }
      snippetLines.push(snippetLine);
    }
    i = j;

    const snippet = snippetLines.join("\n").trim();
    if (!snippet.includes("tikzcd")) {
      continue;
    }

    const key = `${section}::${title}`;
    if (caseMap.has(key)) {
      throw new Error(`duplicate ${fixtureName} case key: ${key}`);
    }
    caseMap.set(key, snippet);
  }

  return caseMap;
}

function parseManifest(content) {
  const parsed = JSON.parse(content);
  if (!parsed || typeof parsed !== "object" || !Array.isArray(parsed.cases)) {
    throw new Error("invalid parser corpus manifest: expected { cases: [...] }");
  }
  return parsed.cases;
}

function assertKnownValue(value, known, fieldName, id) {
  if (!known.includes(value)) {
    throw new Error(`invalid ${fieldName} for ${id}: ${value}`);
  }
}

function validateManifestEntry(entry) {
  if (!entry || typeof entry !== "object") {
    throw new Error("invalid parser corpus entry: expected object");
  }
  const requiredStringFields = ["id", "section", "title", "engine_group", "runtime_expectation"];
  for (const fieldName of requiredStringFields) {
    if (typeof entry[fieldName] !== "string" || entry[fieldName] === "") {
      throw new Error(`invalid parser corpus entry field: ${fieldName}`);
    }
  }
  if (entry.engine_context !== null && typeof entry.engine_context !== "string") {
    throw new Error(`invalid parser corpus engine_context for ${entry.id}`);
  }
  if ("fixture" in entry && (typeof entry.fixture !== "string" || entry.fixture === "")) {
    throw new Error(`invalid parser corpus fixture for ${entry.id}`);
  }
  if ("runtime_min_cells" in entry) {
    if (!Number.isInteger(entry.runtime_min_cells) || entry.runtime_min_cells < 1) {
      throw new Error(`invalid parser corpus runtime_min_cells for ${entry.id}`);
    }
  }

  assertKnownValue(entry.section, ["valid", "invalid"], "section", entry.id);
  assertKnownValue(
    entry.engine_group,
    ["valid", "invalid_fail_fast", "compat_fail_fast", "skip"],
    "engine_group",
    entry.id,
  );
  assertKnownValue(
    entry.runtime_expectation,
    ["import_success", "fail_fast", "skip"],
    "runtime_expectation",
    entry.id,
  );
  const fixture = "fixture" in entry ? entry.fixture : "parser.tex";
  assertKnownValue(
    fixture,
    Object.keys(PARSER_FIXTURE_PATHS),
    "fixture",
    entry.id,
  );
  if (entry.runtime_expectation !== "import_success" && "runtime_min_cells" in entry) {
    throw new Error(
      `runtime_min_cells is only allowed for import_success entries (${entry.id})`,
    );
  }

  if (fixture === "parser_external.tex") {
    if (entry.section !== "valid") {
      throw new Error(
        `parser_external fixture must use section=valid (${entry.id})`,
      );
    }
    if (entry.engine_group !== "valid") {
      throw new Error(
        `parser_external fixture must use engine_group=valid (${entry.id})`,
      );
    }
    if (entry.runtime_expectation !== "import_success") {
      throw new Error(
        `parser_external fixture must use runtime_expectation=import_success (${entry.id})`,
      );
    }
  }

  if (fixture === "parser_external_invalid.tex") {
    if (entry.section !== "invalid") {
      throw new Error(
        `parser_external_invalid fixture must use section=invalid (${entry.id})`,
      );
    }
    if (entry.runtime_expectation !== "fail_fast") {
      throw new Error(
        `parser_external_invalid fixture must use runtime_expectation=fail_fast (${entry.id})`,
      );
    }
    if (!["compat_fail_fast", "invalid_fail_fast"].includes(entry.engine_group)) {
      throw new Error(
        `parser_external_invalid fixture must use fail-fast engine_group (${entry.id})`,
      );
    }
  }
}

export function loadParserCorpusManifestCases() {
  const manifestContent = readFileSync(PARSER_CORPUS_MANIFEST_PATH, "utf8");
  const snippetMaps = new Map();
  for (const [fixtureName, fixturePath] of Object.entries(PARSER_FIXTURE_PATHS)) {
    const fixtureContent = readFileSync(fixturePath, "utf8");
    snippetMaps.set(fixtureName, parseParserTexCaseMap(fixtureContent, fixtureName));
  }
  const manifestCases = parseManifest(manifestContent);

  const ids = new Set();
  const out = [];

  for (const entry of manifestCases) {
    validateManifestEntry(entry);
    if (ids.has(entry.id)) {
      throw new Error(`duplicate parser corpus id: ${entry.id}`);
    }
    ids.add(entry.id);

    const fixture = "fixture" in entry ? entry.fixture : "parser.tex";
    const snippetMap = snippetMaps.get(fixture);
    if (!(snippetMap instanceof Map)) {
      throw new Error(`fixture not loaded for manifest entry ${entry.id}: ${fixture}`);
    }
    const key = `${entry.section}::${entry.title}`;
    const snippet = snippetMap.get(key);
    if (typeof snippet !== "string" || snippet === "") {
      throw new Error(`${fixture} case not found for manifest entry ${entry.id}: ${key}`);
    }

    out.push({
      id: entry.id,
      fixture,
      section: entry.section,
      title: entry.title,
      engine_group: entry.engine_group,
      engine_context: entry.engine_context,
      runtime_expectation: entry.runtime_expectation,
      runtime_min_cells: "runtime_min_cells" in entry ? entry.runtime_min_cells : null,
      snippet,
    });
  }

  return out;
}
