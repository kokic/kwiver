const MODULE_CANDIDATE_PATHS = [
  "../_build/js/release/build/browser_demo/browser_demo.js",
  "../_build/js/debug/build/browser_demo/browser_demo.js",
  "./_build/js/release/build/browser_demo/browser_demo.js",
  "./_build/js/debug/build/browser_demo/browser_demo.js",
];

function addModuleCandidate(target, candidate) {
  if (typeof candidate === "string" && candidate !== "") {
    target.add(candidate);
  }
}

function moduleCandidates() {
  const candidates = new Set();

  for (const relative of MODULE_CANDIDATE_PATHS) {
    try {
      addModuleCandidate(candidates, new URL(relative, import.meta.url).href);
    } catch (_e) {
      // Ignore invalid relative candidate.
    }
  }

  if (typeof window !== "undefined" && window.location) {
    const location = window.location;
    const origin = typeof location.origin === "string" ? location.origin : "";
    const pathname = typeof location.pathname === "string" ? location.pathname : "";

    if (origin !== "" && origin !== "null") {
      const rootSuffixes = [
        "/_build/js/release/build/browser_demo/browser_demo.js",
        "/_build/js/debug/build/browser_demo/browser_demo.js",
      ];
      for (const suffix of rootSuffixes) {
        addModuleCandidate(candidates, origin + suffix);
      }

      const marker = "/browser_ui_upstream/";
      const markerIndex = pathname.indexOf(marker);
      if (markerIndex >= 0) {
        const prefix = pathname.slice(0, markerIndex);
        for (const suffix of rootSuffixes) {
          addModuleCandidate(candidates, origin + prefix + suffix);
        }
      }
    }
  }

  return Array.from(candidates);
}

const DEFAULT_COMMAND_PROTOCOL = "kwiver.command.v1";

const BRIDGE = {
  api: null,
  session: null,
  loading: null,
  commandProtocol: DEFAULT_COMMAND_PROTOCOL,
  loadedCandidate: null,
  loadErrors: [],
};

const BRIDGE_TEST = {
  disableAutoload: false,
};

let commandNonce = 0;
let bridgeLoadGeneration = 0;

function nextCommandId(origin = "ui.bridge") {
  commandNonce += 1;
  return `${origin}-${commandNonce}`;
}

function commandProtocolFromApi(api) {
  if (!api || typeof api.ffi_browser_demo_command_protocol !== "function") {
    return null;
  }
  try {
    const protocol = api.ffi_browser_demo_command_protocol();
    return typeof protocol === "string" && protocol !== "" ? protocol : null;
  } catch (_e) {
    return null;
  }
}

function bridgeCommandProtocol() {
  return typeof BRIDGE.commandProtocol === "string" && BRIDGE.commandProtocol !== ""
    ? BRIDGE.commandProtocol
    : DEFAULT_COMMAND_PROTOCOL;
}

function normalizeCommand(command) {
  const normalized = command && typeof command === "object" ? { ...command } : {};
  const origin = typeof normalized.origin === "string" && normalized.origin !== ""
    ? normalized.origin
    : "ui.bridge";
  normalized.origin = origin;
  normalized.protocol = bridgeCommandProtocol();
  if (typeof normalized.command_id !== "string" || normalized.command_id === "") {
    normalized.command_id = nextCommandId(origin);
  }
  return normalized;
}

async function loadBridgeApi() {
  const candidates = moduleCandidates();
  const loadErrors = [];

  for (const candidate of candidates) {
    try {
      const mod = await import(candidate);
      const hasSession = mod && typeof mod.ffi_browser_demo_session_new === "function";
      const hasProtocol = mod && typeof mod.ffi_browser_demo_command_protocol === "function";
      if (hasSession && hasProtocol) {
        return { api: mod, candidate, loadErrors };
      }

      const missing = [];
      if (!hasSession) {
        missing.push("ffi_browser_demo_session_new");
      }
      if (!hasProtocol) {
        missing.push("ffi_browser_demo_command_protocol");
      }
      loadErrors.push(candidate + " (missing " + missing.join(", ") + ")");
    } catch (e) {
      loadErrors.push(candidate + ": " + String(e));
    }
  }

  return { api: null, candidate: null, loadErrors };
}

