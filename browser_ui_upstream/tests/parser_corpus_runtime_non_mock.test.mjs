import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const TEST_TIMEOUT_MS = 5000;
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const PARSER_TEX_PATH = path.join(__dirname, "parser.tex");

const EXPECT_IMPORT_CASES = [
  { section: "valid", title: "Example of phantom edges." },
  { section: "valid", title: "`dashed`, not `dash`." },
  { section: "valid", title: "Loops of different radii, angles, and direction." },
  { section: "valid", title: "A loop without a target." },
  { section: "valid", title: "Swapping label alignment." },
  { section: "valid", title: "`between'" },
  { section: "valid", title: "Shortened marked arrow." },
  { section: "invalid", title: "Invalid level 1." },
  { section: "invalid", title: "A zero-length edge." },
];

const EXPECT_FAIL_FAST_CASES = [
  { section: "invalid", title: "Incorrect start." },
  { section: "invalid", title: "Incorrect end." },
  { section: "invalid", title: "Extra content after end." },
  { section: "invalid", title: "No target 1." },
  { section: "invalid", title: "No target 2." },
  { section: "invalid", title: "Same source and target." },
  { section: "invalid", title: "Invalid source/target." },
  { section: "invalid", title: "Missing source/target." },
  { section: "invalid", title: "Missing comma." },
  { section: "invalid", title: "Double comma." },
  { section: "invalid", title: "Unexpected end of arrow options." },
  { section: "invalid", title: "No ampersand replacement." },
  { section: "invalid", title: "No separation." },
  { section: "invalid", title: "No name." },
  { section: "invalid", title: "Missing colour." },
  { section: "invalid", title: "Invalid node colour 1." },
  { section: "invalid", title: "Invalid node colour 2." },
  { section: "invalid", title: "Colour without node." },
  { section: "invalid", title: "Invalid arrow colour." },
  { section: "invalid", title: "Invalid level 2." },
  { section: "invalid", title: "Unknown arrow option." },
  { section: "invalid", title: "Unknown diagram option." },
  { section: "invalid", title: "Unknown label option 1." },
  { section: "invalid", title: "Unknown label option 2." },
  { section: "invalid", title: "Multiple errors." },
  { section: "invalid", title: "Unexpected end of diagram." },
  { section: "invalid", title: "A loop whose source and target are not the same." },
];

function defaultSettings(renderer = "canvas") {
  return {
    get(key) {
      if (key === "quiver.renderer") {
        return renderer;
      }
      return undefined;
    },
  };
}

function assertIntegerIdList(value, context) {
  assert.equal(Array.isArray(value), true, `${context}: expected id array`);
  for (const id of value) {
    assert.equal(Number.isInteger(id), true, `${context}: non-integer id`);
  }
}

async function loadBridgeModule() {
  return import(`../kwiver_bridge.mjs?runtime-parser-corpus-non-mock=${Date.now()}`);
}

function parseParserTexCases(content) {
  const lines = content.replace(/\r\n/g, "\n").split("\n");
  const out = [];
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
    if (snippet.includes("tikzcd")) {
      out.push({ section, title, snippet });
    }
  }

  return out;
}

function selectCasesBySpec(cases, specs) {
  const byKey = new Map();
  for (const parserCase of cases) {
    const key = `${parserCase.section}::${parserCase.title}`;
    if (byKey.has(key)) {
      throw new Error(`duplicate parser.tex case key: ${key}`);
    }
    byKey.set(key, parserCase);
  }

  const selected = [];
  for (const spec of specs) {
    const key = `${spec.section}::${spec.title}`;
    const parserCase = byKey.get(key);
    assert.ok(parserCase, `parser.tex case missing: ${key}`);
    selected.push(parserCase);
  }
  return selected;
}

async function ensureRuntimeReady(bridge) {
  const {
    kwiver_bridge_ready,
    kwiver_bridge_status,
    kwiver_bridge_test_reset,
    kwiver_bridge_test_set_autoload,
  } = bridge;

  kwiver_bridge_test_reset();
  kwiver_bridge_test_set_autoload(true);

  const ready = await kwiver_bridge_ready(TEST_TIMEOUT_MS);
  const status = kwiver_bridge_status();
  assert.equal(ready, true, `runtime bridge unavailable: ${JSON.stringify(status)}`);
  assert.equal(status.available, true);
}

