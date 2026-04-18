import assert from "node:assert/strict";

import {
  kwiver_bridge_all_cell_ids,
  kwiver_bridge_add_edge_json,
  kwiver_bridge_add_vertex_json,
  kwiver_bridge_all_cells,
  kwiver_bridge_arrow_find_endpoints_local,
  kwiver_bridge_arrow_label_position_local,
  kwiver_bridge_arrow_render_plan_local,
  kwiver_bridge_arc_intersections_with_rounded_rectangle,
  kwiver_bridge_arc_angle_in_arc,
  kwiver_bridge_arc_arc_length,
  kwiver_bridge_arc_height,
  kwiver_bridge_arc_point,
  kwiver_bridge_arc_t_after_length,
  kwiver_bridge_arc_tangent,
  kwiver_bridge_arc_width,
  kwiver_bridge_bezier_arc_length,
  kwiver_bridge_bezier_height,
  kwiver_bridge_bezier_intersections_with_rounded_rectangle,
  kwiver_bridge_bezier_point,
  kwiver_bridge_bezier_t_after_length,
  kwiver_bridge_bezier_tangent,
  kwiver_bridge_bezier_width,
  kwiver_bridge_connected_components,
  kwiver_bridge_dependencies,
  kwiver_bridge_export,
  kwiver_bridge_export_selection,
  kwiver_bridge_flip_edge_json,
  kwiver_bridge_flip_edge_labels_json,
  kwiver_bridge_import_payload_json,
  kwiver_bridge_move_vertex_json,
  kwiver_bridge_patch_edge_options_json,
  kwiver_bridge_paste_selection_json,
  kwiver_bridge_preview_reconnect_plan,
  kwiver_bridge_reconnect_edge_json,
  kwiver_bridge_remove_json,
  kwiver_bridge_reverse_edge_json,
  kwiver_bridge_reverse_dependencies,
  kwiver_bridge_reset,
  kwiver_bridge_ready,
  kwiver_bridge_set_edge_curve_json,
  kwiver_bridge_set_edge_label_alignment_json,
  kwiver_bridge_set_edge_label_position_json,
  kwiver_bridge_set_edge_offset_json,
  kwiver_bridge_set_label_colour_json,
  kwiver_bridge_set_label_json,
  kwiver_bridge_set_selection,
  kwiver_bridge_transitive_dependencies,
  kwiver_bridge_transitive_reverse_dependencies,
  kwiver_bridge_status,
  kwiver_bridge_test_install_mock_api,
  kwiver_bridge_test_reset,
  kwiver_bridge_test_set_autoload,
} from "../kwiver_bridge.mjs";
import {
  KWIVER_BRIDGE_UNAVAILABLE_DISPLAY_ERROR,
  kwiver_bridge_unavailable_error,
} from "../bridge_startup.mjs";

const COMMAND_PROTOCOL = "kwiver.command.v1";

function mockApiFromResponder(responder) {
  return {
    ffi_runtime_session_new() {
      return { session: "mock" };
    },
    ffi_runtime_command_protocol() {
      return COMMAND_PROTOCOL;
    },
    ffi_runtime_session_dispatch_command_json(_session, rawCommand) {
      const parsedCommand = JSON.parse(rawCommand);
      return JSON.stringify(responder(parsedCommand));
    },
  };
}

function beforeEachTest() {
  kwiver_bridge_test_set_autoload(false);
  kwiver_bridge_test_reset();
}

function afterAllTests() {
  kwiver_bridge_test_reset();
  kwiver_bridge_test_set_autoload(true);
}

async function testUnavailableWhenAutoloadDisabled() {
  const ready = await kwiver_bridge_ready(0);
  const status = kwiver_bridge_status();

  assert.equal(ready, false);
  assert.equal(status.available, false);
  assert.equal(status.command_protocol, COMMAND_PROTOCOL);
}

