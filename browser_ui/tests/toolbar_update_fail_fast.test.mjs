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

function createToolbarElementStub() {
  const actionState = new Map();
  const resetZoomShortcut = { innerText: "" };
  return {
    actionState,
    resetZoomShortcut,
    element: {
      query_selector(selector) {
        if (selector === '.action[data-name="reset-zoom"] .shortcut') {
          return { element: resetZoomShortcut };
        }
        const match = selector.match(/^\.action\[data-name="(.+)"\]$/);
        if (!match) {
          throw new Error(`unexpected selector: ${selector}`);
        }
        const name = match[1];
        if (!actionState.has(name)) {
          actionState.set(name, { disabled: false });
        }
        return { element: actionState.get(name) };
      },
    },
  };
}

function newToolbar(Toolbar) {
  const toolbar = new Toolbar();
  const elementStub = createToolbarElementStub();
  toolbar.element = elementStub.element;
  return { toolbar, ...elementStub };
}

async function run() {
  const restoreDom = installMinimalDomStubs();
  try {
    const { Toolbar } = await import(`../ui.mjs?toolbar-update-fail-fast-test=${Date.now()}`);

    {
      const { toolbar } = newToolbar(Toolbar);
      const ui = {
        kwiver_require_runtime_selection_toolbar_state() {
          throw new Error("[kwiver-only] ui.toolbar: selection_toolbar_state_json failed");
        },
      };
      assert.throws(
        () => toolbar.update(ui),
        /\[kwiver-only\] ui\.toolbar: selection_toolbar_state_json failed/,
      );
    }

    {
      const { toolbar, actionState, resetZoomShortcut } = newToolbar(Toolbar);
      const ui = {
        kwiver_require_runtime_selection_toolbar_state() {
          return {
            can_select_all: true,
            can_expand_connected: false,
            can_deselect_all: true,
            can_delete: true,
            can_transform: true,
            has_selection: true,
          };
        },
        kwiver_require_runtime_all_cell_ids() {
          throw new Error("legacy all_cell_ids lookup should not be called");
        },
        kwiver_require_selected_ids() {
          throw new Error("legacy selected_ids lookup should not be called");
        },
        kwiver_require_runtime_connected_component_ids() {
          throw new Error("legacy connected_components lookup should not be called");
        },
        in_mode() {
          return true;
        },
        history: {
          present: 0,
          actions: [1],
        },
        element: {
          query_selector() {
            return null;
          },
        },
        view_vertices() {
          return [];
        },
        scale: 0,
      };
      toolbar.update(ui);
      assert.equal(actionState.get("select-all")?.disabled, false);
      assert.equal(actionState.get("select-connected")?.disabled, true);
      assert.equal(actionState.get("deselect-all")?.disabled, false);
      assert.equal(actionState.get("delete")?.disabled, false);
      assert.equal(actionState.get("transform")?.disabled, false);
      assert.equal(actionState.get("centre-view")?.disabled, false);
      assert.equal(actionState.get("reset-zoom")?.disabled, true);
      assert.equal(resetZoomShortcut.innerText, "100%");
    }

    console.log("toolbar update fail-fast smoke passed: 2/2");
  } finally {
    restoreDom();
  }
}

await run();
