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

function requireAddedId(envelope, context) {
  const id = Number(envelope?.result?.id);
  assert.equal(Number.isInteger(id), true, `${context}: expected added id`);
  return id;
}

function requireSnapshot(snapshot, context) {
  assert.equal(snapshot && typeof snapshot === "object", true, `${context}: expected snapshot`);
  assertIntegerIdList(snapshot?.cell_ids, `${context}: cell_ids`);
  return snapshot;
}

function requireSelectionSummary(summary, context) {
  assert.equal(summary && typeof summary === "object", true, `${context}: expected selection summary`);
  assertIntegerIdList(summary?.all_cell_ids, `${context}: all_cell_ids`);
  return summary;
}

function assertDependencyLinks(value, context) {
  assert.equal(Array.isArray(value), true, `${context}: expected dependency link array`);
  for (const link of value) {
    assert.equal(Number.isInteger(link?.cell_id), true, `${context}: non-integer dependency id`);
    assert.equal(
      link?.role === "source" || link?.role === "target",
      true,
      `${context}: invalid dependency role`,
    );
  }
}

function snapshotDependencies(snapshot, cellId, context) {
  const entry = snapshot?.dependencies?.find((dependency) => dependency?.cell_id === cellId) ?? null;
  assert.equal(entry !== null, true, `${context}: expected dependency entry`);
  assertDependencyLinks(entry?.dependencies, `${context}: dependencies`);
  assertDependencyLinks(entry?.reverse_dependencies, `${context}: reverse_dependencies`);
  return entry;
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
}