function testRejectsMissingProtocol() {
  const installed = kwiver_bridge_test_install_mock_api(
    mockApiFromResponder(() => ({
      ok: true,
      result: { ok: true, payload: "{\"ok\":true}" },
      after: { payload: "{\"ok\":true}" },
    })),
  );
  assert.equal(installed, true);

  const imported = kwiver_bridge_import_payload_json("{\"cells\":[]}");
  assert.equal(imported, null);
}

function testRejectsProtocolMismatch() {
  const installed = kwiver_bridge_test_install_mock_api(
    mockApiFromResponder(() => ({
      ok: true,
      protocol: "kwiver.command.v2",
      result: { ok: true, payload: "{\"ok\":true}" },
      after: { payload: "{\"ok\":true}" },
    })),
  );
  assert.equal(installed, true);

  const imported = kwiver_bridge_import_payload_json("{\"cells\":[]}");
  assert.equal(imported, null);
}

function testBridgeUnavailableErrorFormatting() {
  const message = kwiver_bridge_unavailable_error({
    loaded_candidate: "http://localhost:8080/browser_ui/_build/js/release/build/runtime/runtime.js",
    load_errors: ["mock-load-error"],
  });
  assert.equal(
    message,
    "[kwiver-only] ui.bootstrap: bridge unavailable (candidate=http://localhost:8080/browser_ui/_build/js/release/build/runtime/runtime.js, error=mock-load-error)",
  );
  assert.equal(
    KWIVER_BRIDGE_UNAVAILABLE_DISPLAY_ERROR,
    "Kwiver runtime unavailable. Please verify server root and build artifacts.",
  );
}

function testBridgeUnavailableErrorFormattingFallback() {
  const message = kwiver_bridge_unavailable_error({});
  assert.equal(
    message,
    "[kwiver-only] ui.bootstrap: bridge unavailable (candidate=none, error=n/a)",
  );
}

function installRecordingMock(recorder = null) {
  const installed = kwiver_bridge_test_install_mock_api(
    mockApiFromResponder((command) => {
      if (Array.isArray(recorder)) {
        recorder.push(command);
      }
      switch (command.action) {
        case "all_cells_json":
          return {
            ok: true,
            protocol: COMMAND_PROTOCOL,
            result: [{ id: 1, kind: "vertex" }],
          };
        case "all_cell_ids_json":
          return {
            ok: true,
            protocol: COMMAND_PROTOCOL,
            result: [1, 2, 3],
          };
        case "connected_components_json":
          return {
            ok: true,
            protocol: COMMAND_PROTOCOL,
            result: [1, 2],
          };
        case "dependencies_of_json":
          return {
            ok: true,
            protocol: COMMAND_PROTOCOL,
            result: [6, 7],
          };
        case "transitive_dependencies_json":
          return {
            ok: true,
            protocol: COMMAND_PROTOCOL,
            result: [2, 3, 4],
          };
        case "transitive_reverse_dependencies_json":
          return {
            ok: true,
            protocol: COMMAND_PROTOCOL,
            result: [1, 2, 3],
          };
        case "preview_reconnect_plan_json":
          return {
            ok: true,
            protocol: COMMAND_PROTOCOL,
            result: {
              edge_id: 3,
              edges: [{ kind: "edge", id: 3 }],
            },
          };
        case "reverse_dependencies_of_json":
          return {
            ok: true,
            protocol: COMMAND_PROTOCOL,
            result: [9, 8],
          };
        case "export_selection":
          return {
            ok: true,
            protocol: COMMAND_PROTOCOL,
            result: "selection-payload",
          };
        case "render_tikz_json":
          return {
            ok: true,
            protocol: COMMAND_PROTOCOL,
            result: {
              data: "\\begin{tikzcd}A\\end{tikzcd}",
              metadata: {
                tikz_incompatibilities: [],
                dependencies: {},
              },
            },
          };
        case "render_fletcher":
          return {
            ok: true,
            protocol: COMMAND_PROTOCOL,
            result: "\\fletcher{}",
          };
        case "render_html_embed":
          return {
            ok: true,
            protocol: COMMAND_PROTOCOL,
            result: "<iframe></iframe>",
          };
        default:
          return {
            ok: true,
            protocol: COMMAND_PROTOCOL,
            result: {
              ok: true,
              payload: `payload-${command.action}`,
              selection: [1, 2],
            },
            after: {
              payload: `payload-${command.action}`,
              selection: [1, 2],
            },
          };
      }
    }),
  );
  assert.equal(installed, true);
}