function ensureBridgeLoading() {
  if (BRIDGE_TEST.disableAutoload) {
    bridgeLoadGeneration += 1;
    BRIDGE.loading = null;
    return;
  }
  if (BRIDGE.api !== null || BRIDGE.loading !== null) {
    return;
  }
  const generation = bridgeLoadGeneration;
  BRIDGE.loading = loadBridgeApi()
    .then((loaded) => {
      if (generation !== bridgeLoadGeneration) {
        return;
      }
      const api = loaded && loaded.api ? loaded.api : null;
      BRIDGE.loadedCandidate = loaded && typeof loaded.candidate === "string"
        ? loaded.candidate
        : null;
      BRIDGE.loadErrors = loaded && Array.isArray(loaded.loadErrors)
        ? loaded.loadErrors
        : [];
      if (api && typeof api.ffi_browser_demo_session_new === "function") {
        const protocol = commandProtocolFromApi(api);
        if (typeof protocol === "string" && protocol !== "") {
          BRIDGE.api = api;
          BRIDGE.session = api.ffi_browser_demo_session_new();
          BRIDGE.commandProtocol = protocol;
        } else {
          const candidate = BRIDGE.loadedCandidate ?? "unknown";
          BRIDGE.loadErrors.push(candidate + " (invalid ffi_browser_demo_command_protocol)");
        }
      }
    })
    .catch(() => {
      // Bridge remains unavailable when loading fails.
    })
    .finally(() => {
      if (generation === bridgeLoadGeneration) {
        BRIDGE.loading = null;
      }
    });
}

function bridgeAvailable() {
  ensureBridgeLoading();
  return BRIDGE.api !== null && BRIDGE.session !== null;
}

// Preload MoonBit bridge in the background without blocking module initialisation.
ensureBridgeLoading();

function bridgeReadyPromise(timeoutMs = 2000) {
  ensureBridgeLoading();
  if (BRIDGE.loading === null) {
    return Promise.resolve();
  }
  const timeout = Number.isFinite(Number(timeoutMs)) ? Math.max(0, Number(timeoutMs)) : 2000;
  return Promise.race([
    BRIDGE.loading.catch(() => {}),
    new Promise((resolve) => setTimeout(resolve, timeout)),
  ]);
}

export async function kwiver_bridge_ready(timeoutMs = 2000) {
  await bridgeReadyPromise(timeoutMs);
  return bridgeAvailable();
}

export function kwiver_bridge_status() {
  return {
    available: BRIDGE.api !== null && BRIDGE.session !== null,
    command_protocol: bridgeCommandProtocol(),
    loaded_candidate: BRIDGE.loadedCandidate,
    load_errors: Array.isArray(BRIDGE.loadErrors) ? [...BRIDGE.loadErrors] : [],
  };
}

export function kwiver_bridge_test_reset() {
  bridgeLoadGeneration += 1;
  BRIDGE.api = null;
  BRIDGE.session = null;
  BRIDGE.loading = null;
  BRIDGE.commandProtocol = DEFAULT_COMMAND_PROTOCOL;
  BRIDGE.loadedCandidate = null;
  BRIDGE.loadErrors = [];
  commandNonce = 0;
}

export function kwiver_bridge_test_set_autoload(enabled) {
  BRIDGE_TEST.disableAutoload = !Boolean(enabled);
  if (BRIDGE_TEST.disableAutoload) {
    bridgeLoadGeneration += 1;
    BRIDGE.loading = null;
  }
}

