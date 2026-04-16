import assert from "node:assert/strict";
import { loadParserCorpusManifestCases } from "./parser_corpus_manifest_util.mjs";

const TEST_TIMEOUT_MS = 5000;

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

  const originBase = `ui.test.non_mock.parser_corpus.import.${parserCase.id}`;
  assert.equal(kwiver_bridge_reset(`${originBase}.reset`)?.ok, true);
  assert.deepEqual(kwiver_bridge_all_cell_ids(`${originBase}.ids.before`), []);

  const payload = kwiver_bridge_import_tikz_payload(parserCase.snippet, defaultSettings());
  assert.equal(typeof payload, "string", `${parserCase.title}: expected payload`);
  assert.notEqual(payload, "", `${parserCase.title}: expected non-empty payload`);

  const idsAfter = kwiver_bridge_all_cell_ids(`${originBase}.ids.after`);
  assertIntegerIdList(idsAfter, parserCase.title);
  const minCells = Number.isInteger(parserCase.runtime_min_cells) ? parserCase.runtime_min_cells : 2;
  assert.equal(
    idsAfter.length >= minCells,
    true,
    `${parserCase.title}: expected at least ${minCells} cells`,
  );
}

function assertCaseFailFast(bridge, parserCase) {
  const {
    kwiver_bridge_all_cell_ids,
    kwiver_bridge_import_tikz_payload,
    kwiver_bridge_reset,
  } = bridge;

  const originBase = `ui.test.non_mock.parser_corpus.fail_fast.${parserCase.id}`;
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
      console.log(`ok: ${context}: ${parserCase.id} (${parserCase.title})`);
    } catch (error) {
      failed += 1;
      const message = error instanceof Error ? error.stack ?? error.message : String(error);
      console.error(`not ok: ${context}: ${parserCase.id} (${parserCase.title})`);
      console.error(message);
    }
  }

  return { passed, failed };
}

async function run() {
  const manifestCases = loadParserCorpusManifestCases();
  const externalCases = manifestCases.filter(
    (parserCase) => parserCase.fixture === "parser_external.tex",
  );
  const externalInvalidCases = manifestCases.filter(
    (parserCase) => parserCase.fixture === "parser_external_invalid.tex",
  );
  assert.equal(externalCases.length > 0, true, "expected parser_external cases");
  assert.equal(externalInvalidCases.length > 0, true, "expected parser_external_invalid cases");
  for (const parserCase of externalCases) {
    assert.equal(
      parserCase.runtime_expectation,
      "import_success",
      `expected parser_external import_success for ${parserCase.id}`,
    );
  }
  for (const parserCase of externalInvalidCases) {
    assert.equal(
      parserCase.runtime_expectation,
      "fail_fast",
      `expected parser_external_invalid fail_fast for ${parserCase.id}`,
    );
  }

  const successCases = manifestCases.filter(
    (parserCase) => parserCase.runtime_expectation === "import_success",
  );
  const failFastCases = manifestCases.filter(
    (parserCase) => parserCase.runtime_expectation === "fail_fast",
  );
  assert.equal(successCases.length > 0, true, "expected runtime import_success cases");
  assert.equal(failFastCases.length > 0, true, "expected runtime fail_fast cases");

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
