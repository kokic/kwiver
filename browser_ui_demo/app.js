const MODULE_CANDIDATES = [
  "../_build/js/release/build/browser_demo/browser_demo.js",
  "../_build/js/debug/build/browser_demo/browser_demo.js",
];

const SVG_NS = "http://www.w3.org/2000/svg";
const GRID = 140;
const PAD = 96;
const HISTORY_LIMIT = 120;
const CLICK_SUPPRESS_MS = 180;
const DRAG_THRESHOLD = 6;
const BOX_THRESHOLD = 4;
const NODE_RADIUS = 30;
const MUTATING = new Set([
  "graph.seed_ab",
  "graph.add_vertex",
  "graph.add_edge",
  "graph.move_vertex",
  "graph.move_vertices",
  "graph.remove",
  "cell.set_label",
  "selection.delete",
  "selection.paste",
  "import.payload",
  "import.text_auto",
  "runtime.dispatch",
]);

const app = {
  api: null,
  session: null,
  commandSequence: 0,
  runtimeCommandNonce: 0,
  operationCount: 0,
  lastCommand: null,
  lastResult: null,
  commandHistory: [],
  stateRaw: "{}",
  stateObject: {},
  snapshotRaw: "{}",
  snapshotObject: {},
  cellsRaw: "[]",
  cellsObject: [],
  lastRenderKind: "tikz-cd",
  lastRenderOutput: "",
  queryOutput: null,
  importOutput: null,
  selectionOutput: null,
  clipboardPayload: "",
  undoStack: [],
  redoStack: [],
  canvasBounds: null,
  canvasPoints: new Map(),
  canvasVertexById: new Map(),
  canvasEdgeById: new Map(),
  interaction: {
    mode: "idle",
    pointerId: null,
    sourceId: null,
    point: null,
    hoverId: null,
    startPoint: null,
    moved: false,
    dragIds: [],
    dragDelta: { x: 0, y: 0 },
    boxAdditive: false,
    suppressClickUntil: 0,
  },
  labelEdit: {
    cellId: null,
    x: 0,
    y: 0,
  },
};

const refs = {
  status: byId("status"),
  summary: byId("summary"),
  canvasMeta: byId("canvas-meta"),
  renderKind: byId("render-kind"),
  renderOutput: byId("render-output"),
  stateJson: byId("state-json"),
  snapshotJson: byId("snapshot-json"),
  cellsJson: byId("cells-json"),
  lastCommand: byId("last-command"),
  lastResult: byId("last-result"),
  commandHistory: byId("command-history"),
  commandJson: byId("command-json"),
  queryResult: byId("query-result"),
  importResult: byId("import-result"),
  selectionResult: byId("selection-result"),
  graphSvg: byId("graph-svg"),
  graphNodes: byId("graph-nodes"),
  canvasStage: byId("canvas-stage"),
  selectionRect: byId("selection-rect"),
  labelEditor: byId("label-editor"),
  labelEditorInput: byId("label-editor-input"),
  btnLabelSave: byId("btn-label-save"),
  btnLabelCancel: byId("btn-label-cancel"),
  vertexLabel: byId("vertex-label"),
  vertexX: byId("vertex-x"),
  vertexY: byId("vertex-y"),
  edgeSource: byId("edge-source"),
  edgeTarget: byId("edge-target"),
  edgeLabel: byId("edge-label"),
  removeId: byId("remove-id"),
  selectionInput: byId("selection-input"),
  includeDeps: byId("include-deps"),
  selectionPayload: byId("selection-payload"),
  pasteX: byId("paste-x"),
  pasteY: byId("paste-y"),
  payloadInput: byId("payload-input"),
  importText: byId("import-text"),
  importRenderer: byId("import-renderer"),
  queryCellId: byId("query-cell-id"),
  queryRoots: byId("query-roots"),
  queryExcludeRoots: byId("query-exclude-roots"),
  btnNewSession: byId("btn-new-session"),
  btnUndo: byId("btn-undo"),
  btnRedo: byId("btn-redo"),
  btnCopySelection: byId("btn-copy-selection"),
  btnCutSelection: byId("btn-cut-selection"),
  btnPasteSelectionTop: byId("btn-paste-selection-top"),
  btnDeleteSelection: byId("btn-delete-selection"),
  btnSeed: byId("btn-seed"),
  btnRenderTikz: byId("btn-render-tikz"),
  btnRenderFletcher: byId("btn-render-fletcher"),
  btnRenderHtml: byId("btn-render-html"),
  btnSetSelection: byId("btn-set-selection"),
  btnExportSelection: byId("btn-export-selection"),
  btnPasteSelection: byId("btn-paste-selection"),
  btnImportPayload: byId("btn-import-payload"),
  btnImportAuto: byId("btn-import-auto"),
  btnDeps: byId("btn-deps"),
  btnRevDeps: byId("btn-rev-deps"),
  btnTransitive: byId("btn-transitive"),
  btnComponents: byId("btn-components"),
  btnDispatchJson: byId("btn-dispatch-json"),
  btnClearHistory: byId("btn-clear-history"),
  formAddVertex: byId("form-add-vertex"),
  formAddEdge: byId("form-add-edge"),
  formRemove: byId("form-remove"),
};

function byId(id) {
  const node = document.getElementById(id);
  if (!node) throw new Error(`Missing DOM node #${id}`);
  return node;
}

function toInt(v, fallback = 0) {
  const n = Number.parseInt(String(v), 10);
  return Number.isFinite(n) ? n : fallback;
}

function parseIds(raw) {
  return String(raw).split(",").map((s) => toInt(s.trim(), Number.NaN)).filter(Number.isFinite);
}

function uniq(values) {
  const out = [];
  const seen = new Set();
  for (const v of values) {
    const n = toInt(v, Number.NaN);
    if (Number.isFinite(n) && !seen.has(n)) {
      seen.add(n);
      out.push(n);
    }
  }
  return out;
}

function pj(s) {
  try {
    return JSON.parse(s);
  } catch (_) {
    return null;
  }
}

function fj(v) {
  if (typeof v === "string") {
    const p = pj(v);
    return p === null ? v : JSON.stringify(p, null, 2);
  }
  return v == null ? "" : JSON.stringify(v, null, 2);
}

function editable(target) {
  return target instanceof HTMLElement &&
    Boolean(target.closest('input, textarea, select, [contenteditable="true"], [contenteditable=""]'));
}

function status(text, error = false) {
  refs.status.textContent = text;
  refs.status.classList.toggle("error", error);
}

function outcome(ok, result, note, refresh = true, runtimeEnvelope = null) {
  return { ok, result, note, refresh, runtimeEnvelope };
}

function payload() {
  return typeof app.stateObject.payload === "string" ? app.stateObject.payload : "";
}

function initUndo() {
  app.undoStack = [payload()];
  app.redoStack = [];
}

function pushUndo() {
  const p = payload();
  if (app.undoStack.length === 0 || app.undoStack[app.undoStack.length - 1] !== p) {
    app.undoStack.push(p);
    app.redoStack = [];
  }
}

function sync() {
  if (!app.api || !app.session) return;
  app.stateRaw = app.api.ffi_browser_demo_session_state_json(app.session);
  app.snapshotRaw = app.api.ffi_browser_demo_session_snapshot_json(app.session);
  app.cellsRaw = app.api.ffi_browser_demo_session_all_cells_json(app.session);
  app.stateObject = pj(app.stateRaw) ?? {};
  app.snapshotObject = pj(app.snapshotRaw) ?? {};
  app.cellsObject = pj(app.cellsRaw) ?? [];
  if (typeof app.stateObject.payload === "string" && document.activeElement !== refs.payloadInput) {
    refs.payloadInput.value = app.stateObject.payload;
  }
  if (document.activeElement !== refs.selectionInput) {
    refs.selectionInput.value = Array.isArray(app.stateObject.selection) ? app.stateObject.selection.join(",") : "";
  }
}

function objectResult(value) {
  return value && typeof value === "object" && !Array.isArray(value) ? value : {};
}

function nextCommandId(origin = "ui") {
  const prefix = typeof origin === "string" && origin !== "" ? origin : "ui";
  app.runtimeCommandNonce += 1;
  return `${prefix}-${app.commandSequence + 1}-${app.operationCount + 1}-${app.runtimeCommandNonce}`;
}