export function kwiver_bridge_test_install_mock_api(api) {
  kwiver_bridge_test_reset();
  if (!api || typeof api !== "object") {
    return false;
  }
  if (
    typeof api.ffi_browser_demo_session_new !== "function"
    || typeof api.ffi_browser_demo_command_protocol !== "function"
    || typeof api.ffi_browser_demo_session_dispatch_command_json !== "function"
  ) {
    return false;
  }
  const protocol = commandProtocolFromApi(api);
  if (typeof protocol !== "string" || protocol === "") {
    return false;
  }
  BRIDGE.api = api;
  BRIDGE.session = api.ffi_browser_demo_session_new();
  BRIDGE.commandProtocol = protocol;
  return true;
}

function settingValue(settings, key, fallback) {
  if (settings && typeof settings.get === "function") {
    const value = settings.get(key);
    return value === undefined ? fallback : value;
  }
  if (settings && Object.prototype.hasOwnProperty.call(settings, key)) {
    return settings[key];
  }
  return fallback;
}

function asNumber(value, fallback) {
  const n = Number(value);
  return Number.isFinite(n) ? n : fallback;
}

function asInt(value, fallback) {
  const n = Math.round(asNumber(value, Number.NaN));
  return Number.isFinite(n) ? n : fallback;
}

function iterableEntries(value) {
  if (value instanceof Map) {
    return Array.from(value.entries());
  }
  if (value && typeof value === "object" && !Array.isArray(value)) {
    return Object.entries(value);
  }
  return [];
}

function colourToJson(colour) {
  if (colour && typeof colour.hsla === "function") {
    const hsla = colour.hsla();
    if (Array.isArray(hsla) && hsla.length >= 4) {
      return {
        h: asInt(hsla[0], 0),
        s: asInt(hsla[1], 0),
        l: asInt(hsla[2], 0),
        a: asNumber(hsla[3], 1),
      };
    }
  }

  if (Array.isArray(colour) && colour.length >= 4) {
    return {
      h: asInt(colour[0], 0),
      s: asInt(colour[1], 0),
      l: asInt(colour[2], 0),
      a: asNumber(colour[3], 1),
    };
  }

  if (colour && typeof colour === "object") {
    return {
      h: asInt(colour.h, 0),
      s: asInt(colour.s, 0),
      l: asInt(colour.l, 0),
      a: asNumber(colour.a, 1),
    };
  }

  return null;
}

function rendererFromSettings(settings, options) {
  const fromOptions = options && typeof options.renderer === "string"
    ? options.renderer
    : null;
  if (fromOptions) {
    return fromOptions;
  }
  const fromSettings = settingValue(settings, "quiver.renderer", "katex");
  return typeof fromSettings === "string" && fromSettings !== "" ? fromSettings : "katex";
}