function envelopeSelection(envelope) {
  if (Array.isArray(envelope?.result?.selection)) {
    return envelope.result.selection;
  }
  if (Array.isArray(envelope?.after?.selection)) {
    return envelope.after.selection;
  }
  return null;
}

function assertSelectionEnvelope(envelope) {
  assert.equal(Array.isArray(envelopeSelection(envelope)), true);
}

function testInteractionWrappersDispatchRuntimeCommands() {
  installRecordingMock();

  const cells = kwiver_bridge_all_cells();
  assert.equal(Array.isArray(cells), true);
  assert.equal(cells?.length, 1);

  const cellIds = kwiver_bridge_all_cell_ids("ui.test.all_cell_ids");
  assert.deepEqual(cellIds, [1, 2, 3]);

  const connectedIds = kwiver_bridge_connected_components([1], "ui.test.connected_components");
  assert.deepEqual(connectedIds, [1, 2]);

  const dependenciesIds = kwiver_bridge_dependencies(5, "ui.test.dependencies");
  assert.deepEqual(dependenciesIds, [6, 7]);

  const transitiveIds = kwiver_bridge_transitive_dependencies(
    [1, 2],
    true,
    "ui.test.transitive_dependencies",
  );
  assert.deepEqual(transitiveIds, [2, 3, 4]);

  const reverseIds = kwiver_bridge_transitive_reverse_dependencies(
    [4],
    "ui.test.transitive_reverse_dependencies",
  );
  assert.deepEqual(reverseIds, [1, 2, 3]);

  const reverseDependencyIds = kwiver_bridge_reverse_dependencies(
    7,
    "ui.test.reverse_dependencies",
  );
  assert.deepEqual(reverseDependencyIds, [9, 8]);

  const previewPlan = kwiver_bridge_preview_reconnect_plan(
    3,
    2,
    1,
    "ui.test.preview_reconnect_plan",
  );
  assert.equal(previewPlan?.edge_id, 3);
  assert.equal(Array.isArray(previewPlan?.edges), true);

  const setSelectionEnvelope = kwiver_bridge_set_selection([1, 2], "ui.test.selection");
  assert.equal(setSelectionEnvelope?.ok, true);
  assertSelectionEnvelope(setSelectionEnvelope);

  const selectionPayload = kwiver_bridge_export_selection(true, "ui.test.selection");
  assert.equal(selectionPayload, "selection-payload");

  const addVertexEnvelope = kwiver_bridge_add_vertex_json("A", 4, 5, null, "ui.test.create.vertex");
  assert.equal(addVertexEnvelope?.ok, true);
  assertSelectionEnvelope(addVertexEnvelope);

  const addEdgeEnvelope = kwiver_bridge_add_edge_json(1, 2, "f", null, null, "ui.test.create.edge");
  assert.equal(addEdgeEnvelope?.ok, true);
  assertSelectionEnvelope(addEdgeEnvelope);

  const moveEnvelope = kwiver_bridge_move_vertex_json(1, 7, 8, "ui.test.move");
  assert.equal(moveEnvelope?.ok, true);
  assertSelectionEnvelope(moveEnvelope);

  const setLabelColourEnvelope = kwiver_bridge_set_label_colour_json(
    1,
    { h: 10, s: 20, l: 30, a: 1 },
    "ui.test.label_colour",
  );
  assert.equal(setLabelColourEnvelope?.ok, true);
  assertSelectionEnvelope(setLabelColourEnvelope);

  const removeEnvelope = kwiver_bridge_remove_json(1, 12, "ui.test.remove");
  assert.equal(removeEnvelope?.ok, true);
  assertSelectionEnvelope(removeEnvelope);

  const setOffsetEnvelope = kwiver_bridge_set_edge_offset_json(2, 3, "ui.test.edge.offset");
  assert.equal(setOffsetEnvelope?.ok, true);
  assertSelectionEnvelope(setOffsetEnvelope);

  const setCurveEnvelope = kwiver_bridge_set_edge_curve_json(2, -4, "ui.test.edge.curve");
  assert.equal(setCurveEnvelope?.ok, true);
  assertSelectionEnvelope(setCurveEnvelope);

  const setAlignmentEnvelope = kwiver_bridge_set_edge_label_alignment_json(
    2,
    "centre",
    "ui.test.edge.label_alignment",
  );
  assert.equal(setAlignmentEnvelope?.ok, true);
  assertSelectionEnvelope(setAlignmentEnvelope);

  const setPositionEnvelope = kwiver_bridge_set_edge_label_position_json(
    2,
    60,
    "ui.test.edge.label_position",
  );
  assert.equal(setPositionEnvelope?.ok, true);
  assertSelectionEnvelope(setPositionEnvelope);

  const reverseEnvelope = kwiver_bridge_reverse_edge_json(2, "ui.test.edge.reverse");
  assert.equal(reverseEnvelope?.ok, true);
  assertSelectionEnvelope(reverseEnvelope);

  const flipEnvelope = kwiver_bridge_flip_edge_json(2, "ui.test.edge.flip");
  assert.equal(flipEnvelope?.ok, true);
  assertSelectionEnvelope(flipEnvelope);

  const flipLabelsEnvelope = kwiver_bridge_flip_edge_labels_json(2, "ui.test.edge.flip_labels");
  assert.equal(flipLabelsEnvelope?.ok, true);
  assertSelectionEnvelope(flipLabelsEnvelope);

  const pasteEnvelope = kwiver_bridge_paste_selection_json(
    "selection-payload",
    20,
    30,
    10,
    "ui.test.paste",
  );
  assert.equal(pasteEnvelope?.ok, true);
  assertSelectionEnvelope(pasteEnvelope);
}