function runRuntimeEnvelope(command, originOverride = null) {
  if (!app.api || !app.session || typeof app.api.ffi_browser_demo_session_dispatch_command_json !== "function") {
    return {
      ok: false,
      envelope: {
        ok: false,
        action: typeof command?.action === "string" ? command.action : "unknown",
        error: "Runtime command envelope API is unavailable.",
      },
    };
  }

  const payload = command && typeof command === "object" ? { ...command } : {};
  if (typeof payload.origin !== "string" && typeof originOverride === "string" && originOverride !== "") {
    payload.origin = originOverride;
  }
  if (typeof payload.command_id !== "string" || payload.command_id === "") {
    payload.command_id = nextCommandId(payload.origin);
  }

  try {
    const raw = app.api.ffi_browser_demo_session_dispatch_command_json(
      app.session,
      JSON.stringify(payload),
    );
    const parsed = pj(raw);
    if (!parsed || typeof parsed !== "object") {
      return {
        ok: false,
        envelope: {
          ok: false,
          action: typeof payload.action === "string" ? payload.action : "unknown",
          error: "Malformed runtime envelope response.",
          raw,
        },
      };
    }
    return { ok: Boolean(parsed.ok), envelope: parsed };
  } catch (e) {
    return {
      ok: false,
      envelope: {
        ok: false,
        action: typeof payload.action === "string" ? payload.action : "unknown",
        error: String(e),
      },
    };
  }
}

function runRuntimeAction(action, input, origin = "ui", extra = {}) {
  const command = { action, ...extra };
  if (input !== undefined) command.input = input;
  return runRuntimeEnvelope(command, origin);
}

function applyRuntimeCheckpoints(type, res) {
  const envelope = res?.runtimeEnvelope;
  if (!envelope || typeof envelope !== "object") return false;
  if (!MUTATING.has(type) || envelope.changed !== true) return false;

  const undo = typeof envelope.undo_checkpoint === "string" ? envelope.undo_checkpoint : null;
  const redo = typeof envelope.redo_checkpoint === "string" ? envelope.redo_checkpoint : null;
  if (undo == null && redo == null) return false;

  if (undo !== null && (app.undoStack.length === 0 || app.undoStack[app.undoStack.length - 1] !== undo)) {
    app.undoStack.push(undo);
  }
  if (redo !== null && (app.undoStack.length === 0 || app.undoStack[app.undoStack.length - 1] !== redo)) {
    app.undoStack.push(redo);
  }
  app.redoStack = [];
  return true;
}