function base64UrlPrefix() {
  if (
    typeof window === "undefined"
    || !window.location
    || typeof window.location.href !== "string"
  ) {
    return "";
  }
  return window.location.href.replace(/\?.*$/, "").replace(/#.*$/, "");
}

function base64ShareUrl(payload, settings, options) {
  const prefix = base64UrlPrefix();
  if (typeof payload !== "string" || payload === "") {
    return prefix;
  }

  const renderer = rendererFromSettings(settings, options);
  const defaultRenderer = "katex";
  const rendererPrefix = renderer === defaultRenderer ? "" : `r=${renderer}&`;
  const macroData = options && typeof options.macro_url === "string" && options.macro_url !== ""
    ? `&macro_url=${encodeURIComponent(options.macro_url)}`
    : "";
  return `${prefix}#${rendererPrefix}q=${payload}${macroData}`;
}

function tikzInput(settings, options, definitions) {
  const sep = options && options.sep ? options.sep : {};
  const colours = {};
  const definitionColours = definitions && definitions.colours ? definitions.colours : {};
  for (const [name, colour] of iterableEntries(definitionColours)) {
    const parsed = colourToJson(colour);
    if (parsed !== null && typeof name === "string" && name !== "") {
      colours[name] = parsed;
    }
  }

  const input = {
    settings: {
      centre_diagram: Boolean(settingValue(settings, "export.centre_diagram", true)),
      ampersand_replacement: Boolean(
        settingValue(settings, "export.ampersand_replacement", false),
      ),
      cramped: Boolean(settingValue(settings, "export.cramped", false)),
      standalone: false,
    },
    options: {
      renderer: rendererFromSettings(settings, options),
      sep: {
        column_em: asNumber(sep.column, 1.8),
        row_em: asNumber(sep.row, 1.8),
      },
    },
    definitions: {
      colours,
    },
  };

  if (options && typeof options.macro_url === "string" && options.macro_url !== "") {
    input.options.macro_url = options.macro_url;
  }

  return input;
}

function fletcherInput(settings, options) {
  const input = {
    settings: {
      centre_diagram: Boolean(settingValue(settings, "export.centre_diagram", true)),
    },
    options: {
      renderer: rendererFromSettings(settings, options),
    },
  };
  if (options && typeof options.macro_url === "string" && options.macro_url !== "") {
    input.options.macro_url = options.macro_url;
  }
  return input;
}

function htmlInput(settings, options) {
  const dimensions = options && options.dimensions ? options.dimensions : {};
  const input = {
    settings: {
      base_url: "https://q.uiver.app",
      fixed_size: Boolean(settingValue(settings, "export.embed.fixed_size", false)),
      width: asInt(settingValue(settings, "export.embed.width", 400), 400),
      height: asInt(settingValue(settings, "export.embed.height", 400), 400),
      diagram_width: asInt(dimensions.width, 400),
      diagram_height: asInt(dimensions.height, 400),
      embed_padding: 24,
    },
    options: {
      renderer: rendererFromSettings(settings, options),
    },
  };
  if (options && typeof options.macro_url === "string" && options.macro_url !== "") {
    input.options.macro_url = options.macro_url;
  }
  return input;
}

function commandResultPayload(result, after) {
  if (typeof result === "string" && result !== "") {
    return result;
  }
  if (result && typeof result === "object" && typeof result.payload === "string" && result.payload !== "") {
    return result.payload;
  }
  if (after && typeof after.payload === "string" && after.payload !== "") {
    return after.payload;
  }
  return null;
}

function dispatchCommandEnvelope(command) {
  if (!bridgeAvailable() || !command || typeof command !== "object") {
    return null;
  }
  try {
    const normalized = normalizeCommand(command);
    const raw = BRIDGE.api.ffi_browser_demo_session_dispatch_command_json(
      BRIDGE.session,
      JSON.stringify(normalized),
    );
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== "object") {
      return null;
    }
    const protocol = bridgeCommandProtocol();
    if (typeof parsed.protocol !== "string" || parsed.protocol !== protocol) {
      return null;
    }
    return parsed;
  } catch (_e) {
    return null;
  }
}

function dispatchCommandResult(action, input, origin = "ui.bridge", rootFields = null) {
  if (typeof action !== "string" || action === "") {
    return null;
  }
  const command = { action, origin };
  if (input !== undefined) {
    command.input = input;
  }
  if (rootFields && typeof rootFields === "object" && !Array.isArray(rootFields)) {
    for (const [key, value] of Object.entries(rootFields)) {
      if (
        key === "action" ||
        key === "origin" ||
        key === "input" ||
        key === "protocol" ||
        key === "command_id"
      ) {
        continue;
      }
      command[key] = value;
    }
  }
  const envelope = dispatchCommandEnvelope(command);
  if (!envelope || envelope.ok !== true) {
    return null;
  }
  return envelope;
}

function dispatchMutationResult(action, input, origin = "ui.bridge") {
  const envelope = dispatchCommandResult(action, input, origin);
  if (!envelope) {
    return null;
  }
  const result = envelope.result;
  if (
    result
    && typeof result === "object"
    && Object.prototype.hasOwnProperty.call(result, "ok")
    && result.ok !== true
  ) {
    return null;
  }
  return envelope;
}

