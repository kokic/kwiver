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

function requireSelectionSummary(summary, context) {
  assert.equal(summary && typeof summary === "object", true, `${context}: expected selection summary`);
  assertIntegerIdList(summary?.all_cell_ids, `${context}: all_cell_ids`);
  return summary;
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
    kwiver_bridge_import_tikz_result,
    kwiver_bridge_reset,
    kwiver_bridge_selection_summary,
  } = bridge;

  const originBase = `ui.test.non_mock.parser_corpus.import.${parserCase.id}`;
  assert.equal(kwiver_bridge_reset(`${originBase}.reset`)?.ok, true);
  assert.deepEqual(
    requireSelectionSummary(
      kwiver_bridge_selection_summary([], `${originBase}.selection_summary.before`),
      `${parserCase.title}: before`,
    ).all_cell_ids,
    [],
  );

  const result = kwiver_bridge_import_tikz_result(parserCase.snippet, defaultSettings());
  assert.equal(result?.ok, true, `${parserCase.title}: expected successful import result`);
  assert.equal(typeof result?.payload, "string", `${parserCase.title}: expected payload`);
  assert.notEqual(result?.payload, "", `${parserCase.title}: expected non-empty payload`);

  const idsAfter = requireSelectionSummary(
    kwiver_bridge_selection_summary([], `${originBase}.selection_summary.after`),
    `${parserCase.title}: after`,
  ).all_cell_ids;
  assertIntegerIdList(idsAfter, parserCase.title);
  assert.notEqual(idsAfter.length, 0, `${parserCase.title}: expected imported state`);
}

function assertCaseFailFast(bridge, parserCase) {
  const {
    kwiver_bridge_export_payload,
    kwiver_bridge_import_tikz_result,
    kwiver_bridge_reset,
    kwiver_bridge_selection_summary,
  } = bridge;

  const originBase = `ui.test.non_mock.parser_corpus.fail_fast.${parserCase.id}`;
  assert.equal(kwiver_bridge_reset(`${originBase}.reset`)?.ok, true);
  assert.deepEqual(
    requireSelectionSummary(
      kwiver_bridge_selection_summary([], `${originBase}.selection_summary.before`),
      `${parserCase.title}: before`,
    ).all_cell_ids,
    [],
  );

  const result = kwiver_bridge_import_tikz_result(parserCase.snippet, defaultSettings());
  assert.equal(result?.ok, false, `${parserCase.title}: expected fail-fast result`);
  assert.equal(typeof result?.payload, "string", `${parserCase.title}: expected canonical payload on failure`);
  assert.equal(
    result?.payload,
    kwiver_bridge_export_payload(`${originBase}.payload.after`),
    `${parserCase.title}: payload should match unchanged state`,
  );

  const idsAfter = requireSelectionSummary(
    kwiver_bridge_selection_summary([], `${originBase}.selection_summary.after`),
    `${parserCase.title}: after`,
  ).all_cell_ids;
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
  const successCases = manifestCases.filter(
    (parserCase) => parserCase.runtime_expectation === "import_success",
  );
  const failFastCases = manifestCases.filter(
    (parserCase) => parserCase.runtime_expectation === "fail_fast",
  );

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