function testRenderWrappersDispatchRuntimeCommands() {
  installRecordingMock();

  const settings = {
    get(key) {
      if (key === "quiver.embed.fixed_size") {
        return false;
      }
      if (key === "quiver.embed.width") {
        return 123;
      }
      if (key === "quiver.embed.height") {
        return 45;
      }
      if (key === "quiver.export.centre_diagrams") {
        return true;
      }
      if (key === "quiver.export.spread") {
        return "normal";
      }
      if (key === "quiver.export.cramped") {
        return false;
      }
      if (key === "quiver.renderer") {
        return "canvas";
      }
      return undefined;
    },
  };
  const options = {
    macro_url: "https://example.com/macros.tex",
  };

  const previousWindow = globalThis.window;
  globalThis.window = {
    location: {
      href: "https://q.uiver.app/editor?x=1#hash",
    },
  };
  try {
    const tikzExported = kwiver_bridge_export("tikz-cd", settings, options, {});
    assert.equal(tikzExported?.data, "\\begin{tikzcd}A\\end{tikzcd}");

    const fletcherExported = kwiver_bridge_export("fletcher", settings, options, {});
    assert.equal(fletcherExported?.data, "\\fletcher{}");

    const htmlExported = kwiver_bridge_export("html", settings, options, {});
    assert.equal(htmlExported?.data, "<iframe></iframe>");
  } finally {
    globalThis.window = previousWindow;
  }
}

function testExportBase64UsesRuntimePayload() {
  const installed = kwiver_bridge_test_install_mock_api(
    mockApiFromResponder(() => ({
      ok: true,
      protocol: COMMAND_PROTOCOL,
      result: "payload-123",
      after: { payload: "payload-123" },
    })),
  );
  assert.equal(installed, true);

  const previousWindow = globalThis.window;
  globalThis.window = {
    location: {
      href: "https://q.uiver.app/#seed",
    },
  };

  try {
    const exported = kwiver_bridge_export(
      "base64",
      {
        get(key) {
          return key === "quiver.renderer" ? "typst" : undefined;
        },
      },
      {
        macro_url: "https://example.com/macros.tex",
      },
      {},
    );
    assert.equal(
      exported?.data,
      "https://q.uiver.app/#r=typst&q=payload-123&macro_url=https%3A%2F%2Fexample.com%2Fmacros.tex",
    );
  } finally {
    globalThis.window = previousWindow;
  }
}