function normalizeTikzMetadata(rawMetadata) {
  const metadata = {
    tikz_incompatibilities: new Set(),
    dependencies: new Map(),
  };

  if (!rawMetadata || typeof rawMetadata !== "object") {
    return metadata;
  }

  const incompatibilities = Array.isArray(rawMetadata.tikz_incompatibilities)
    ? rawMetadata.tikz_incompatibilities
    : [];
  for (const item of incompatibilities) {
    if (typeof item === "string" && item !== "") {
      metadata.tikz_incompatibilities.add(item);
    }
  }

  const dependencies = rawMetadata.dependencies;
  if (dependencies && typeof dependencies === "object" && !Array.isArray(dependencies)) {
    for (const [library, reasonsObject] of Object.entries(dependencies)) {
      if (typeof library !== "string" || library === "") {
        continue;
      }
      const reasons = new Set();
      if (reasonsObject && typeof reasonsObject === "object" && !Array.isArray(reasonsObject)) {
        for (const [reason, present] of Object.entries(reasonsObject)) {
          if (present && typeof reason === "string" && reason !== "") {
            reasons.add(reason);
          }
        }
      }
      metadata.dependencies.set(library, reasons);
    }
  }

  return metadata;
}

export function kwiver_bridge_export(format, settings, options, definitions) {
  switch (format) {
    case "tikz-cd": {
      const envelope = dispatchCommandResult(
        "render_tikz_json",
        tikzInput(settings, options, definitions),
        "ui.bridge.export.tikz",
      );
      const result = envelope && envelope.result && typeof envelope.result === "object"
        ? envelope.result
        : null;
      return {
        data: typeof result?.data === "string" ? result.data : "",
        metadata: normalizeTikzMetadata(result?.metadata),
      };
    }
    case "fletcher": {
      const envelope = dispatchCommandResult(
        "render_fletcher",
        fletcherInput(settings, options),
        "ui.bridge.export.fletcher",
      );
      return {
        data: typeof envelope?.result === "string" ? envelope.result : "",
        metadata: { fletcher_incompatibilities: new Set() },
      };
    }
    case "html": {
      const envelope = dispatchCommandResult(
        "render_html_embed",
        htmlInput(settings, options),
        "ui.bridge.export.html",
      );
      return {
        data: typeof envelope?.result === "string" ? envelope.result : "",
        metadata: {},
      };
    }
    case "base64": {
      const payload = kwiver_bridge_export_payload("ui.bridge.export.base64");
      if (typeof payload !== "string") {
        return null;
      }
      return {
        data: base64ShareUrl(payload, settings, options),
        metadata: {},
      };
    }
    default:
      return null;
  }
}

export function kwiver_bridge_export_payload(origin = "ui.bridge.export.payload") {
  const envelope = dispatchCommandResult("export_payload", undefined, origin);
  if (!envelope) {
    return null;
  }
  if (typeof envelope.result === "string") {
    return envelope.result;
  }
  if (envelope.after && typeof envelope.after.payload === "string") {
    return envelope.after.payload;
  }
  return null;
}

export function kwiver_bridge_reset(origin = "ui.bridge.reset") {
  return dispatchCommandResult("reset", undefined, origin);
}

export function kwiver_bridge_import_tikz_payload(input, settings) {
  if (typeof input !== "string") {
    return null;
  }

  const renderer = rendererFromSettings(settings, null);
  const envelope = dispatchCommandResult(
    "import_text_auto_json",
    input,
    "ui.bridge.import",
    {
      default_renderer: renderer,
    },
  );
  if (!envelope) {
    return null;
  }
  return commandResultPayload(envelope.result, envelope.after);
}

export function kwiver_bridge_import_payload_json(
  payload,
  origin = "ui.bridge.import_payload",
) {
  if (typeof payload !== "string" || payload === "") {
    return null;
  }

  const envelope = dispatchMutationResult("import_payload", payload, origin);
  if (!envelope) {
    return null;
  }

  const bridgedPayload = commandResultPayload(envelope.result, envelope.after);
  if (typeof bridgedPayload !== "string" || bridgedPayload === "") {
    return null;
  }

  return {
    payload: bridgedPayload,
    after: envelope.after && typeof envelope.after === "object" ? envelope.after : null,
  };
}