function testMutationExportImportRoundtrip(bridge) {
  const {
    kwiver_bridge_add_edge_json,
    kwiver_bridge_add_vertex_json,
    kwiver_bridge_cell_records_for_ids,
    kwiver_bridge_export,
    kwiver_bridge_export_payload,
    kwiver_bridge_import_payload_json,
    kwiver_bridge_patch_edge_options_json,
    kwiver_bridge_reset,
    kwiver_bridge_selection_summary,
    kwiver_bridge_snapshot,
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
  const vertexAId = requireAddedId(addVertexA, "roundtrip add vertex A");

  const addVertexB = kwiver_bridge_add_vertex_json(
    "B",
    1,
    0,
    null,
    "ui.test.non_mock.add_vertex.b",
  );
  assert.equal(addVertexB?.ok, true);
  const vertexBId = requireAddedId(addVertexB, "roundtrip add vertex B");

  const addEdge = kwiver_bridge_add_edge_json(
    vertexAId,
    vertexBId,
    "f",
    null,
    null,
    "ui.test.non_mock.add_edge",
  );
  assert.equal(addEdge?.ok, true);
  const edgeId = requireAddedId(addEdge, "roundtrip add edge");

  const addLoop = kwiver_bridge_add_edge_json(
    vertexAId,
    vertexAId,
    "l",
    null,
    null,
    "ui.test.non_mock.add_edge.loop",
  );
  assert.equal(addLoop?.ok, true);
  const loopId = requireAddedId(addLoop, "roundtrip add loop");

  const patchLevel = kwiver_bridge_patch_edge_options_json(
    edgeId,
    { level: 4 },
    "ui.test.non_mock.patch_edge_options.level",
  );
  assert.equal(patchLevel?.ok, true);

  const idsBefore = requireSelectionSummary(
    kwiver_bridge_selection_summary([], "ui.test.non_mock.selection_summary.before"),
    "roundtrip before",
  ).all_cell_ids;
  assertIntegerIdList(idsBefore, "roundtrip before");
  assert.deepEqual(new Set(idsBefore), new Set([vertexAId, vertexBId, edgeId, loopId]));

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

  const runtimeSnapshot = requireSnapshot(
    kwiver_bridge_snapshot("ui.test.non_mock.snapshot.after"),
    "roundtrip after",
  );
  const idsAfter = runtimeSnapshot.cell_ids;
  assertIntegerIdList(idsAfter, "roundtrip after");
  assert.deepEqual(new Set(idsAfter), new Set([vertexAId, vertexBId, edgeId, loopId]));

  const cellsAfter = kwiver_bridge_cell_records_for_ids(
    idsAfter,
    "ui.test.non_mock.cell_records.after",
    runtimeSnapshot,
  );
  assert.equal(Array.isArray(cellsAfter), true);
  const lifted = cellsAfter.find((cell) => cell?.kind === "edge" && cell?.label === "f");
  const loop = cellsAfter.find((cell) => cell?.kind === "edge" && cell?.label === "l");
  assert.equal(Number(lifted?.level), 1, "roundtrip after: expected structural edge level");
  assert.equal(Number(lifted?.options?.level), 4, "roundtrip after: expected lifted option level");
  assert.equal(loop?.options?.shape, "arc", "roundtrip after: expected loop arc shape");
}

function testTikzImportPath(bridge) {
  const {
    kwiver_bridge_export,
    kwiver_bridge_import_tikz_result,
    kwiver_bridge_reset,
    kwiver_bridge_selection_summary,
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

  const ids = requireSelectionSummary(
    kwiver_bridge_selection_summary([], "ui.test.non_mock.selection_summary.tikz"),
    "tikz import",
  ).all_cell_ids;
  assertIntegerIdList(ids, "tikz import");
  assert.notEqual(ids.length, 0, "tikz import: expected imported state");

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
    kwiver_bridge_export_payload,
    kwiver_bridge_import_tikz_result,
    kwiver_bridge_reset,
    kwiver_bridge_selection_summary,
  } = bridge;

  const resetEnvelope = kwiver_bridge_reset("ui.test.non_mock.reset.tikz_fail_fast");
  assert.equal(resetEnvelope?.ok, true);

  const idsBefore = requireSelectionSummary(
    kwiver_bridge_selection_summary([], "ui.test.non_mock.selection_summary.tikz_fail_fast.before"),
    "tikz fail fast before",
  ).all_cell_ids;
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

  const idsAfter = requireSelectionSummary(
    kwiver_bridge_selection_summary([], "ui.test.non_mock.selection_summary.tikz_fail_fast.after"),
    "tikz fail fast after",
  ).all_cell_ids;
  assert.deepEqual(idsAfter, []);
}

function testQueryAndSelectionPaths(bridge) {
  const {
    kwiver_bridge_add_edge_json,
    kwiver_bridge_add_vertex_json,
    kwiver_bridge_export_selection,
    kwiver_bridge_paste_selection_json,
    kwiver_bridge_preview_reconnect_plan,
    kwiver_bridge_reset,
    kwiver_bridge_selection_panel_state,
    kwiver_bridge_selection_summary,
    kwiver_bridge_selection_toolbar_state,
    kwiver_bridge_set_selection,
    kwiver_bridge_snapshot,
    kwiver_bridge_suggest_edge_options,
  } = bridge;

  const resetEnvelope = kwiver_bridge_reset("ui.test.non_mock.reset.query_selection");
  assert.equal(resetEnvelope?.ok, true);

  const addVertexA = kwiver_bridge_add_vertex_json(
    "A",
    0,
    0,
    null,
    "ui.test.non_mock.query_selection.add_vertex.a",
  );
  assert.equal(addVertexA?.ok, true);
  const sourceId = requireAddedId(addVertexA, "query_selection add vertex A");

  const addVertexB = kwiver_bridge_add_vertex_json(
    "B",
    1,
    0,
    null,
    "ui.test.non_mock.query_selection.add_vertex.b",
  );
  assert.equal(addVertexB?.ok, true);
  const targetId = requireAddedId(addVertexB, "query_selection add vertex B");

  const addEdge = kwiver_bridge_add_edge_json(
    sourceId,
    targetId,
    "f",
    null,
    null,
    "ui.test.non_mock.query_selection.add_edge",
  );
  assert.equal(addEdge?.ok, true);
  const edgeId = requireAddedId(addEdge, "query_selection add edge");

  const dependencySnapshot = requireSnapshot(
    kwiver_bridge_snapshot("ui.test.non_mock.query_selection.snapshot.dependencies"),
    "query_selection dependencies",
  );
  const dependencies = snapshotDependencies(
    dependencySnapshot,
    targetId,
    "query_selection dependencies",
  ).dependencies;
  const edgeDependencies = snapshotDependencies(
    dependencySnapshot,
    edgeId,
    "query_selection edge dependencies",
  ).reverse_dependencies;
  assert.equal(
    dependencies.some((link) => link.cell_id === edgeId && link.role === "target"),
    true,
    "query_selection dependencies: expected connecting edge",
  );
  assert.equal(
    edgeDependencies.some((link) => link.cell_id === sourceId && link.role === "source"),
    true,
    "query_selection edge dependencies: expected source role",
  );
  assert.equal(
    edgeDependencies.some((link) => link.cell_id === targetId && link.role === "target"),
    true,
    "query_selection edge dependencies: expected target role",
  );
  const runtimeEdge = dependencySnapshot.edges.find((edge) => edge?.id === edgeId) ?? null;
  assert.equal(runtimeEdge?.source_projection?.kind, "vertex");
  assert.equal(runtimeEdge?.target_projection?.kind, "vertex");

  const summary = requireSelectionSummary(
    kwiver_bridge_selection_summary(
      [sourceId],
      "ui.test.non_mock.query_selection.selection_summary",
    ),
    "query_selection selection_summary",
  );
  const connected = summary.connected_component_ids;
  assertIntegerIdList(connected, "query_selection connected_components");
  assert.equal(connected.includes(sourceId), true, "query_selection connected_components: expected source id");
  assert.equal(connected.includes(targetId), true, "query_selection connected_components: expected target id");
  assert.equal(connected.includes(edgeId), true, "query_selection connected_components: expected edge id");

  const transitive = summary.transitive_dependency_ids;
  assertIntegerIdList(transitive, "query_selection transitive_dependencies");
  assert.equal(transitive.includes(sourceId), true, "query_selection transitive_dependencies: expected source id");
  assert.equal(transitive.includes(edgeId), true, "query_selection transitive_dependencies: expected edge id");

  const panelState = kwiver_bridge_selection_panel_state(
    [edgeId],
    "ui.test.non_mock.query_selection.selection_panel_state",
  );
  assert.equal(panelState && typeof panelState === "object", true);
  assert.equal(panelState?.selection_size, 1);
  assert.equal(panelState?.has_selected_edges, true);
  assert.equal(panelState?.has_selected_nonloop_edges, true);
  assert.equal(panelState?.has_selected_loop_edges, false);
  assert.equal(panelState?.label, "f");
  assert.equal(panelState?.edge_type, "arrow");
  assert.equal(panelState?.all_edges_are_arrows, true);
  assert.equal(typeof panelState?.edge_angle, "number");

  const toolbarState = kwiver_bridge_selection_toolbar_state(
    [sourceId],
    "ui.test.non_mock.query_selection.selection_toolbar_state",
  );
  assert.equal(toolbarState && typeof toolbarState === "object", true);
  assert.equal(toolbarState?.all_cells_count, 3);
  assert.equal(toolbarState?.selected_count, 1);
  assert.equal(toolbarState?.has_selection, true);
  assert.equal(toolbarState?.has_any_cells, true);
  assert.equal(toolbarState?.has_vertices, true);
  assert.equal(toolbarState?.can_select_all, true);
  assert.equal(toolbarState?.can_expand_connected, true);
  assert.equal(toolbarState?.can_deselect_all, true);
  assert.equal(toolbarState?.can_delete, true);
  assert.equal(toolbarState?.can_transform, true);

  const previewPlan = kwiver_bridge_preview_reconnect_plan(
    edgeId,
    targetId,
    sourceId,
    "ui.test.non_mock.query_selection.preview_reconnect_plan",
  );
  assert.equal(typeof previewPlan, "object");
  assert.equal(previewPlan?.edge_id, edgeId);
  assert.equal(Array.isArray(previewPlan?.edges), true);
  assert.equal(
    previewPlan.edges.some((edge) => Number(edge?.id) === edgeId),
    true,
    "query_selection preview_reconnect_plan: expected root edge record",
  );

  const suggestedOptions = kwiver_bridge_suggest_edge_options(
    sourceId,
    targetId,
    "left",
    "ui.test.non_mock.query_selection.suggest_edge_options",
  );
  assert.equal(suggestedOptions && typeof suggestedOptions === "object", true);
  assert.equal(
    suggestedOptions?.label_alignment,
    "right",
    "query_selection suggest_edge_options: expected flipped label alignment",
  );
  assert.equal(
    suggestedOptions?.offset,
    -3,
    "query_selection suggest_edge_options: expected non-overlapping parallel offset",
  );

  const setSelectionEnvelope = kwiver_bridge_set_selection(
    [sourceId, edgeId],
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
  assertIntegerIdList(pasted?.result?.imported_ids, "query_selection paste imported_ids");
  assert.notEqual(
    pasted.result.imported_ids.length,
    0,
    "query_selection paste: expected imported ids",
  );
  assert.equal(
    pasted.result.imported_ids.some((id) => id === sourceId || id === edgeId),
    false,
    "query_selection paste: expected no id collision with existing selection",
  );

  const allIds = requireSelectionSummary(
    kwiver_bridge_selection_summary([], "ui.test.non_mock.query_selection.selection_summary.after"),
    "query_selection all_cell_ids",
  ).all_cell_ids;
  assertIntegerIdList(allIds, "query_selection all_cell_ids");
  assert.equal(allIds.includes(sourceId), true, "query_selection all_cell_ids: expected source id");
  assert.equal(allIds.includes(targetId), true, "query_selection all_cell_ids: expected target id");
  assert.equal(allIds.includes(edgeId), true, "query_selection all_cell_ids: expected edge id");
  assert.equal(
    pasted.result.imported_ids.every((id) => allIds.includes(id)),
    true,
    "query_selection all_cell_ids: expected pasted ids to be present",
  );
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
