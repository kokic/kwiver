const MODULE_CANDIDATES = [
  "../_build/js/release/build/browser_demo/browser_demo.js",
  // keep release
  // "../_build/js/debug/build/browser_demo/browser_demo.js",
];

const DEFAULT_COMMAND_PROTOCOL = "kwiver.command.v1";

const BRIDGE = {
  api: null,
  session: null,
  loading: null,
  commandProtocol: DEFAULT_COMMAND_PROTOCOL,
};

let commandNonce = 0;

function nextCommandId(origin = "ui.bridge") {
  commandNonce += 1;
  return `${origin}-${commandNonce}`;
}

function commandProtocolFromApi(api) {
  if (!api || typeof api.ffi_browser_demo_command_protocol !== "function") {
    return DEFAULT_COMMAND_PROTOCOL;
  }
  try {
    const protocol = api.ffi_browser_demo_command_protocol();
    return typeof protocol === "string" && protocol !== "" ? protocol : DEFAULT_COMMAND_PROTOCOL;
  } catch (_e) {
    return DEFAULT_COMMAND_PROTOCOL;
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
  for (const candidate of MODULE_CANDIDATES) {
    try {
      const mod = await import(candidate);
      if (mod && typeof mod.ffi_browser_demo_session_new === "function") {
        return mod;
      }
    } catch (_e) {
      // Try the next candidate.
    }
  }
  return null;
}

function ensureBridgeLoading() {
  if (BRIDGE.api !== null || BRIDGE.loading !== null) {
    return;
  }
  BRIDGE.loading = loadBridgeApi()
    .then((api) => {
      if (api && typeof api.ffi_browser_demo_session_new === "function") {
        BRIDGE.api = api;
        BRIDGE.session = api.ffi_browser_demo_session_new();
        BRIDGE.commandProtocol = commandProtocolFromApi(api);
      }
    })
    .catch(() => {
      // Keep fallback path active when bridge module cannot be loaded.
    })
    .finally(() => {
      BRIDGE.loading = null;
    });
}

function bridgeAvailable() {
  ensureBridgeLoading();
  return BRIDGE.api !== null && BRIDGE.session !== null;
}

// Preload MoonBit bridge in the background without blocking module initialisation.
ensureBridgeLoading();

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

function syncPayload(payload) {
  if (typeof payload !== "string" || payload === "") {
    return false;
  }
  return dispatchCommandResult("import_payload", payload, "ui.bridge.sync") !== null;
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

export function kwiver_bridge_export(format, payload, settings, options, definitions) {
  if (!syncPayload(payload)) {
    return null;
  }

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
    default:
      return null;
  }
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

export function kwiver_bridge_sync_payload(payload) {
  return syncPayload(payload);
}

export function kwiver_bridge_dispatch_command(command) {
  return dispatchCommandEnvelope(command);
}

export function kwiver_bridge_all_cells() {
  const envelope = dispatchCommandResult("all_cells_json", undefined, "ui.bridge.all_cells");
  if (!envelope) {
    return null;
  }
  return Array.isArray(envelope.result) ? envelope.result : null;
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