function testResetUsesRuntimeResetAction() {
  const installed = kwiver_bridge_test_install_mock_api(
    mockApiFromResponder(() => ({
      ok: true,
      protocol: COMMAND_PROTOCOL,
      result: {},
    })),
  );
  assert.equal(installed, true);

  const reset = kwiver_bridge_reset("ui.test.reset");
  assert.equal(reset?.ok, true);
}

function testReconnectDispatchesRuntimeMutation() {
  const installed = kwiver_bridge_test_install_mock_api(
    mockApiFromResponder(() => ({
      ok: true,
      protocol: COMMAND_PROTOCOL,
      result: { ok: true, payload: "payload-after-reconnect" },
      after: { payload: "payload-after-reconnect" },
    })),
  );
  assert.equal(installed, true);

  const reconnectEnvelope = kwiver_bridge_reconnect_edge_json(7, 2, 3, "ui.test.reconnect");
  assert.equal(reconnectEnvelope?.ok, true);
}

function testSetLabelDispatchesRuntimeMutation() {
  const installed = kwiver_bridge_test_install_mock_api(
    mockApiFromResponder(() => ({
      ok: true,
      protocol: COMMAND_PROTOCOL,
      result: { ok: true, payload: "payload-after-label" },
      after: { payload: "payload-after-label" },
    })),
  );
  assert.equal(installed, true);

  const labelEnvelope = kwiver_bridge_set_label_json(11, "f", "ui.test.label");
  assert.equal(labelEnvelope?.ok, true);
}

function testPatchEdgeOptionsDispatchesRuntimeMutation() {
  const installed = kwiver_bridge_test_install_mock_api(
    mockApiFromResponder(() => ({
      ok: true,
      protocol: COMMAND_PROTOCOL,
      result: { ok: true, payload: "payload-after-patch" },
      after: { payload: "payload-after-patch" },
    })),
  );
  assert.equal(installed, true);

  const patch = {
    level: 3,
    edge_alignment_source: true,
  };
  const patchEnvelope = kwiver_bridge_patch_edge_options_json(13, patch, "ui.test.patch");
  assert.equal(patchEnvelope?.ok, true);
}

