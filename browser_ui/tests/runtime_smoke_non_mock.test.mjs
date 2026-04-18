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
  assert.match(status.loaded_candidate, /runtime\.js$/);
}

function testMutationExportImportRoundtrip(bridge) {
  const {
    kwiver_bridge_add_edge_json,
    kwiver_bridge_add_vertex_json,
    kwiver_bridge_all_cells,
    kwiver_bridge_all_cell_ids,
    kwiver_bridge_export,
    kwiver_bridge_export_payload,
    kwiver_bridge_import_payload_json,
    kwiver_bridge_patch_edge_options_json,
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

  const addLoop = kwiver_bridge_add_edge_json(
    1,
    1,
    "l",
    null,
    null,
    "ui.test.non_mock.add_edge.loop",
  );
  assert.equal(addLoop?.ok, true);

  const patchLevel = kwiver_bridge_patch_edge_options_json(
    3,
    { level: 4 },
    "ui.test.non_mock.patch_edge_options.level",
  );
  assert.equal(patchLevel?.ok, true);

  const idsBefore = kwiver_bridge_all_cell_ids("ui.test.non_mock.all_cell_ids.before");
  assertIntegerIdList(idsBefore, "roundtrip before");
  assert.equal(idsBefore.length, 4, "roundtrip before: expected 4 cells");

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
  assert.equal(idsAfter.length, 4, "roundtrip after: expected 4 cells");

  const cellsAfter = kwiver_bridge_all_cells();
  assert.equal(Array.isArray(cellsAfter), true);
  const lifted = cellsAfter.find((cell) => cell?.kind === "edge" && cell?.label === "f");
  const loop = cellsAfter.find((cell) => cell?.kind === "edge" && cell?.label === "l");
  assert.equal(Number(lifted?.level), 1, "roundtrip after: expected structural edge level");
  assert.equal(Number(lifted?.options?.level), 4, "roundtrip after: expected lifted option level");
  assert.equal(loop?.options?.shape, "arc", "roundtrip after: expected loop arc shape");
}

function testTikzImportPath(bridge) {
  const {
    kwiver_bridge_all_cell_ids,
    kwiver_bridge_export,
    kwiver_bridge_import_tikz_result,
    kwiver_bridge_reset,
  } = bridge;

  const resetEnvelope = kwiver_bridge_reset("ui.test.non_mock.reset.tikz");
  assert.equal(resetEnvelope?.ok, true);

  const tikzText = [
    "\\begin{tikzcd}\n",
    "A \\arrow[r, \"f\"] & B\n",
    "\\end{tikzcd}",
  ].join("");

  const imported = kwiver_bridge_import_tikz_result(
    tikzText,
    defaultSettings(),
  );
  assert.equal(imported?.ok, true);
  assert.equal(typeof imported?.payload, "string");
  assert.notEqual(imported?.payload, "");

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

function testTikzImportFailFastPath(bridge) {
  const {
    kwiver_bridge_all_cell_ids,
    kwiver_bridge_export_payload,
    kwiver_bridge_import_tikz_result,
    kwiver_bridge_reset,
  } = bridge;

  const resetEnvelope = kwiver_bridge_reset("ui.test.non_mock.reset.tikz_fail_fast");
  assert.equal(resetEnvelope?.ok, true);

  const idsBefore = kwiver_bridge_all_cell_ids("ui.test.non_mock.all_cell_ids.tikz_fail_fast.before");
  assert.deepEqual(idsBefore, []);

  const invalidTikz = [
    "\\begin{tikzcd}\n",
    "A & B\n",
    "\\arrow[Rightarrow, scaling nfold=unknown, from=1-1, to=1-2]\n",
    "\\end{tikzcd}",
  ].join("");

  const imported = kwiver_bridge_import_tikz_result(
    invalidTikz,
    defaultSettings(),
  );
  assert.equal(imported?.ok, false);
  assert.equal(typeof imported?.payload, "string");
  assert.equal(
    imported?.payload,
    kwiver_bridge_export_payload("ui.test.non_mock.export_payload.tikz_fail_fast"),
  );

  const idsAfter = kwiver_bridge_all_cell_ids("ui.test.non_mock.all_cell_ids.tikz_fail_fast.after");
  assert.deepEqual(idsAfter, []);
}

function testQueryAndSelectionPaths(bridge) {
  const {
    kwiver_bridge_add_edge_json,
    kwiver_bridge_add_vertex_json,
    kwiver_bridge_all_cell_ids,
    kwiver_bridge_connected_components,
    kwiver_bridge_dependencies,
    kwiver_bridge_export_selection,
    kwiver_bridge_paste_selection_json,
    kwiver_bridge_preview_reconnect_plan,
    kwiver_bridge_reset,
    kwiver_bridge_set_selection,
    kwiver_bridge_transitive_dependencies,
  } = bridge;

  const resetEnvelope = kwiver_bridge_reset("ui.test.non_mock.reset.query_selection");
  assert.equal(resetEnvelope?.ok, true);

  assert.equal(
    kwiver_bridge_add_vertex_json("A", 0, 0, null, "ui.test.non_mock.query_selection.add_vertex.a")?.ok,
    true,
  );
  assert.equal(
    kwiver_bridge_add_vertex_json("B", 1, 0, null, "ui.test.non_mock.query_selection.add_vertex.b")?.ok,
    true,
  );
  assert.equal(
    kwiver_bridge_add_edge_json(1, 2, "f", null, null, "ui.test.non_mock.query_selection.add_edge")?.ok,
    true,
  );

  const dependencies = kwiver_bridge_dependencies(2, "ui.test.non_mock.query_selection.dependencies");
  assertIntegerIdList(dependencies, "query_selection dependencies");
  assert.equal(dependencies.includes(3), true, "query_selection dependencies: expected edge id 3");

  const connected = kwiver_bridge_connected_components(
    [1],
    "ui.test.non_mock.query_selection.connected_components",
  );
  assertIntegerIdList(connected, "query_selection connected_components");
  assert.equal(connected.includes(1), true, "query_selection connected_components: expected root id");

  const transitive = kwiver_bridge_transitive_dependencies(
    [1],
    false,
    "ui.test.non_mock.query_selection.transitive_dependencies",
  );
  assertIntegerIdList(transitive, "query_selection transitive_dependencies");
  assert.equal(transitive.includes(1), true, "query_selection transitive_dependencies: expected root id");

  const previewPlan = kwiver_bridge_preview_reconnect_plan(
    3,
    2,
    1,
    "ui.test.non_mock.query_selection.preview_reconnect_plan",
  );
  assert.equal(typeof previewPlan, "object");
  assert.equal(previewPlan?.edge_id, 3);
  assert.equal(Array.isArray(previewPlan?.edges), true);
  assert.equal(
    previewPlan.edges.some((edge) => Number(edge?.id) === 3),
    true,
    "query_selection preview_reconnect_plan: expected root edge record",
  );

  const setSelectionEnvelope = kwiver_bridge_set_selection(
    [1, 3],
    "ui.test.non_mock.query_selection.set_selection",
  );
  assert.equal(setSelectionEnvelope?.ok, true);

  const selectionPayload = kwiver_bridge_export_selection(
    true,
    "ui.test.non_mock.query_selection.export_selection",
  );
  assert.equal(typeof selectionPayload, "string");
  assert.notEqual(selectionPayload, "");

  const pasted = kwiver_bridge_paste_selection_json(
    selectionPayload,
    10,
    10,
    10,
    "ui.test.non_mock.query_selection.paste",
  );
  assert.equal(pasted?.ok, true);
  assert.equal(Array.isArray(pasted?.result?.imported_ids), true);
  assert.equal(pasted.result.imported_ids.length >= 3, true);
  assert.equal(pasted.result.imported_ids[0], 10);

  const allIds = kwiver_bridge_all_cell_ids("ui.test.non_mock.query_selection.all_cell_ids.after");
  assertIntegerIdList(allIds, "query_selection all_cell_ids");
  assert.equal(allIds.length >= 6, true);
}

async function run() {
  const bridge = await loadBridgeModule();
  const { kwiver_bridge_test_reset, kwiver_bridge_test_set_autoload } = bridge;

  const testCases = [
    ["runtime non-mock: bridge loads runtime artifact", () => testRuntimeLoadsWithoutMock(bridge)],
    ["runtime non-mock: mutation/export/import payload roundtrip", () => testMutationExportImportRoundtrip(bridge)],
    ["runtime non-mock: tikz import command path", () => testTikzImportPath(bridge)],
    ["runtime non-mock: tikz import fail-fast path", () => testTikzImportFailFastPath(bridge)],
    ["runtime non-mock: query and selection command paths", () => testQueryAndSelectionPaths(bridge)],
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