export function kwiver_bridge_all_cells() {
  const envelope = dispatchCommandResult("all_cells_json", undefined, "ui.bridge.all_cells");
  if (!envelope) {
    return null;
  }
  return Array.isArray(envelope.result) ? envelope.result : null;
}

export function kwiver_bridge_all_cell_ids(origin = "ui.bridge.all_cell_ids") {
  const envelope = dispatchCommandResult("all_cell_ids_json", undefined, origin);
  if (!envelope || !Array.isArray(envelope.result)) {
    return null;
  }
  const out = [];
  for (const rawId of envelope.result) {
    const cellId = Number(rawId);
    if (!Number.isInteger(cellId)) {
      return null;
    }
    out.push(cellId);
  }
  return out;
}

export function kwiver_bridge_dependencies(
  cellId,
  origin = "ui.bridge.dependencies",
) {
  if (!Number.isInteger(cellId)) {
    return null;
  }
  const envelope = dispatchCommandResult(
    "dependencies_of_json",
    { cell_id: cellId },
    origin,
  );
  if (!envelope || !Array.isArray(envelope.result)) {
    return null;
  }
  const out = [];
  for (const rawId of envelope.result) {
    const dependencyId = Number(rawId);
    if (!Number.isInteger(dependencyId)) {
      return null;
    }
    out.push(dependencyId);
  }
  return out;
}

export function kwiver_bridge_connected_components(
  roots,
  origin = "ui.bridge.connected_components",
) {
  if (!Array.isArray(roots)) {
    return null;
  }
  const normalizedRoots = [];
  for (const rawRoot of roots) {
    const rootId = Number(rawRoot);
    if (!Number.isInteger(rootId)) {
      return null;
    }
    normalizedRoots.push(rootId);
  }

  const envelope = dispatchCommandResult(
    "connected_components_json",
    { roots: normalizedRoots },
    origin,
  );
  if (!envelope || !Array.isArray(envelope.result)) {
    return null;
  }

  const out = [];
  for (const rawId of envelope.result) {
    const cellId = Number(rawId);
    if (!Number.isInteger(cellId)) {
      return null;
    }
    out.push(cellId);
  }
  return out;
}

export function kwiver_bridge_transitive_dependencies(
  roots,
  excludeRoots = false,
  origin = "ui.bridge.transitive_dependencies",
) {
  if (!Array.isArray(roots)) {
    return null;
  }
  const normalizedRoots = [];
  for (const rawRoot of roots) {
    const rootId = Number(rawRoot);
    if (!Number.isInteger(rootId)) {
      return null;
    }
    normalizedRoots.push(rootId);
  }

  const envelope = dispatchCommandResult(
    "transitive_dependencies_json",
    {
      roots: normalizedRoots,
      exclude_roots: Boolean(excludeRoots),
    },
    origin,
  );
  if (!envelope || !Array.isArray(envelope.result)) {
    return null;
  }

  const out = [];
  for (const rawId of envelope.result) {
    const cellId = Number(rawId);
    if (!Number.isInteger(cellId)) {
      return null;
    }
    out.push(cellId);
  }
  return out;
}

export function kwiver_bridge_transitive_reverse_dependencies(
  roots,
  origin = "ui.bridge.transitive_reverse_dependencies",
) {
  if (!Array.isArray(roots)) {
    return null;
  }
  const normalizedRoots = [];
  for (const rawRoot of roots) {
    const rootId = Number(rawRoot);
    if (!Number.isInteger(rootId)) {
      return null;
    }
    normalizedRoots.push(rootId);
  }

  const envelope = dispatchCommandResult(
    "transitive_reverse_dependencies_json",
    { roots: normalizedRoots },
    origin,
  );
  if (!envelope || !Array.isArray(envelope.result)) {
    return null;
  }

  const out = [];
  for (const rawId of envelope.result) {
    const cellId = Number(rawId);
    if (!Number.isInteger(cellId)) {
      return null;
    }
    out.push(cellId);
  }
  return out;
}