function testPureGeometryWrappersUseBridgeExports() {
  const installed = kwiver_bridge_test_install_mock_api({
    ...mockApiFromResponder(() => ({
      ok: true,
      protocol: COMMAND_PROTOCOL,
      result: {},
    })),
    ffi_runtime_bezier_point(originX, originY, w, h, _angle, t) {
      return { x: originX + w * t, y: originY + h * t };
    },
    ffi_runtime_bezier_tangent() {
      return 1.25;
    },
    ffi_runtime_bezier_arc_length(_originX, _originY, w, _h, _angle, t) {
      return w * t;
    },
    ffi_runtime_bezier_t_after_length(_originX, _originY, w, _h, _angle, length) {
      return length / w;
    },
    ffi_runtime_bezier_height(_originX, _originY, _w, h) {
      return h / 2;
    },
    ffi_runtime_bezier_width(_originX, _originY, w) {
      return w;
    },
    ffi_runtime_bezier_intersections_with_rounded_rectangle() {
      return [
        { x: 1, y: 2, t: 0.25, angle: 0.5 },
        { x: 3, y: 4, t: 0.75, angle: 1.5 },
      ];
    },
    ffi_runtime_arc_point(originX, originY, chord, _major, _radius, _angle, t) {
      return { x: originX + chord * t, y: originY + t };
    },
    ffi_runtime_arc_tangent() {
      return 2.5;
    },
    ffi_runtime_arc_arc_length(_originX, _originY, chord, _major, _radius, _angle, t) {
      return chord * t;
    },
    ffi_runtime_arc_t_after_length(_originX, _originY, chord, _major, _radius, _angle, length) {
      return length / chord;
    },
    ffi_runtime_arc_height() {
      return 8;
    },
    ffi_runtime_arc_width() {
      return 13;
    },
    ffi_runtime_arc_angle_in_arc(_originX, _originY, _chord, _major, _radius, _angle, targetAngle) {
      return targetAngle < Math.PI;
    },
    ffi_runtime_arc_intersections_with_rounded_rectangle() {
      return [
        { x: 6, y: 7, t: 0.1, angle: 0.2 },
        { x: 8, y: 9, t: 0.9, angle: 0.4 },
      ];
    },
    ffi_runtime_arrow_find_endpoints_local() {
      return {
        ok: true,
        start: { x: 10, y: 11, t: 0.2, angle: 0.3 },
        end: { x: 20, y: 21, t: 0.8, angle: 0.9 },
      };
    },
    ffi_runtime_arrow_label_position_local() {
      return { x: 14, y: -6 };
    },
    ffi_runtime_arrow_render_plan_local() {
      return {
        ok: true,
        edge_valid: false,
        angle: 0.75,
        shift: { x: 2, y: 3 },
        svg_width: 120,
        svg_height: 80,
        offset: { x: 4, y: 5 },
        start: { x: 10, y: 11, t: 0.2, angle: 0.3 },
        end: { x: 20, y: 21, t: 0.8, angle: 0.9 },
        background: { d: "M 0 0\nh 5", dash_array: "0 1 2 3" },
        edge: { d: "M 4 5\nl 6 7", dash_array: "0 8 9" },
        clipping_path: { d: "M 1 1\nv 2", dash_array: "3 4 5" },
        decoration: {
          kind: "solid-circle",
          path_d: "",
          circle: { cx: 31, cy: 32, r: 6 },
          mask_circle: null,
        },
        tail: { has_path: true, d: "M 1 2\nl 3 4", total_width: 5 },
        tail_mask: { has_path: false, d: "", total_width: 0 },
        head: { has_path: true, d: "M 6 7\nh 8", total_width: 9 },
        head_mask: { has_path: true, d: "M 10 11\nv 12", total_width: 13 },
      };
    },
  });
  assert.equal(installed, true);

  assert.deepEqual(
    kwiver_bridge_bezier_point(1, 2, 4, 6, 0, 0.5),
    { x: 3, y: 5 },
  );
  assert.equal(kwiver_bridge_bezier_tangent(1, 2, 4, 6, 0, 0.5), 1.25);
  assert.equal(kwiver_bridge_bezier_arc_length(1, 2, 4, 6, 0, 0.5), 2);
  assert.equal(kwiver_bridge_bezier_t_after_length(1, 2, 4, 6, 0, 1), 0.25);
  assert.equal(kwiver_bridge_bezier_height(1, 2, 4, 6, 0), 3);
  assert.equal(kwiver_bridge_bezier_width(1, 2, 4, 6, 0), 4);
  assert.deepEqual(
    kwiver_bridge_bezier_intersections_with_rounded_rectangle(
      1, 2, 4, 6, 0,
      10, 20, 30, 40, 5,
      false,
    ),
    [
      { x: 1, y: 2, t: 0.25, angle: 0.5 },
      { x: 3, y: 4, t: 0.75, angle: 1.5 },
    ],
  );

  assert.deepEqual(
    kwiver_bridge_arc_point(3, 4, 10, false, 8, 0, 0.5),
    { x: 8, y: 4.5 },
  );
  assert.equal(kwiver_bridge_arc_tangent(3, 4, 10, false, 8, 0, 0.5), 2.5);
  assert.equal(kwiver_bridge_arc_arc_length(3, 4, 10, false, 8, 0, 0.5), 5);
  assert.equal(kwiver_bridge_arc_t_after_length(3, 4, 10, false, 8, 0, 2), 0.2);
  assert.equal(kwiver_bridge_arc_height(3, 4, 10, false, 8, 0), 8);
  assert.equal(kwiver_bridge_arc_width(3, 4, 10, false, 8, 0), 13);
  assert.equal(kwiver_bridge_arc_angle_in_arc(3, 4, 10, false, 8, 0, 1), true);
  assert.equal(kwiver_bridge_arc_angle_in_arc(3, 4, 10, false, 8, 0, Math.PI), false);
  assert.deepEqual(
    kwiver_bridge_arc_intersections_with_rounded_rectangle(
      3, 4, 10, false, 8, 0,
      30, 40, 16, 18, 6,
      true,
    ),
    [
      { x: 6, y: 7, t: 0.1, angle: 0.2 },
      { x: 8, y: 9, t: 0.9, angle: 0.4 },
    ],
  );
  assert.deepEqual(
    kwiver_bridge_arrow_find_endpoints_local(
      1, 2, 3, 4,
      false, 5, 6, 20, 10, 4,
      true, 7, 8, 0, 0, 0,
      false, 1, 3, 15, -2,
    ),
    {
      ok: true,
      start: { x: 10, y: 11, t: 0.2, angle: 0.3 },
      end: { x: 20, y: 21, t: 0.8, angle: 0.9 },
    },
  );
  assert.deepEqual(
    kwiver_bridge_arrow_label_position_local(
      1, 2, 3, 4,
      false, 5, 6, 20, 10, 4,
      true, 7, 8, 0, 0, 0,
      false, 1, 3, 15, -2,
      "left", 60,
      22, 12, 3,
    ),
    { x: 14, y: -6 },
  );
  assert.deepEqual(
    kwiver_bridge_arrow_render_plan_local(
      1, 2, 3, 4,
      false, 5, 6, 20, 10, 4,
      true, 7, 8, 0, 0, 0,
      false,
      false,
      1,
      3,
      15,
      -2,
      24,
      0.7,
      2,
      7.5,
      9,
      8,
      16,
      1.5,
      1,
      2,
      "proarrow",
      "dashed",
      "epi",
      "epi,mono",
    ),
    {
      ok: true,
      edge_valid: false,
      angle: 0.75,
      shift: { x: 2, y: 3 },
      svg_width: 120,
      svg_height: 80,
      offset: { x: 4, y: 5 },
      start: { x: 10, y: 11, t: 0.2, angle: 0.3 },
      end: { x: 20, y: 21, t: 0.8, angle: 0.9 },
      background: { d: "M 0 0\nh 5", dash_array: "0 1 2 3" },
      edge: { d: "M 4 5\nl 6 7", dash_array: "0 8 9" },
      clipping_path: { d: "M 1 1\nv 2", dash_array: "3 4 5" },
      decoration: {
        kind: "solid-circle",
        path_d: "",
        circle: { cx: 31, cy: 32, r: 6 },
        mask_circle: null,
      },
      tail: { has_path: true, d: "M 1 2\nl 3 4", total_width: 5 },
      tail_mask: { has_path: false, d: "", total_width: 0 },
      head: { has_path: true, d: "M 6 7\nh 8", total_width: 9 },
      head_mask: { has_path: true, d: "M 10 11\nv 12", total_width: 13 },
    },
  );
}