const HANDLERS = {
  "session.new": () => {
    app.session = app.api.ffi_browser_demo_session_new();
    app.lastRenderKind = "tikz-cd";
    app.lastRenderOutput = "";
    app.queryOutput = null;
    app.importOutput = null;
    app.selectionOutput = null;
    app.clipboardPayload = "";
    return outcome(true, { created: true }, "new session");
  },

  "session.undo": () => {
    if (app.undoStack.length <= 1) {
      return outcome(false, { undo_depth: 0, redo_depth: app.redoStack.length }, "nothing to undo", false);
    }
    const current = app.undoStack.pop();
    if (current !== undefined) app.redoStack.push(current);
    const target = app.undoStack[app.undoStack.length - 1];
    const ok = app.api.ffi_browser_demo_session_import_payload(app.session, target);
    if (!ok) {
      const rollback = app.redoStack.pop();
      if (rollback !== undefined) app.undoStack.push(rollback);
      return outcome(false, { ok }, "undo failed", false);
    }
    return outcome(true, {
      undo_depth: Math.max(0, app.undoStack.length - 1),
      redo_depth: app.redoStack.length,
    }, "undo");
  },

  "session.redo": () => {
    if (app.redoStack.length === 0) {
      return outcome(false, { undo_depth: Math.max(0, app.undoStack.length - 1), redo_depth: 0 }, "nothing to redo", false);
    }
    const target = app.redoStack.pop();
    if (target === undefined) return outcome(false, { ok: false }, "redo underflow", false);
    const ok = app.api.ffi_browser_demo_session_import_payload(app.session, target);
    if (!ok) {
      app.redoStack.push(target);
      return outcome(false, { ok }, "redo failed", false);
    }
    app.undoStack.push(target);
    return outcome(true, {
      undo_depth: Math.max(0, app.undoStack.length - 1),
      redo_depth: app.redoStack.length,
    }, "redo");
  },

  "graph.seed_ab": () => {
    const a = app.api.ffi_browser_demo_session_add_vertex(app.session, "A", 0, 0);
    const b = app.api.ffi_browser_demo_session_add_vertex(app.session, "B", 1, 0);
    const e = app.api.ffi_browser_demo_session_add_edge(app.session, a, b, "f");
    const selection = app.api.ffi_browser_demo_session_set_selection(app.session, [a, e]);
    return outcome(true, { a, b, e, selection }, "seeded");
  },

  "graph.add_vertex": (input, _command, origin) => {
    const label = typeof input.label === "string" && input.label !== "" ? input.label : "V";
    const x = toInt(input.x, 0);
    const y = toInt(input.y, 0);
    const runtime = runRuntimeAction(
      "add_vertex_json",
      { label, x, y },
      origin,
    );
    const runtimeResult = objectResult(runtime.envelope?.result);
    const id = toInt(runtimeResult.id, -1);
    return outcome(runtime.ok, { id, label, x, y }, `vertex #${id}`, true, runtime.envelope);
  },

  "graph.add_edge": (input, _command, origin) => {
    const source_id = toInt(input.source_id, -1);
    const target_id = toInt(input.target_id, -1);
    const label = typeof input.label === "string" ? input.label : "";
    const runtime = runRuntimeAction(
      "add_edge_json",
      { source_id, target_id, label },
      origin,
    );
    const runtimeResult = objectResult(runtime.envelope?.result);
    const id = toInt(runtimeResult.id, -1);
    return outcome(runtime.ok, { id, source_id, target_id, label }, `edge #${id}`, true, runtime.envelope);
  },

  "graph.move_vertex": (input, _command, origin) => {
    const vertex_id = toInt(input.vertex_id, -1);
    const x = toInt(input.x, 0);
    const y = toInt(input.y, 0);
    const runtime = runRuntimeAction(
      "move_vertex_json",
      { vertex_id, x, y },
      origin,
    );
    const runtimeResult = objectResult(runtime.envelope?.result);
    const ok = runtime.ok && Boolean(runtimeResult.ok);
    return outcome(ok, { ok, vertex_id, x, y }, ok ? "moved" : "move failed", true, runtime.envelope);
  },

  "graph.move_vertices": (input, _command, origin) => {
    const rawMoves = Array.isArray(input.moves) ? input.moves : [];
    const vertex_positions = [];
    for (const m of rawMoves) {
      const vertex_id = toInt(m?.vertex_id, -1);
      const x = toInt(m?.x, 0);
      const y = toInt(m?.y, 0);
      vertex_positions.push({ vertex_id, x, y });
    }
    if (vertex_positions.length === 0) {
      return outcome(false, { applied: [], count: 0 }, "group move empty", false);
    }
    const runtime = runRuntimeAction(
      "apply_mutation_batch_json",
      { vertex_positions },
      origin,
    );
    const runtimeResult = objectResult(runtime.envelope?.result);
    const rawResults = Array.isArray(runtimeResult.vertex_position_results)
      ? runtimeResult.vertex_position_results
      : [];
    const applied = vertex_positions.map((move, idx) => ({
      ...move,
      ok: Boolean(rawResults[idx]),
    }));
    const allOk = applied.length > 0 && applied.every((item) => item.ok);
    const ok = runtime.ok && allOk;
    return outcome(ok, { applied, count: applied.length }, ok ? "moved group" : "group move partial", true, runtime.envelope);
  },

  "cell.set_label": (input, _command, origin) => {
    const cell_id = toInt(input.cell_id, -1);
    const label = typeof input.label === "string" ? input.label : "";
    const runtime = runRuntimeAction(
      "set_label_json",
      { cell_id, label },
      origin,
    );
    const runtimeResult = objectResult(runtime.envelope?.result);
    const ok = runtime.ok && Boolean(runtimeResult.ok);
    return outcome(ok, { ok, cell_id, label }, ok ? "label updated" : "set label failed", true, runtime.envelope);
  },

  "graph.remove": (input, _command, origin) => {
    const cell_id = toInt(input.cell_id, -1);
    const when = toInt(input.when, 0);
    const runtime = runRuntimeAction(
      "remove_json",
      { cell_id, when },
      origin,
    );
    const runtimeResult = objectResult(runtime.envelope?.result);
    const removed_ids = Array.isArray(runtimeResult.removed_ids) ? runtimeResult.removed_ids : [];
    return outcome(runtime.ok, { cell_id, removed_ids }, `removed #${cell_id}`, true, runtime.envelope);
  },

  "selection.set": (input, _command, origin) => {
    const selected_ids = Array.isArray(input.selected_ids)
      ? uniq(input.selected_ids).filter((id) => id >= 0)
      : [];
    const runtime = runRuntimeAction("set_selection", selected_ids, origin);
    const normalized = Array.isArray(runtime.envelope?.result) ? runtime.envelope.result : [];
    return outcome(runtime.ok, { selected_ids: normalized }, "selection", true, runtime.envelope);
  },

  "selection.delete": (_input, _command, origin) => {
    const selected = uniq(Array.isArray(app.stateObject.selection) ? app.stateObject.selection : [])
      .filter((id) => id >= 0)
      .sort((a, b) => b - a);
    if (selected.length === 0) return outcome(false, { removed_ids: [] }, "selection empty", false);
    const removed = new Set();
    const applied = [];
    let allOk = true;
    let firstUndo = null;
    let lastRedo = null;
    for (const id of selected) {
      const runtime = runRuntimeAction(
        "remove_json",
        { cell_id: id, when: 0 },
        origin,
      );
      const runtimeResult = objectResult(runtime.envelope?.result);
      const removedIds = Array.isArray(runtimeResult.removed_ids) ? runtimeResult.removed_ids : [];
      removedIds.forEach((x) => removed.add(x));
      applied.push({ cell_id: id, ok: runtime.ok, removed_ids: removedIds });
      if (!runtime.ok) allOk = false;
      if (runtime.envelope?.changed === true) {
        if (firstUndo == null && typeof runtime.envelope.undo_checkpoint === "string") {
          firstUndo = runtime.envelope.undo_checkpoint;
        }
        if (typeof runtime.envelope.redo_checkpoint === "string") {
          lastRedo = runtime.envelope.redo_checkpoint;
        }
      }
    }
    const removed_ids = [...removed].sort((a, b) => a - b);
    const changed = firstUndo !== null || lastRedo !== null;
    const runtimeEnvelope = changed
      ? {
        ok: allOk,
        action: "remove_json",
        changed: true,
        undo_checkpoint: firstUndo,
        redo_checkpoint: lastRedo,
      }
      : null;
    const ok = removed_ids.length > 0;
    return outcome(
      ok,
      { selected_ids: selected, removed_ids, applied },
      ok ? (allOk ? "deleted" : "delete partial") : "nothing removed",
      true,
      runtimeEnvelope,
    );
  },

  "selection.export": (input, _command, origin) => {
    const include_dependencies = input.include_dependencies !== false;
    const runtime = runRuntimeAction(
      "export_selection",
      { include_dependencies },
      origin,
    );
    const payloadText = typeof runtime.envelope?.result === "string" ? runtime.envelope.result : "";
    refs.selectionPayload.value = payloadText;
    app.selectionOutput = { include_dependencies, payload_length: payloadText.length };
    return outcome(runtime.ok, { payload: payloadText, include_dependencies }, "selection exported", false, runtime.envelope);
  },

  "selection.paste": (input, _command, origin) => {
    const payloadText = typeof input.payload === "string" ? input.payload : "";
    const origin_x = toInt(input.origin_x, 0);
    const origin_y = toInt(input.origin_y, 0);
    const runtime = runRuntimeAction(
      "paste_selection_json",
      { payload: payloadText, origin_x, origin_y },
      origin,
    );
    const result = objectResult(runtime.envelope?.result);
    app.selectionOutput = result;
    const ok = runtime.ok && (result.ok !== false);
    return outcome(ok, result, "selection pasted", true, runtime.envelope);
  },

  "import.payload": (input, _command, origin) => {
    const payloadText = typeof input.payload === "string" ? input.payload : "";
    const runtime = runRuntimeAction("import_payload", payloadText, origin);
    const normalizedPayload = typeof runtime.envelope?.result === "string" ? runtime.envelope.result : payloadText;
    const ok = runtime.ok;
    return outcome(ok, { ok, payload_length: normalizedPayload.length }, "import payload", true, runtime.envelope);
  },

  "import.text_auto": (input, _command, origin) => {
    const text = typeof input.text === "string" ? input.text : "";
    const default_renderer = typeof input.default_renderer === "string" && input.default_renderer !== ""
      ? input.default_renderer
      : undefined;
    const runtime = runRuntimeAction(
      "import_text_auto_json",
      text,
      origin,
      default_renderer ? { default_renderer } : {},
    );
    const result = objectResult(runtime.envelope?.result);
    app.importOutput = result;
    const ok = runtime.ok && Boolean(result.ok);
    return outcome(ok, result, "import auto", true, runtime.envelope);
  },

  "query.dependencies_of": (input, _command, origin) => {
    const cell_id = toInt(input.cell_id, -1);
    const runtime = runRuntimeAction(
      "dependencies_of_json",
      { cell_id },
      origin,
    );
    const result = Array.isArray(runtime.envelope?.result) ? runtime.envelope.result : [];
    app.queryOutput = {
      type: "dependencies_of",
      cell_id,
      result,
    };
    return outcome(runtime.ok, app.queryOutput, "query", false, runtime.envelope);
  },

  "query.reverse_dependencies_of": (input, _command, origin) => {
    const cell_id = toInt(input.cell_id, -1);
    const runtime = runRuntimeAction(
      "reverse_dependencies_of_json",
      { cell_id },
      origin,
    );
    const result = Array.isArray(runtime.envelope?.result) ? runtime.envelope.result : [];
    app.queryOutput = {
      type: "reverse_dependencies_of",
      cell_id,
      result,
    };
    return outcome(runtime.ok, app.queryOutput, "query", false, runtime.envelope);
  },

  "query.transitive_dependencies": (input, _command, origin) => {
    const roots = Array.isArray(input.roots) ? uniq(input.roots).filter((id) => id >= 0) : [];
    const exclude_roots = Boolean(input.exclude_roots);
    const runtime = runRuntimeAction(
      "transitive_dependencies_json",
      { roots, exclude_roots },
      origin,
    );
    const result = Array.isArray(runtime.envelope?.result) ? runtime.envelope.result : [];
    app.queryOutput = {
      type: "transitive_dependencies",
      roots,
      exclude_roots,
      result,
    };
    return outcome(runtime.ok, app.queryOutput, "query", false, runtime.envelope);
  },

  "query.connected_components": (input, _command, origin) => {
    const roots = Array.isArray(input.roots) ? uniq(input.roots).filter((id) => id >= 0) : [];
    const runtime = runRuntimeAction(
      "connected_components_json",
      { roots },
      origin,
    );
    const result = Array.isArray(runtime.envelope?.result) ? runtime.envelope.result : [];
    app.queryOutput = {
      type: "connected_components",
      roots,
      result,
    };
    return outcome(runtime.ok, app.queryOutput, "query", false, runtime.envelope);
  },

  "render.tikz": (_input, _command, origin) => {
    const runtime = runRuntimeAction("render_tikz", undefined, origin);
    app.lastRenderKind = "tikz-cd";
    app.lastRenderOutput = typeof runtime.envelope?.result === "string" ? runtime.envelope.result : "";
    return outcome(runtime.ok, { length: app.lastRenderOutput.length }, "render", false, runtime.envelope);
  },

  "render.fletcher": (_input, _command, origin) => {
    const runtime = runRuntimeAction("render_fletcher", {}, origin);
    app.lastRenderKind = "fletcher";
    app.lastRenderOutput = typeof runtime.envelope?.result === "string" ? runtime.envelope.result : "";
    return outcome(runtime.ok, { length: app.lastRenderOutput.length }, "render", false, runtime.envelope);
  },

  "render.html_embed": (_input, _command, origin) => {
    const runtime = runRuntimeAction("render_html_embed", {}, origin);
    app.lastRenderKind = "html-embed";
    app.lastRenderOutput = typeof runtime.envelope?.result === "string" ? runtime.envelope.result : "";
    return outcome(runtime.ok, { length: app.lastRenderOutput.length }, "render", false, runtime.envelope);
  },

  "runtime.dispatch": (input, _command, origin) => {
    const runtime = runRuntimeEnvelope(input, origin);
    const action = typeof runtime.envelope?.action === "string" ? runtime.envelope.action : "unknown";
    return outcome(
      runtime.ok,
      runtime.envelope ?? {},
      runtime.ok ? `runtime ${action}` : `runtime ${action} failed`,
      true,
      runtime.envelope,
    );
  },
};