export function kwiver_bridge_reverse_dependencies(
  cellId,
  origin = "ui.bridge.reverse_dependencies",
) {
  if (!Number.isInteger(cellId)) {
    return null;
  }
  const envelope = dispatchCommandResult(
    "reverse_dependencies_of_json",
    { cell_id: cellId },
    origin,
  );
  if (!envelope || !Array.isArray(envelope.result)) {
    return null;
  }
  const out = [];
  for (const rawId of envelope.result) {
    const dependencyId = Number(rawId);
    if (!Number.isInteger(dependencyId)) {
      return null;
    }
    out.push(dependencyId);
  }
  return out;
}
export function kwiver_bridge_set_selection(selectedIds, origin = "ui.bridge.selection") {
  return dispatchCommandResult("set_selection", selectedIds, origin);
}

export function kwiver_bridge_export_selection(
  includeDependencies = true,
  origin = "ui.bridge.selection",
) {
  const envelope = dispatchCommandResult(
    "export_selection",
    { include_dependencies: Boolean(includeDependencies) },
    origin,
  );
  if (!envelope) {
    return null;
  }
  return typeof envelope.result === "string" ? envelope.result : null;
}

export function kwiver_bridge_paste_selection_json(
  payload,
  originX,
  originY,
  startId = 1,
  origin = "ui.bridge.paste",
) {
  if (typeof payload !== "string" || payload === "") {
    return null;
  }
  return dispatchMutationResult("paste_selection_json", {
    payload,
    origin_x: asInt(originX, 0),
    origin_y: asInt(originY, 0),
    start_id: asInt(startId, 1),
  }, origin);
}

export function kwiver_bridge_add_vertex_json(
  label,
  x,
  y,
  labelColour = null,
  origin = "ui.bridge.create.vertex",
) {
  if (typeof label !== "string") {
    return null;
  }
  const input = {
    label,
    x: asInt(x, 0),
    y: asInt(y, 0),
  };
  if (
    labelColour
    && typeof labelColour === "object"
    && !Array.isArray(labelColour)
  ) {
    input.label_colour = labelColour;
  }
  return dispatchMutationResult("add_vertex_json", input, origin);
}

export function kwiver_bridge_add_edge_json(
  sourceId,
  targetId,
  label = "",
  options = null,
  labelColour = null,
  origin = "ui.bridge.create.edge",
) {
  if (
    !Number.isInteger(sourceId)
    || !Number.isInteger(targetId)
    || typeof label !== "string"
  ) {
    return null;
  }
  const input = {
    source_id: sourceId,
    target_id: targetId,
    label,
  };
  if (
    options
    && typeof options === "object"
    && !Array.isArray(options)
  ) {
    input.options = options;
  }
  if (
    labelColour
    && typeof labelColour === "object"
    && !Array.isArray(labelColour)
  ) {
    input.label_colour = labelColour;
  }
  return dispatchMutationResult("add_edge_json", input, origin);
}

export function kwiver_bridge_move_vertex_json(
  vertexId,
  x,
  y,
  origin = "ui.bridge.move",
) {
  if (!Number.isInteger(vertexId)) {
    return null;
  }
  return dispatchMutationResult("move_vertex_json", {
    vertex_id: vertexId,
    x: asInt(x, 0),
    y: asInt(y, 0),
  }, origin);
}

export function kwiver_bridge_set_label_json(
  cellId,
  label,
  origin = "ui.bridge.label",
) {
  if (!Number.isInteger(cellId) || typeof label !== "string") {
    return null;
  }
  return dispatchMutationResult("set_label_json", {
    cell_id: cellId,
    label,
  }, origin);
}

