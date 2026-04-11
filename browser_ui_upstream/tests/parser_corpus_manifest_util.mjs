import { readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export const PARSER_TEX_PATH = path.join(__dirname, "parser.tex");
export const PARSER_CORPUS_MANIFEST_PATH = path.join(
  __dirname,
  "parser_corpus_manifest.json",
);

function parseParserTexCaseMap(content) {
  const lines = content.replace(/\r\n/g, "\n").split("\n");
  const caseMap = new Map();
  let section = null;

  for (let i = 0; i < lines.length; i += 1) {
    const trimmed = lines[i].trim();
    if (trimmed === "%%% Valid diagrams %%%") {
      section = "valid";
      continue;
    }
    if (trimmed === "%%% Invalid diagrams %%%") {
      section = "invalid";
      continue;
    }
    if (!trimmed.startsWith("%") || trimmed.startsWith("%%%")) {
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
      throw new Error(`duplicate parser.tex case key: ${key}`);
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
}

export function loadParserCorpusManifestCases() {
  const parserTexContent = readFileSync(PARSER_TEX_PATH, "utf8");
  const manifestContent = readFileSync(PARSER_CORPUS_MANIFEST_PATH, "utf8");
  const snippetMap = parseParserTexCaseMap(parserTexContent);
  const manifestCases = parseManifest(manifestContent);

  const ids = new Set();
  const out = [];

  for (const entry of manifestCases) {
    validateManifestEntry(entry);
    if (ids.has(entry.id)) {
      throw new Error(`duplicate parser corpus id: ${entry.id}`);
    }
    ids.add(entry.id);

    const key = `${entry.section}::${entry.title}`;
    const snippet = snippetMap.get(key);
    if (typeof snippet !== "string" || snippet === "") {
      throw new Error(`parser.tex case not found for manifest entry ${entry.id}: ${key}`);
    }

    out.push({
      id: entry.id,
      section: entry.section,
      title: entry.title,
      engine_group: entry.engine_group,
      engine_context: entry.engine_context,
      runtime_expectation: entry.runtime_expectation,
      snippet,
    });
  }

  return out;
}