function register(command, res, elapsedMs, origin) {
  app.commandSequence += 1;
  app.operationCount += 1;
  app.lastCommand = command;
  app.lastResult = {
    ok: res.ok,
    note: res.note,
    result: res.result,
    elapsed_ms: elapsedMs,
    origin,
  };
  app.commandHistory.unshift({
    id: app.commandSequence,
    type: command.type,
    ok: res.ok,
    elapsed_ms: elapsedMs,
    note: res.note,
  });
  if (app.commandHistory.length > HISTORY_LIMIT) app.commandHistory.length = HISTORY_LIMIT;
}

function dispatch(command, origin = "ui") {
  const type = typeof command?.type === "string" ? command.type : "";
  if (!app.api) {
    const res = outcome(false, { error: "MoonBit module is not loaded yet." }, "runtime unavailable");
    register(command ?? { type: "<none>" }, res, 0, origin);
    status("MoonBit module is not loaded yet.", true);
    render();
    return res;
  }
  if (type === "") {
    const res = outcome(false, { error: "Command type is required." }, "invalid");
    register({ type: "<invalid>", input: command }, res, 0, origin);
    status("Command rejected: missing type", true);
    render();
    return res;
  }
  if (!app.session && type !== "session.new") {
    const res = outcome(false, { error: "No active session. Run session.new first." }, "runtime unavailable");
    register(command, res, 0, origin);
    status("No active session. Run session.new first.", true);
    render();
    return res;
  }

  const handler = HANDLERS[type];
  if (!handler) {
    const res = outcome(false, { error: `Unknown command type: ${type}` }, "unknown");
    register(command, res, 0, origin);
    status(`Unknown command: ${type}`, true);
    render();
    return res;
  }

  const t0 = performance.now();
  let res;
  try {
    res = handler(command.input ?? {}, command, origin);
  } catch (e) {
    res = outcome(false, { error: String(e) }, `failed: ${type}`);
  }
  const dt = Math.round((performance.now() - t0) * 100) / 100;
  register(command, res, dt, origin);
  if (res.refresh !== false) {
    sync();
    if (res.ok) {
      if (type === "session.new") initUndo();
      else if (!applyRuntimeCheckpoints(type, res) && MUTATING.has(type)) pushUndo();
    }
  }
  status(res.ok ? `OK | ${type} (${dt}ms)` : `FAIL | ${type} (${dt}ms)`, !res.ok);
  render();
  return res;
}

function bounds(vertices) {
  if (vertices.length === 0) {
    return { minX: 0, maxX: 0, minY: 0, maxY: 0, width: PAD * 2 + GRID, height: PAD * 2 + GRID };
  }
  let minX = vertices[0].x;
  let maxX = vertices[0].x;
  let minY = vertices[0].y;
  let maxY = vertices[0].y;
  for (const v of vertices) {
    minX = Math.min(minX, v.x);
    maxX = Math.max(maxX, v.x);
    minY = Math.min(minY, v.y);
    maxY = Math.max(maxY, v.y);
  }
  return { minX, maxX, minY, maxY, width: PAD * 2 + (maxX - minX + 1) * GRID, height: PAD * 2 + (maxY - minY + 1) * GRID };
}

function stagePoint(v, b) {
  return { x: PAD + (v.x - b.minX) * GRID + GRID / 2, y: PAD + (v.y - b.minY) * GRID + GRID / 2 };
}

function pointerStage(e) {
  const rect = refs.canvasStage.getBoundingClientRect();
  return { x: e.clientX - rect.left + refs.canvasStage.scrollLeft, y: e.clientY - rect.top + refs.canvasStage.scrollTop };
}

function stageToGrid(p) {
  const b = app.canvasBounds ?? bounds(Array.isArray(app.snapshotObject.vertices) ? app.snapshotObject.vertices : []);
  return {
    x: Math.round((p.x - PAD - GRID / 2) / GRID + b.minX),
    y: Math.round((p.y - PAD - GRID / 2) / GRID + b.minY),
  };
}

function nearestVertex(p, radius = 32, excludeId = null) {
  let bestId = null;
  let best = radius * radius;
  for (const [id, q] of app.canvasPoints.entries()) {
    if (excludeId !== null && id === excludeId) continue;
    const dx = q.x - p.x;
    const dy = q.y - p.y;
    const d = dx * dx + dy * dy;
    if (d <= best) {
      best = d;
      bestId = id;
    }
  }
  return bestId;
}

function pointerDistanceSq(a, b) {
  const dx = a.x - b.x;
  const dy = a.y - b.y;
  return dx * dx + dy * dy;
}

function rectFromPoints(a, b) {
  return {
    left: Math.min(a.x, b.x),
    top: Math.min(a.y, b.y),
    right: Math.max(a.x, b.x),
    bottom: Math.max(a.y, b.y),
  };
}

function rectContainsPoint(rect, p) {
  return p.x >= rect.left && p.x <= rect.right && p.y >= rect.top && p.y <= rect.bottom;
}

function trimSegment(start, end, startPad = NODE_RADIUS, endPad = NODE_RADIUS) {
  const dx = end.x - start.x;
  const dy = end.y - start.y;
  const len = Math.hypot(dx, dy);
  if (len <= 0.0001) {
    return { start, end };
  }
  return {
    start: { x: start.x + dx * (startPad / len), y: start.y + dy * (startPad / len) },
    end: { x: end.x - dx * (endPad / len), y: end.y - dy * (endPad / len) },
  };
}

function quadraticControl(start, end, bend) {
  const dx = end.x - start.x;
  const dy = end.y - start.y;
  const len = Math.hypot(dx, dy) || 1;
  const nx = -dy / len;
  const ny = dx / len;
  return {
    x: (start.x + end.x) / 2 + nx * bend,
    y: (start.y + end.y) / 2 + ny * bend,
  };
}

function quadraticPoint(start, control, end, t) {
  const u = 1 - t;
  return {
    x: u * u * start.x + 2 * u * t * control.x + t * t * end.x,
    y: u * u * start.y + 2 * u * t * control.y + t * t * end.y,
  };
}

function edgeBend(edge, start, end) {
  const curve = Number(edge?.options?.curve);
  if (Number.isFinite(curve) && curve !== 0) return curve * 36;
  const offset = Number(edge?.options?.offset);
  if (Number.isFinite(offset) && offset !== 0) return offset * 24;
  const dx = end.x - start.x;
  const dy = end.y - start.y;
  if (Math.abs(dy) < 0.01) return 16 * (dx >= 0 ? 1 : -1);
  if (Math.abs(dx) < 0.01) return 16 * (dy >= 0 ? 1 : -1);
  return 14 * (dx * dy >= 0 ? 1 : -1);
}

function edgeLayout(start, end, bend, startPad = NODE_RADIUS, endPad = NODE_RADIUS) {
  const trimmed = trimSegment(start, end, startPad, endPad);
  const control = quadraticControl(trimmed.start, trimmed.end, bend);
  const label = quadraticPoint(trimmed.start, control, trimmed.end, 0.5);
  return {
    start: trimmed.start,
    end: trimmed.end,
    control,
    label,
    path: `M ${trimmed.start.x} ${trimmed.start.y} Q ${control.x} ${control.y} ${trimmed.end.x} ${trimmed.end.y}`,
  };
}

