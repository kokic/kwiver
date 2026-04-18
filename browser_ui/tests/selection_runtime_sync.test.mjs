import assert from "node:assert/strict";

function installMinimalDomStubs() {
  const hadDocument = Object.prototype.hasOwnProperty.call(globalThis, "document");
  const hadWindow = Object.prototype.hasOwnProperty.call(globalThis, "window");
  const previousDocument = globalThis.document;
  const previousWindow = globalThis.window;

  globalThis.document = {
    documentElement: {},
    addEventListener(type, listener) {
      void type;
      void listener;
    },
    removeEventListener() {},
  };
  globalThis.window = {
    addEventListener() {},
    removeEventListener() {},
    location: { href: "http://localhost/#" },
    getSelection() {
      return {
        removeAllRanges() {},
        addRange() {},
      };
    },
    devicePixelRatio: 1,
  };

  return () => {
    if (hadDocument) {
      globalThis.document = previousDocument;
    } else {
      delete globalThis.document;
    }
    if (hadWindow) {
      globalThis.window = previousWindow;
    } else {
      delete globalThis.window;
    }
  };
}

function createClassListStub() {
  return {
    add() {},
    remove() {},
    toggle() {},
  };
}

function createUiStub(UI) {
  const syncOrigins = [];
  const ui = Object.create(UI.prototype);
  ui.selection = new Set();
  ui.view_contains_cell = () => true;
  ui.update_focus_tooltip = () => {};
  ui.panel = {
    update() {},
    element: { class_list: createClassListStub() },
    label_input: {
      parent: { class_list: createClassListStub() },
    },
  };
  ui.toolbar = { update() {} };
  ui.kwiver_sync_runtime_selection_from_ui = (origin) => {
    syncOrigins.push(origin);
    return true;
  };
  return { ui, syncOrigins };
}

function createCell(id, { isEdge = false } = {}) {
  return {
    kwiver_id: id,
    is_edge() {
      return isEdge;
    },
    is_vertex() {
      return !isEdge;
    },
    select() {},
    deselect() {},
  };
}

async function run() {
  const restoreDom = installMinimalDomStubs();
  try {
    const { UI } = await import(`../ui.mjs?selection-runtime-sync-test=${Date.now()}`);

    {
      const { ui, syncOrigins } = createUiStub(UI);
      const cell = createCell(1);

      UI.prototype.select.call(ui, cell);

      assert.deepEqual(Array.from(ui.selection), [cell]);
      assert.deepEqual(syncOrigins, ["ui.selection.select"]);
    }

    {
      const { ui, syncOrigins } = createUiStub(UI);
      const cell = createCell(1);
      ui.selection = new Set([cell]);

      UI.prototype.deselect.call(ui, cell);

      assert.deepEqual(Array.from(ui.selection), []);
      assert.deepEqual(syncOrigins, ["ui.selection.deselect"]);
    }

    {
      const { ui, syncOrigins } = createUiStub(UI);
      const vertex = createCell(1);
      const edge = createCell(2, { isEdge: true });
      ui.selection = new Set([vertex]);
      ui.kwiver_js_cells_by_id = () => new Map([
        [1, vertex],
        [2, edge],
      ]);

      const ok = UI.prototype.kwiver_apply_runtime_selection.call(
        ui,
        [1, 2],
      );

      assert.equal(ok, true);
      assert.deepEqual(Array.from(ui.selection), [vertex, edge]);
      assert.deepEqual(syncOrigins, ["ui.selection.runtime"]);
    }

    console.log("selection runtime sync smoke passed: 3/3");
  } finally {
    restoreDom();
  }
}

await run();