function assertCaseImports(bridge, parserCase) {
  const {
    kwiver_bridge_all_cell_ids,
    kwiver_bridge_import_tikz_payload,
    kwiver_bridge_reset,
  } = bridge;

  const originBase = `ui.test.non_mock.parser_corpus.import.${parserCase.title}`;
  assert.equal(kwiver_bridge_reset(`${originBase}.reset`)?.ok, true);
  assert.deepEqual(kwiver_bridge_all_cell_ids(`${originBase}.ids.before`), []);

  const payload = kwiver_bridge_import_tikz_payload(parserCase.snippet, defaultSettings());
  assert.equal(typeof payload, "string", `${parserCase.title}: expected payload`);
  assert.notEqual(payload, "", `${parserCase.title}: expected non-empty payload`);

  const idsAfter = kwiver_bridge_all_cell_ids(`${originBase}.ids.after`);
  assertIntegerIdList(idsAfter, parserCase.title);
  assert.equal(idsAfter.length >= 2, true, `${parserCase.title}: expected at least 2 cells`);
}

function assertCaseFailFast(bridge, parserCase) {
  const {
    kwiver_bridge_all_cell_ids,
    kwiver_bridge_import_tikz_payload,
    kwiver_bridge_reset,
  } = bridge;

  const originBase = `ui.test.non_mock.parser_corpus.fail_fast.${parserCase.title}`;
  assert.equal(kwiver_bridge_reset(`${originBase}.reset`)?.ok, true);
  assert.deepEqual(kwiver_bridge_all_cell_ids(`${originBase}.ids.before`), []);

  const payload = kwiver_bridge_import_tikz_payload(parserCase.snippet, defaultSettings());
  assert.equal(payload, null, `${parserCase.title}: expected fail-fast null payload`);

  const idsAfter = kwiver_bridge_all_cell_ids(`${originBase}.ids.after`);
  assert.deepEqual(idsAfter, [], `${parserCase.title}: state should remain empty`);
}

function runCases(cases, fn, context) {
  let passed = 0;
  let failed = 0;

  for (const parserCase of cases) {
    try {
      fn(parserCase);
      passed += 1;
      console.log(`ok: ${context}: ${parserCase.title}`);
    } catch (error) {
      failed += 1;
      const message = error instanceof Error ? error.stack ?? error.message : String(error);
      console.error(`not ok: ${context}: ${parserCase.title}`);
      console.error(message);
    }
  }

  return { passed, failed };
}

async function run() {
  const parserTex = readFileSync(PARSER_TEX_PATH, "utf8");
  const parsedCases = parseParserTexCases(parserTex);
  const successCases = selectCasesBySpec(parsedCases, EXPECT_IMPORT_CASES);
  const failFastCases = selectCasesBySpec(parsedCases, EXPECT_FAIL_FAST_CASES);

  const bridge = await loadBridgeModule();
  const { kwiver_bridge_test_reset, kwiver_bridge_test_set_autoload } = bridge;

  await ensureRuntimeReady(bridge);

  const imported = runCases(
    successCases,
    (parserCase) => assertCaseImports(bridge, parserCase),
    "runtime parser corpus import",
  );
  const failedFast = runCases(
    failFastCases,
    (parserCase) => assertCaseFailFast(bridge, parserCase),
    "runtime parser corpus fail-fast",
  );

  kwiver_bridge_test_reset();
  kwiver_bridge_test_set_autoload(true);

  const passed = imported.passed + failedFast.passed;
  const failed = imported.failed + failedFast.failed;
  if (failed > 0) {
    throw new Error(`runtime parser corpus non-mock failed: ${failed}/${passed + failed}`);
  }
  console.log(`runtime parser corpus non-mock passed: ${passed}/${passed + failed}`);
}

await run();