function loopLayout(source) {
  const path = `M ${source.x} ${source.y - 18} C ${source.x + 40} ${source.y - 90}, ${source.x - 40} ${source.y - 90}, ${source.x} ${source.y - 18}`;
  return {
    path,
    label: { x: source.x, y: source.y - 96 },
    anchor: { x: source.x, y: source.y - 96 },
  };
}

function applySelection(ids, additive, origin = "canvas.select") {
  const current = uniq(Array.isArray(app.stateObject.selection) ? app.stateObject.selection : []);
  let next;
  if (additive) {
    const set = new Set(current);
    for (const id of ids) {
      if (set.has(id)) set.delete(id);
      else set.add(id);
    }
    next = [...set].sort((a, b) => a - b);
  } else {
    next = uniq(ids).sort((a, b) => a - b);
  }
  dispatch({ type: "selection.set", input: { selected_ids: next } }, origin);
}

function setSelection(ids, origin = "canvas.select") {
  dispatch({ type: "selection.set", input: { selected_ids: uniq(ids).sort((a, b) => a - b) } }, origin);
}

function selectedIds() {
  return uniq(Array.isArray(app.stateObject.selection) ? app.stateObject.selection : []).sort((a, b) => a - b);
}

function selectedVertexIds() {
  const vertices = new Set((Array.isArray(app.snapshotObject.vertices) ? app.snapshotObject.vertices : []).map((v) => v.id));
  return selectedIds().filter((id) => vertices.has(id));
}

function allCellIds() {
  return uniq((Array.isArray(app.cellsObject) ? app.cellsObject : []).map((c) => c?.id)).sort((a, b) => a - b);
}

function suggestedPasteOrigin() {
  const vertexById = new Map((Array.isArray(app.snapshotObject.vertices) ? app.snapshotObject.vertices : []).map((v) => [v.id, v]));
  const selectedVertices = selectedVertexIds().map((id) => vertexById.get(id)).filter(Boolean);
  if (selectedVertices.length > 0) {
    let minX = selectedVertices[0].x;
    let minY = selectedVertices[0].y;
    for (const v of selectedVertices) {
      minX = Math.min(minX, v.x);
      minY = Math.min(minY, v.y);
    }
    return { x: minX + 1, y: minY + 1 };
  }
  const allVertices = Array.isArray(app.snapshotObject.vertices) ? app.snapshotObject.vertices : [];
  if (allVertices.length > 0) {
    return {
      x: Math.round(allVertices.reduce((acc, v) => acc + v.x, 0) / allVertices.length),
      y: Math.round(allVertices.reduce((acc, v) => acc + v.y, 0) / allVertices.length),
    };
  }
  return { x: 0, y: 0 };
}

function writeSystemClipboard(text) {
  if (typeof navigator === "undefined" || !navigator.clipboard || !navigator.clipboard.writeText) {
    return Promise.resolve(false);
  }
  return navigator.clipboard.writeText(text).then(() => true).catch(() => false);
}

function readSystemClipboard() {
  if (typeof navigator === "undefined" || !navigator.clipboard || !navigator.clipboard.readText) {
    return Promise.resolve("");
  }
  return navigator.clipboard.readText().then((v) => String(v ?? "")).catch(() => "");
}

async function copySelectionToClipboard(origin = "keyboard.copy") {
  if (!app.session) return false;
  if (selectedIds().length === 0) {
    status("Copy skipped: selection is empty.", false);
    return false;
  }
  const includeDependencies = refs.includeDeps.checked;
  const res = dispatch(
    { type: "selection.export", input: { include_dependencies: includeDependencies } },
    origin,
  );
  const payloadText = typeof res?.result?.payload === "string" ? res.result.payload : "";
  if (payloadText === "") {
    status("Copy failed: empty payload.", true);
    return false;
  }
  app.clipboardPayload = payloadText;
  refs.selectionPayload.value = payloadText;
  const systemOk = await writeSystemClipboard(payloadText);
  status(
    systemOk ? "Selection copied to system clipboard." : "Selection copied to local clipboard buffer.",
    false,
  );
  return true;
}

async function cutSelectionToClipboard(origin = "keyboard.cut") {
  const copied = await copySelectionToClipboard(origin);
  if (!copied) return false;
  const del = dispatch({ type: "selection.delete", input: {} }, origin);
  return Boolean(del?.ok);
}

async function pasteClipboardSelection(origin = "keyboard.paste") {
  if (!app.session) return false;
  let payloadText = await readSystemClipboard();
  if (payloadText === "") payloadText = app.clipboardPayload;
  if (payloadText === "") {
    status("Paste skipped: clipboard is empty.", false);
    return false;
  }
  const originPoint = suggestedPasteOrigin();
  refs.pasteX.value = String(originPoint.x);
  refs.pasteY.value = String(originPoint.y);
  const res = dispatch({
    type: "selection.paste",
    input: { payload: payloadText, origin_x: originPoint.x, origin_y: originPoint.y },
  }, origin);
  if (!res.ok) {
    status("Paste failed: payload was not recognized.", true);
    return false;
  }
  app.clipboardPayload = payloadText;
  refs.selectionPayload.value = payloadText;
  return true;
}

function closeLabelEditor() {
  app.labelEdit.cellId = null;
  refs.labelEditor.classList.add("hidden");
}

function placeLabelEditor(x, y) {
  const stageW = app.canvasBounds?.width ?? refs.canvasStage.clientWidth;
  const stageH = app.canvasBounds?.height ?? refs.canvasStage.clientHeight;
  const editorW = Math.max(180, refs.labelEditor.offsetWidth || 220);
  const editorH = Math.max(68, refs.labelEditor.offsetHeight || 72);
  const left = Math.max(8, Math.min(stageW - editorW - 8, x + 10));
  const top = Math.max(8, Math.min(stageH - editorH - 8, y + 10));
  refs.labelEditor.style.left = `${left}px`;
  refs.labelEditor.style.top = `${top}px`;
}

function openLabelEditor(cellId, label, anchor) {
  if (!app.session) return;
  app.labelEdit.cellId = cellId;
  app.labelEdit.x = anchor.x;
  app.labelEdit.y = anchor.y;
  refs.labelEditor.classList.remove("hidden");
  refs.labelEditorInput.value = typeof label === "string" ? label : "";
  placeLabelEditor(anchor.x, anchor.y);
  requestAnimationFrame(() => {
    refs.labelEditorInput.focus();
    refs.labelEditorInput.select();
  });
}

function commitLabelEditor() {
  if (app.labelEdit.cellId == null) return;
  const cellId = app.labelEdit.cellId;
  const label = refs.labelEditorInput.value;
  closeLabelEditor();
  dispatch({ type: "cell.set_label", input: { cell_id: cellId, label } }, "gesture.label-edit");
}

function showSelectionRect() {
  if (
    app.interaction.mode !== "box" ||
    !app.interaction.moved ||
    !app.interaction.startPoint ||
    !app.interaction.point
  ) {
    refs.selectionRect.classList.add("hidden");
    return;
  }
  const rect = rectFromPoints(app.interaction.startPoint, app.interaction.point);
  refs.selectionRect.classList.remove("hidden");
  refs.selectionRect.style.left = `${rect.left}px`;
  refs.selectionRect.style.top = `${rect.top}px`;
  refs.selectionRect.style.width = `${Math.max(1, rect.right - rect.left)}px`;
  refs.selectionRect.style.height = `${Math.max(1, rect.bottom - rect.top)}px`;
}

function edgeInteractiveTarget(target) {
  return target instanceof Element && target.closest(".edge-hit, .edge-label, .graph-node, .label-editor");
}

function clearGesture() {
  app.interaction.mode = "idle";
  app.interaction.pointerId = null;
  app.interaction.sourceId = null;
  app.interaction.point = null;
  app.interaction.hoverId = null;
  app.interaction.startPoint = null;
  app.interaction.moved = false;
  app.interaction.dragIds = [];
  app.interaction.dragDelta = { x: 0, y: 0 };
  app.interaction.boxAdditive = false;
}