export function kwiver_bridge_set_label_colour_json(
  cellId,
  labelColour,
  origin = "ui.bridge.label_colour",
) {
  if (
    !Number.isInteger(cellId)
    || !labelColour
    || typeof labelColour !== "object"
    || Array.isArray(labelColour)
  ) {
    return null;
  }
  return dispatchMutationResult("set_label_colour_json", {
    cell_id: cellId,
    label_colour: labelColour,
  }, origin);
}

export function kwiver_bridge_reconnect_edge_json(
  edgeId,
  sourceId,
  targetId,
  origin = "ui.bridge.reconnect",
) {
  if (
    !Number.isInteger(edgeId)
    || !Number.isInteger(sourceId)
    || !Number.isInteger(targetId)
  ) {
    return null;
  }
  return dispatchMutationResult("reconnect_edge_json", {
    edge_id: edgeId,
    source_id: sourceId,
    target_id: targetId,
  }, origin);
}

export function kwiver_bridge_remove_json(
  cellId,
  when,
  origin = "ui.bridge.remove",
) {
  if (!Number.isInteger(cellId)) {
    return null;
  }
  return dispatchMutationResult("remove_json", {
    cell_id: cellId,
    when: asInt(when, 0),
  }, origin);
}


export function kwiver_bridge_set_edge_offset_json(
  edgeId,
  offset,
  origin = "ui.bridge.edge.offset",
) {
  if (!Number.isInteger(edgeId)) {
    return null;
  }
  return dispatchMutationResult("set_edge_offset_json", {
    edge_id: edgeId,
    offset: asInt(offset, 0),
  }, origin);
}

export function kwiver_bridge_set_edge_curve_json(
  edgeId,
  curve,
  origin = "ui.bridge.edge.curve",
) {
  if (!Number.isInteger(edgeId)) {
    return null;
  }
  return dispatchMutationResult("set_edge_curve_json", {
    edge_id: edgeId,
    curve: asInt(curve, 0),
  }, origin);
}

export function kwiver_bridge_set_edge_label_alignment_json(
  edgeId,
  labelAlignment,
  origin = "ui.bridge.edge.label_alignment",
) {
  if (!Number.isInteger(edgeId) || typeof labelAlignment !== "string") {
    return null;
  }
  return dispatchMutationResult("set_edge_label_alignment_json", {
    edge_id: edgeId,
    label_alignment: labelAlignment,
  }, origin);
}

export function kwiver_bridge_set_edge_label_position_json(
  edgeId,
  labelPosition,
  origin = "ui.bridge.edge.label_position",
) {
  if (!Number.isInteger(edgeId)) {
    return null;
  }
  return dispatchMutationResult("set_edge_label_position_json", {
    edge_id: edgeId,
    label_position: asInt(labelPosition, 0),
  }, origin);
}

export function kwiver_bridge_reverse_edge_json(
  edgeId,
  origin = "ui.bridge.edge.reverse",
) {
  if (!Number.isInteger(edgeId)) {
    return null;
  }
  return dispatchMutationResult("reverse_edge_json", {
    edge_id: edgeId,
  }, origin);
}

export function kwiver_bridge_flip_edge_json(
  edgeId,
  origin = "ui.bridge.edge.flip",
) {
  if (!Number.isInteger(edgeId)) {
    return null;
  }
  return dispatchMutationResult("flip_edge_json", {
    edge_id: edgeId,
  }, origin);
}

export function kwiver_bridge_flip_edge_labels_json(
  edgeId,
  origin = "ui.bridge.edge.flip_labels",
) {
  if (!Number.isInteger(edgeId)) {
    return null;
  }
  return dispatchMutationResult("flip_edge_labels_json", {
    edge_id: edgeId,
  }, origin);
}

export function kwiver_bridge_patch_edge_options_json(
  edgeId,
  patch,
  origin = "ui.bridge.edge.patch",
) {
  if (
    !Number.isInteger(edgeId)
    || !patch
    || typeof patch !== "object"
    || Array.isArray(patch)
  ) {
    return null;
  }
  return dispatchMutationResult("patch_edge_options_json", {
    edge_id: edgeId,
    patch,
  }, origin);
}