function testQueryWrappersRejectMalformedResults() {
  const installed = kwiver_bridge_test_install_mock_api(
    mockApiFromResponder((command) => {
      switch (command.action) {
        case "all_cell_ids_json":
          return {
            ok: true,
            protocol: COMMAND_PROTOCOL,
            result: [1, "x"],
          };
        case "connected_components_json":
          return {
            ok: true,
            protocol: COMMAND_PROTOCOL,
            result: [2, {}],
          };
        case "dependencies_of_json":
          return {
            ok: true,
            protocol: COMMAND_PROTOCOL,
            result: { ids: [3] },
          };
        case "transitive_dependencies_json":
          return {
            ok: true,
            protocol: COMMAND_PROTOCOL,
            result: [4, "bad"],
          };
        case "transitive_reverse_dependencies_json":
          return {
            ok: true,
            protocol: COMMAND_PROTOCOL,
            result: [5, {}],
          };
        case "reverse_dependencies_of_json":
          return {
            ok: true,
            protocol: COMMAND_PROTOCOL,
            result: [6, {}],
          };
        default:
          return {
            ok: true,
            protocol: COMMAND_PROTOCOL,
            result: [],
          };
      }
    }),
  );
  assert.equal(installed, true);

  const allCellIds = kwiver_bridge_all_cell_ids("ui.test.bad.all_cell_ids");
  assert.equal(allCellIds, null);

  const connected = kwiver_bridge_connected_components([1], "ui.test.bad.connected_components");
  assert.equal(connected, null);

  const dependencies = kwiver_bridge_dependencies(9, "ui.test.bad.dependencies");
  assert.equal(dependencies, null);

  const transitive = kwiver_bridge_transitive_dependencies(
    [1],
    false,
    "ui.test.bad.transitive_dependencies",
  );
  assert.equal(transitive, null);

  const transitiveReverse = kwiver_bridge_transitive_reverse_dependencies(
    [1],
    "ui.test.bad.transitive_reverse_dependencies",
  );
  assert.equal(transitiveReverse, null);

  const reverse = kwiver_bridge_reverse_dependencies(9, "ui.test.bad.reverse_dependencies");
  assert.equal(reverse, null);

  const preview = kwiver_bridge_preview_reconnect_plan(
    3,
    2,
    1,
    "ui.test.bad.preview_reconnect_plan",
  );
  assert.equal(preview, null);
}