function render() {
  refs.renderKind.textContent = app.lastRenderKind;
  refs.renderOutput.value = app.lastRenderOutput;
  refs.stateJson.textContent = fj(app.stateRaw);
  refs.snapshotJson.textContent = fj(app.snapshotRaw);
  refs.cellsJson.textContent = fj(app.cellsRaw);
  refs.lastCommand.textContent = fj(app.lastCommand);
  refs.lastResult.textContent = fj(app.lastResult);
  refs.queryResult.textContent = fj(app.queryOutput);
  refs.importResult.textContent = fj(app.importOutput);
  refs.selectionResult.textContent = fj(app.selectionOutput);

  const vs = Array.isArray(app.snapshotObject.vertices) ? app.snapshotObject.vertices : [];
  const es = Array.isArray(app.snapshotObject.edges) ? app.snapshotObject.edges : [];
  const sel = uniq(Array.isArray(app.stateObject.selection) ? app.stateObject.selection : []);
  refs.summary.textContent =
    `commands=${app.operationCount}, vertices=${vs.length}, edges=${es.length}, selection=[${sel.join(", ")}], ` +
    `undo=${Math.max(0, app.undoStack.length - 1)}, redo=${app.redoStack.length}, mode=${app.interaction.mode}`;

  refs.commandHistory.innerHTML = "";
  for (const h of app.commandHistory) {
    const li = document.createElement("li");
    li.className = h.ok ? "" : "fail";
    li.textContent = `#${h.id} ${h.type} | ${h.ok ? "ok" : "fail"} | ${h.elapsed_ms}ms${h.note ? ` | ${h.note}` : ""}`;
    refs.commandHistory.appendChild(li);
  }

  const b = bounds(vs);
  app.canvasBounds = b;
  refs.canvasMeta.textContent = `vertices=${vs.length}, edges=${es.length}, size=${Math.round(b.width)}x${Math.round(b.height)}`;
  refs.graphSvg.setAttribute("viewBox", `0 0 ${b.width} ${b.height}`);
  refs.graphSvg.setAttribute("width", String(b.width));
  refs.graphSvg.setAttribute("height", String(b.height));
  refs.graphNodes.style.width = `${b.width}px`;
  refs.graphNodes.style.height = `${b.height}px`;
  refs.graphSvg.innerHTML = "";
  refs.graphNodes.innerHTML = "";

  const defs = document.createElementNS(SVG_NS, "defs");
  const marker = document.createElementNS(SVG_NS, "marker");
  marker.setAttribute("id", "edge-arrow");
  marker.setAttribute("viewBox", "0 0 10 10");
  marker.setAttribute("refX", "8");
  marker.setAttribute("refY", "5");
  marker.setAttribute("markerWidth", "7");
  marker.setAttribute("markerHeight", "7");
  marker.setAttribute("orient", "auto-start-reverse");
  const arrow = document.createElementNS(SVG_NS, "path");
  arrow.setAttribute("d", "M 0 0 L 10 5 L 0 10 z");
  arrow.setAttribute("fill", "#3d4d59");
  marker.appendChild(arrow);
  defs.appendChild(marker);
  refs.graphSvg.appendChild(defs);

  const dragDelta = app.interaction.mode === "drag" ? app.interaction.dragDelta : { x: 0, y: 0 };
  const dragSet = new Set(app.interaction.mode === "drag" ? app.interaction.dragIds : []);
  const points = new Map();
  const vertexById = new Map();
  for (const v of vs) {
    vertexById.set(v.id, v);
    let p = stagePoint(v, b);
    if (dragSet.has(v.id)) {
      p = { x: p.x + dragDelta.x * GRID, y: p.y + dragDelta.y * GRID };
    }
    points.set(v.id, p);

    const node = document.createElement("div");
    node.className = "graph-node";
    if (sel.includes(v.id)) node.classList.add("selected");
    if (app.interaction.mode === "connect" && app.interaction.sourceId === v.id) node.classList.add("connect-source");
    if (app.interaction.mode === "connect" && app.interaction.hoverId === v.id) node.classList.add("connect-target");
    node.style.left = `${p.x}px`;
    node.style.top = `${p.y}px`;
    node.tabIndex = 0;
    node.setAttribute("role", "button");
    node.setAttribute("aria-label", `Select vertex ${v.id}`);

    const id = document.createElement("span");
    id.className = "id";
    id.textContent = `#${v.id}`;
    const label = document.createElement("span");
    label.textContent = v.label === "" ? "(empty)" : v.label;
    node.appendChild(id);
    node.appendChild(label);

    node.addEventListener("click", (e) => {
      if (performance.now() < app.interaction.suppressClickUntil) return;
      applySelection([v.id], e.ctrlKey || e.metaKey, "canvas.vertex-select");
    });

    node.addEventListener("dblclick", (e) => {
      e.preventDefault();
      e.stopPropagation();
      openLabelEditor(v.id, v.label, points.get(v.id) ?? stagePoint(v, b));
    });

    node.addEventListener("pointerdown", (e) => {
      if (e.button !== 0) return;
      if (!app.session) return;
      e.preventDefault();
      app.interaction.mode = e.shiftKey ? "connect" : "drag";
      app.interaction.pointerId = e.pointerId;
      app.interaction.sourceId = v.id;
      const start = pointerStage(e);
      app.interaction.point = start;
      app.interaction.startPoint = start;
      app.interaction.moved = false;
      app.interaction.hoverId = null;
      app.interaction.boxAdditive = false;
      app.interaction.dragDelta = { x: 0, y: 0 };
      if (app.interaction.mode === "drag") {
        const selectedVertices = uniq(Array.isArray(app.stateObject.selection) ? app.stateObject.selection : [])
          .filter((id) => vertexById.has(id));
        if (!e.ctrlKey && !e.metaKey && selectedVertices.includes(v.id) && selectedVertices.length > 1) {
          app.interaction.dragIds = selectedVertices;
        } else {
          app.interaction.dragIds = [v.id];
        }
      } else {
        app.interaction.dragIds = [];
      }
      render();
    });

    refs.graphNodes.appendChild(node);
  }
  app.canvasPoints = points;
  app.canvasVertexById = vertexById;

  const edgeById = new Map();
  for (const e of es) {
    const s = points.get(e.source_id);
    const t = points.get(e.target_id);
    if (!s || !t) continue;
    const isSelected = sel.includes(e.id);
    if (e.source_id === e.target_id) {
      const layout = loopLayout(s);
      edgeById.set(e.id, { id: e.id, label: e.label ?? "", anchor: layout.anchor });

      const loop = document.createElementNS(SVG_NS, "path");
      loop.setAttribute("d", layout.path);
      loop.setAttribute("class", isSelected ? "edge-loop edge-selected" : "edge-loop");
      loop.setAttribute("marker-end", "url(#edge-arrow)");
      refs.graphSvg.appendChild(loop);

      const hit = document.createElementNS(SVG_NS, "path");
      hit.setAttribute("d", layout.path);
      hit.setAttribute("class", isSelected ? "edge-hit edge-selected" : "edge-hit");
      hit.tabIndex = 0;
      hit.setAttribute("role", "button");
      hit.setAttribute("aria-label", `Select edge ${e.id}`);
      hit.addEventListener("click", (evt) => {
        evt.preventDefault();
        evt.stopPropagation();
        if (performance.now() < app.interaction.suppressClickUntil) return;
        applySelection([e.id], evt.ctrlKey || evt.metaKey, "canvas.edge-select");
      });
      hit.addEventListener("dblclick", (evt) => {
        evt.preventDefault();
        evt.stopPropagation();
        openLabelEditor(e.id, e.label ?? "", layout.anchor);
      });
      refs.graphSvg.appendChild(hit);

      if (e.label) {
        const text = document.createElementNS(SVG_NS, "text");
        text.setAttribute("x", String(layout.label.x));
        text.setAttribute("y", String(layout.label.y));
        text.setAttribute("class", isSelected ? "edge-label edge-selected" : "edge-label");
        text.textContent = e.label;
        text.addEventListener("dblclick", (evt) => {
          evt.preventDefault();
          evt.stopPropagation();
          openLabelEditor(e.id, e.label ?? "", layout.anchor);
        });
        refs.graphSvg.appendChild(text);
      }
    } else {
      const bend = edgeBend(e, s, t);
      const layout = edgeLayout(s, t, bend);
      edgeById.set(e.id, { id: e.id, label: e.label ?? "", anchor: layout.label });

      const path = document.createElementNS(SVG_NS, "path");
      path.setAttribute("d", layout.path);
      path.setAttribute("class", isSelected ? "edge-line edge-selected" : "edge-line");
      path.setAttribute("marker-end", "url(#edge-arrow)");
      refs.graphSvg.appendChild(path);

      const hit = document.createElementNS(SVG_NS, "path");
      hit.setAttribute("d", layout.path);
      hit.setAttribute("class", isSelected ? "edge-hit edge-selected" : "edge-hit");
      hit.tabIndex = 0;
      hit.setAttribute("role", "button");
      hit.setAttribute("aria-label", `Select edge ${e.id}`);
      hit.addEventListener("click", (evt) => {
        evt.preventDefault();
        evt.stopPropagation();
        if (performance.now() < app.interaction.suppressClickUntil) return;
        applySelection([e.id], evt.ctrlKey || evt.metaKey, "canvas.edge-select");
      });
      hit.addEventListener("dblclick", (evt) => {
        evt.preventDefault();
        evt.stopPropagation();
        openLabelEditor(e.id, e.label ?? "", layout.label);
      });
      refs.graphSvg.appendChild(hit);

      if (e.label) {
        const text = document.createElementNS(SVG_NS, "text");
        text.setAttribute("x", String(layout.label.x));
        text.setAttribute("y", String(layout.label.y - 4));
        text.setAttribute("class", isSelected ? "edge-label edge-selected" : "edge-label");
        text.textContent = e.label;
        text.addEventListener("dblclick", (evt) => {
          evt.preventDefault();
          evt.stopPropagation();
          openLabelEditor(e.id, e.label ?? "", layout.label);
        });
        refs.graphSvg.appendChild(text);
      }
    }
  }
  app.canvasEdgeById = edgeById;

  if (app.interaction.mode === "connect" && app.interaction.sourceId != null && app.interaction.point) {
    const s = points.get(app.interaction.sourceId);
    const t = app.interaction.hoverId != null ? points.get(app.interaction.hoverId) : app.interaction.point;
    if (s && t) {
      const layout = app.interaction.hoverId != null
        ? edgeLayout(s, t, edgeBend({ options: {} }, s, t), NODE_RADIUS + 4, NODE_RADIUS + 4)
        : edgeLayout(s, t, edgeBend({ options: {} }, s, t), NODE_RADIUS + 4, 8);
      const pre = document.createElementNS(SVG_NS, "path");
      pre.setAttribute("d", layout.path);
      pre.setAttribute("class", "edge-preview");
      pre.setAttribute("marker-end", "url(#edge-arrow)");
      refs.graphSvg.appendChild(pre);
    }
  }

  if (app.labelEdit.cellId != null) {
    const vertexPoint = points.get(app.labelEdit.cellId);
    const edgeInfo = edgeById.get(app.labelEdit.cellId);
    const anchor = vertexPoint ?? edgeInfo?.anchor;
    if (anchor) {
      app.labelEdit.x = anchor.x;
      app.labelEdit.y = anchor.y;
      placeLabelEditor(anchor.x, anchor.y);
    } else {
      closeLabelEditor();
    }
  }
  showSelectionRect();
}

