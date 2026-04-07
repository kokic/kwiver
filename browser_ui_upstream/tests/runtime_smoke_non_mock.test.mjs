import assert from "node:assert/strict";

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
  return import(`../kwiver_bridge.mjs?runtime-smoke-non-mock=${Date.now()}`);
}

async function testRuntimeLoadsWithoutMock(bridge) {
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

  assert.equal(
    ready,
    true,
    `runtime bridge unavailable: ${JSON.stringify(status)}`,
  );
  assert.equal(status.available, true);
  assert.equal(typeof status.command_protocol, "string");
  assert.notEqual(status.command_protocol, "");
  assert.equal(typeof status.loaded_candidate, "string");
  assert.match(status.loaded_candidate, /browser_demo\.js$/);
}

function testMutationExportImportRoundtrip(bridge) {
  const {
    kwiver_bridge_add_edge_json,
    kwiver_bridge_add_vertex_json,
    kwiver_bridge_all_cell_ids,
    kwiver_bridge_export,
    kwiver_bridge_export_payload,
    kwiver_bridge_import_payload_json,
    kwiver_bridge_reset,
  } = bridge;

  const resetEnvelope = kwiver_bridge_reset("ui.test.non_mock.reset.initial");
  assert.equal(resetEnvelope?.ok, true);

  const addVertexA = kwiver_bridge_add_vertex_json(
    "A",
    0,
    0,
    null,
    "ui.test.non_mock.add_vertex.a",
  );
  assert.equal(addVertexA?.ok, true);

  const addVertexB = kwiver_bridge_add_vertex_json(
    "B",
    1,
    0,
    null,
    "ui.test.non_mock.add_vertex.b",
  );
  assert.equal(addVertexB?.ok, true);

  const addEdge = kwiver_bridge_add_edge_json(
    1,
    2,
    "f",
    null,
    null,
    "ui.test.non_mock.add_edge",
  );
  assert.equal(addEdge?.ok, true);

  const idsBefore = kwiver_bridge_all_cell_ids("ui.test.non_mock.all_cell_ids.before");
  assertIntegerIdList(idsBefore, "roundtrip before");
  assert.equal(idsBefore.length, 3, "roundtrip before: expected 3 cells");

  const tikzExported = kwiver_bridge_export(
    "tikz-cd",
    defaultSettings(),
    {},
    {},
  );
  assert.equal(typeof tikzExported?.data, "string");
  assert.equal(tikzExported.data.includes("\\begin{tikzcd}"), true);

  const payload = kwiver_bridge_export_payload("ui.test.non_mock.export_payload");
  assert.equal(typeof payload, "string");
  assert.notEqual(payload, "");

  const resetAfterExport = kwiver_bridge_reset("ui.test.non_mock.reset.after_export");
  assert.equal(resetAfterExport?.ok, true);

  const imported = kwiver_bridge_import_payload_json(
    payload,
    "ui.test.non_mock.import_payload",
  );
  assert.equal(typeof imported?.payload, "string");
  assert.notEqual(imported.payload, "");

  const idsAfter = kwiver_bridge_all_cell_ids("ui.test.non_mock.all_cell_ids.after");
  assertIntegerIdList(idsAfter, "roundtrip after");
  assert.equal(idsAfter.length, 3, "roundtrip after: expected 3 cells");
}

function testTikzImportPath(bridge) {
  const {
    kwiver_bridge_all_cell_ids,
    kwiver_bridge_export,
    kwiver_bridge_import_tikz_payload,
    kwiver_bridge_reset,
  } = bridge;

  const resetEnvelope = kwiver_bridge_reset("ui.test.non_mock.reset.tikz");
  assert.equal(resetEnvelope?.ok, true);

  const tikzText = [
    "\\begin{tikzcd}\n",
    "A \\arrow[r, \"f\"] & B\n",
    "\\end{tikzcd}",
  ].join("");

  const importedPayload = kwiver_bridge_import_tikz_payload(
    tikzText,
    defaultSettings(),
  );
  assert.equal(typeof importedPayload, "string");
  assert.notEqual(importedPayload, "");

  const ids = kwiver_bridge_all_cell_ids("ui.test.non_mock.all_cell_ids.tikz");
  assertIntegerIdList(ids, "tikz import");
  assert.equal(ids.length >= 3, true, "tikz import: expected at least 3 cells");

  const exported = kwiver_bridge_export(
    "tikz-cd",
    defaultSettings(),
    {},
    {},
  );
  assert.equal(typeof exported?.data, "string");
  assert.equal(exported.data.includes("\\begin{tikzcd}"), true);
}

async function run() {
  const bridge = await loadBridgeModule();
  const { kwiver_bridge_test_reset, kwiver_bridge_test_set_autoload } = bridge;

  const testCases = [
    ["runtime non-mock: bridge loads runtime artifact", () => testRuntimeLoadsWithoutMock(bridge)],
    ["runtime non-mock: mutation/export/import payload roundtrip", () => testMutationExportImportRoundtrip(bridge)],
    ["runtime non-mock: tikz import command path", () => testTikzImportPath(bridge)],
  ];

  let passed = 0;
  let failed = 0;

  for (const [name, fn] of testCases) {
    try {
      await fn();
      passed += 1;
      console.log("ok:", name);
    } catch (error) {
      failed += 1;
      const message = error instanceof Error ? error.stack ?? error.message : String(error);
      console.error("not ok:", name);
      console.error(message);
    }
  }

  kwiver_bridge_test_reset();
  kwiver_bridge_test_set_autoload(true);

  if (failed > 0) {
    throw new Error(`runtime non-mock smoke failed: ${failed}/${testCases.length}`);
  }
  console.log(`runtime non-mock smoke passed: ${passed}/${testCases.length}`);
}

await run();