const TEST_CASES = [
  [
    "bridge smoke: unavailable when autoload is disabled and no mock is installed",
    testUnavailableWhenAutoloadDisabled,
  ],
  [
    "bridge smoke: import payload rejects response without protocol",
    testRejectsMissingProtocol,
  ],
  [
    "bridge smoke: import payload rejects response with protocol mismatch",
    testRejectsProtocolMismatch,
  ],
  [
    "bridge smoke: startup fail-fast error message includes candidate and first load error",
    testBridgeUnavailableErrorFormatting,
  ],
  [
    "bridge smoke: startup fail-fast error message falls back to none/n-a details",
    testBridgeUnavailableErrorFormattingFallback,
  ],
  [
    "bridge smoke: bridge-backed interaction wrappers return bridged results",
    testInteractionWrappersDispatchRuntimeCommands,
  ],
  [
    "bridge smoke: query wrappers reject malformed runtime results",
    testQueryWrappersRejectMalformedResults,
  ],
  [
    "bridge smoke: runtime render wrappers return rendered output",
    testRenderWrappersDispatchRuntimeCommands,
  ],
  [
    "bridge smoke: base64 export uses bridged payload in share URL",
    testExportBase64UsesRuntimePayload,
  ],
  [
    "bridge smoke: ui reset returns bridged envelope",
    testResetUsesRuntimeResetAction,
  ],
  [
    "bridge smoke: reconnect path returns bridged envelope",
    testReconnectDispatchesRuntimeMutation,
  ],
  [
    "bridge smoke: set label path returns bridged envelope",
    testSetLabelDispatchesRuntimeMutation,
  ],
  [
    "bridge smoke: patch edge options path returns bridged envelope",
    testPatchEdgeOptionsDispatchesRuntimeMutation,
  ],
  [
    "bridge smoke: pure geometry wrappers use MoonBit bridge exports",
    testPureGeometryWrappersUseBridgeExports,
  ],
];

async function runSmokeTests() {
  let passed = 0;
  let failed = 0;
  for (const [name, fn] of TEST_CASES) {
    beforeEachTest();
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
  afterAllTests();

  if (failed > 0) {
    throw new Error(`kwiver bridge smoke failed: ${failed}/${TEST_CASES.length}`);
  }
  console.log(`kwiver bridge smoke passed: ${passed}/${TEST_CASES.length}`);
}

await runSmokeTests();