function bind() {
  refs.btnNewSession.addEventListener("click", () => dispatch({ type: "session.new", input: {} }, "topbar"));
  refs.btnUndo.addEventListener("click", () => dispatch({ type: "session.undo", input: {} }, "topbar"));
  refs.btnRedo.addEventListener("click", () => dispatch({ type: "session.redo", input: {} }, "topbar"));
  refs.btnCopySelection.addEventListener("click", () => {
    void copySelectionToClipboard("topbar.copy");
  });
  refs.btnCutSelection.addEventListener("click", () => {
    void cutSelectionToClipboard("topbar.cut");
  });
  refs.btnPasteSelectionTop.addEventListener("click", () => {
    void pasteClipboardSelection("topbar.paste");
  });
  refs.btnDeleteSelection.addEventListener("click", () => dispatch({ type: "selection.delete", input: {} }, "topbar"));
  refs.btnSeed.addEventListener("click", () => dispatch({ type: "graph.seed_ab", input: {} }, "topbar"));
  refs.btnRenderTikz.addEventListener("click", () => dispatch({ type: "render.tikz", input: {} }, "topbar"));
  refs.btnRenderFletcher.addEventListener("click", () => dispatch({ type: "render.fletcher", input: {} }, "topbar"));
  refs.btnRenderHtml.addEventListener("click", () => dispatch({ type: "render.html_embed", input: {} }, "topbar"));

  refs.formAddVertex.addEventListener("submit", (e) => {
    e.preventDefault();
    dispatch({
      type: "graph.add_vertex",
      input: { label: refs.vertexLabel.value, x: toInt(refs.vertexX.value, 0), y: toInt(refs.vertexY.value, 0) },
    }, "controls");
  });

  refs.formAddEdge.addEventListener("submit", (e) => {
    e.preventDefault();
    dispatch({
      type: "graph.add_edge",
      input: {
        source_id: toInt(refs.edgeSource.value, -1),
        target_id: toInt(refs.edgeTarget.value, -1),
        label: refs.edgeLabel.value,
      },
    }, "controls");
  });

  refs.formRemove.addEventListener("submit", (e) => {
    e.preventDefault();
    dispatch({
      type: "graph.remove",
      input: { cell_id: toInt(refs.removeId.value, -1), when: 0 },
    }, "controls");
  });

  refs.btnSetSelection.addEventListener("click", () => {
    dispatch({ type: "selection.set", input: { selected_ids: parseIds(refs.selectionInput.value) } }, "controls");
  });
  refs.btnExportSelection.addEventListener("click", () => {
    dispatch({ type: "selection.export", input: { include_dependencies: refs.includeDeps.checked } }, "controls");
  });
  refs.btnPasteSelection.addEventListener("click", () => {
    dispatch({
      type: "selection.paste",
      input: {
        payload: refs.selectionPayload.value,
        origin_x: toInt(refs.pasteX.value, 0),
        origin_y: toInt(refs.pasteY.value, 0),
      },
    }, "controls");
  });

  refs.btnImportPayload.addEventListener("click", () => {
    dispatch({ type: "import.payload", input: { payload: refs.payloadInput.value.trim() } }, "controls");
  });
  refs.btnImportAuto.addEventListener("click", () => {
    const renderer = refs.importRenderer.value.trim();
    dispatch({
      type: "import.text_auto",
      input: { text: refs.importText.value, default_renderer: renderer === "" ? undefined : renderer },
    }, "controls");
  });

  refs.btnDeps.addEventListener("click", () => {
    dispatch({ type: "query.dependencies_of", input: { cell_id: toInt(refs.queryCellId.value, -1) } }, "controls");
  });
  refs.btnRevDeps.addEventListener("click", () => {
    dispatch({ type: "query.reverse_dependencies_of", input: { cell_id: toInt(refs.queryCellId.value, -1) } }, "controls");
  });
  refs.btnTransitive.addEventListener("click", () => {
    dispatch({
      type: "query.transitive_dependencies",
      input: { roots: parseIds(refs.queryRoots.value), exclude_roots: refs.queryExcludeRoots.checked },
    }, "controls");
  });
  refs.btnComponents.addEventListener("click", () => {
    dispatch({ type: "query.connected_components", input: { roots: parseIds(refs.queryRoots.value) } }, "controls");
  });

  refs.btnDispatchJson.addEventListener("click", () => {
    const raw = refs.commandJson.value.trim();
    if (raw === "") return status("Command JSON is empty.", true);
    const parsed = pj(raw);
    if (!parsed || typeof parsed !== "object") return status("Command JSON is invalid.", true);
    const type = typeof parsed.type === "string" ? parsed.type : "";
    const action = typeof parsed.action === "string" ? parsed.action : "";
    const isKnownUiType = type !== "" && Object.prototype.hasOwnProperty.call(HANDLERS, type);
    if (isKnownUiType) {
      dispatch(parsed, "inspector-json");
      return;
    }
    if (action !== "" || type !== "") {
      dispatch({ type: "runtime.dispatch", input: parsed }, "inspector-json");
      return;
    }
    status("Command JSON needs a known UI `type` or runtime `action`.", true);
  });

  refs.btnClearHistory.addEventListener("click", () => {
    app.commandHistory = [];
    app.lastCommand = null;
    app.lastResult = null;
    render();
  });

  refs.btnLabelSave.addEventListener("click", () => commitLabelEditor());
  refs.btnLabelCancel.addEventListener("click", () => {
    closeLabelEditor();
    render();
  });
  refs.labelEditorInput.addEventListener("keydown", (e) => {
    if (e.key === "Enter") {
      e.preventDefault();
      commitLabelEditor();
      return;
    }
    if (e.key === "Escape") {
      e.preventDefault();
      closeLabelEditor();
      render();
    }
  });

  refs.canvasStage.addEventListener("pointerdown", (e) => {
    if (e.button !== 0) return;
    if (!app.session) return;
    if (edgeInteractiveTarget(e.target)) return;
    if (app.labelEdit.cellId != null) closeLabelEditor();
    const start = pointerStage(e);
    app.interaction.mode = "box";
    app.interaction.pointerId = e.pointerId;
    app.interaction.sourceId = null;
    app.interaction.point = start;
    app.interaction.startPoint = start;
    app.interaction.moved = false;
    app.interaction.hoverId = null;
    app.interaction.dragIds = [];
    app.interaction.dragDelta = { x: 0, y: 0 };
    app.interaction.boxAdditive = e.ctrlKey || e.metaKey;
    render();
  });

  refs.canvasStage.addEventListener("click", (e) => {
    if (performance.now() < app.interaction.suppressClickUntil) return;
    if (edgeInteractiveTarget(e.target)) return;
    if (!app.session) return;
    const p = pointerStage(e);
    const g = stageToGrid(p);
    refs.vertexX.value = String(g.x);
    refs.vertexY.value = String(g.y);
    dispatch({ type: "graph.add_vertex", input: { label: refs.vertexLabel.value, x: g.x, y: g.y } }, "gesture.canvas-click");
  });

  window.addEventListener("pointermove", (e) => {
    if (app.interaction.mode === "idle" || e.pointerId !== app.interaction.pointerId) return;
    const p = pointerStage(e);
    app.interaction.point = p;
    if (app.interaction.mode === "connect") {
      app.interaction.hoverId = nearestVertex(p, 36, app.interaction.sourceId);
      if (app.interaction.startPoint && pointerDistanceSq(p, app.interaction.startPoint) > DRAG_THRESHOLD * DRAG_THRESHOLD) {
        app.interaction.moved = true;
      }
    } else if (app.interaction.mode === "drag") {
      if (app.interaction.startPoint) {
        app.interaction.dragDelta = {
          x: Math.round((p.x - app.interaction.startPoint.x) / GRID),
          y: Math.round((p.y - app.interaction.startPoint.y) / GRID),
        };
        if (app.interaction.dragDelta.x !== 0 || app.interaction.dragDelta.y !== 0) app.interaction.moved = true;
      }
    } else if (app.interaction.mode === "box") {
      if (
        app.interaction.startPoint &&
        (Math.abs(p.x - app.interaction.startPoint.x) > BOX_THRESHOLD ||
          Math.abs(p.y - app.interaction.startPoint.y) > BOX_THRESHOLD)
      ) {
        app.interaction.moved = true;
      }
    }
    render();
  });

  const onPointerEnd = (e) => {
    if (app.interaction.mode === "idle" || e.pointerId !== app.interaction.pointerId) return;
    const mode = app.interaction.mode;
    const sourceId = app.interaction.sourceId;
    const point = pointerStage(e);
    const moved = app.interaction.moved;
    const dragIds = [...app.interaction.dragIds];
    const dragDelta = { ...app.interaction.dragDelta };
    const startPoint = app.interaction.startPoint;
    const boxAdditive = app.interaction.boxAdditive;

    let acted = false;
    if (mode === "drag" && sourceId != null && moved && (dragDelta.x !== 0 || dragDelta.y !== 0)) {
      const ids = dragIds.length > 0 ? dragIds : [sourceId];
      const moves = [];
      for (const id of ids) {
        const vertex = app.canvasVertexById.get(id);
        if (!vertex) continue;
        moves.push({ vertex_id: id, x: vertex.x + dragDelta.x, y: vertex.y + dragDelta.y });
      }
      if (moves.length === 1) {
        dispatch({ type: "graph.move_vertex", input: moves[0] }, "gesture.drag");
      } else if (moves.length > 1) {
        dispatch({ type: "graph.move_vertices", input: { moves } }, "gesture.drag-group");
      }
      acted = moves.length > 0;
    } else if (mode === "connect" && sourceId != null) {
      const targetId = nearestVertex(point, 36, sourceId);
      if (moved && targetId != null) {
        dispatch({
          type: "graph.add_edge",
          input: { source_id: sourceId, target_id: targetId, label: refs.edgeLabel.value },
        }, "gesture.connect");
        acted = true;
      } else if (moved) {
        status("Connect cancelled: release on another vertex.", false);
      }
    } else if (mode === "box" && moved && startPoint) {
      const rect = rectFromPoints(startPoint, point);
      const selected = [];
      for (const [id, p] of app.canvasPoints.entries()) {
        if (rectContainsPoint(rect, p)) selected.push(id);
      }
      if (boxAdditive) {
        const current = uniq(Array.isArray(app.stateObject.selection) ? app.stateObject.selection : []);
        setSelection([...new Set([...current, ...selected])], "gesture.box-select");
      } else {
        setSelection(selected, "gesture.box-select");
      }
      acted = true;
    }

    clearGesture();
    if (acted) {
      app.interaction.suppressClickUntil = performance.now() + CLICK_SUPPRESS_MS;
    } else {
      render();
    }
  };
  window.addEventListener("pointerup", onPointerEnd);
  window.addEventListener("pointercancel", onPointerEnd);

  document.addEventListener("keydown", (e) => {
    const mod = e.ctrlKey || e.metaKey;
    const key = e.key.toLowerCase();
    if (mod && !e.altKey && !editable(e.target)) {
      if (key === "z") {
        e.preventDefault();
        dispatch({ type: e.shiftKey ? "session.redo" : "session.undo", input: {} }, "keyboard");
        return;
      }
      if (key === "y") {
        e.preventDefault();
        dispatch({ type: "session.redo", input: {} }, "keyboard");
        return;
      }
      if (key === "a") {
        e.preventDefault();
        setSelection(allCellIds(), "keyboard.select-all");
        return;
      }
      if (key === "c") {
        e.preventDefault();
        void copySelectionToClipboard("keyboard.copy");
        return;
      }
      if (key === "x") {
        e.preventDefault();
        void cutSelectionToClipboard("keyboard.cut");
        return;
      }
      if (key === "v") {
        e.preventDefault();
        void pasteClipboardSelection("keyboard.paste");
        return;
      }
    }
    if (editable(e.target)) return;
    if ((e.key === "Delete" || e.key === "Backspace") && !mod && !e.altKey) {
      const selected = uniq(Array.isArray(app.stateObject.selection) ? app.stateObject.selection : []);
      if (selected.length > 0) {
        e.preventDefault();
        dispatch({ type: "selection.delete", input: {} }, "keyboard");
      }
      return;
    }
    if (e.key === "Escape") {
      if (app.labelEdit.cellId != null) {
        e.preventDefault();
        closeLabelEditor();
        render();
        return;
      }
      if (app.interaction.mode !== "idle") {
        e.preventDefault();
        clearGesture();
        status("Gesture cancelled.", false);
        render();
      }
    }
  });
}

async function boot() {
  bind();
  status("Loading MoonBit module...");
  render();
  let lastError = null;
  for (const candidate of MODULE_CANDIDATES) {
    try {
      app.api = await import(candidate);
      status(`Module loaded: ${candidate}`);
      dispatch({ type: "session.new", input: {} }, "boot");
      return;
    } catch (e) {
      lastError = e;
    }
  }
  status("Cannot load MoonBit build output. Run `moon build` in kwiver/, then refresh.", true);
  app.lastResult = { ok: false, error: String(lastError) };
  render();
}

boot();
