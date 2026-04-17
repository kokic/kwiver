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
  };
}

function newToolbar(Toolbar) {
  const toolbar = new Toolbar();
  toolbar.element = createToolbarElementStub();
  return toolbar;
}

async function run() {
  const restoreDom = installMinimalDomStubs();
  try {
    const { Toolbar } = await import(`../ui.mjs?toolbar-update-fail-fast-test=${Date.now()}`);

    {
      const toolbar = newToolbar(Toolbar);
      const ui = {
        kwiver_require_runtime_all_cell_ids() {
          throw new Error("[kwiver-only] ui.toolbar.all_cell_ids: all_cell_ids_json failed");
        },
      };
      assert.throws(
        () => toolbar.update(ui),
        /\[kwiver-only\] ui\.toolbar\.all_cell_ids: all_cell_ids_json failed/,
      );
    }

    {
      const toolbar = newToolbar(Toolbar);
      const ui = {
        kwiver_require_runtime_all_cell_ids() {
          return [1, 2, 3];
        },
        kwiver_require_selected_ids() {
          return [1];
        },
        kwiver_require_runtime_connected_component_ids() {
          throw new Error(
            "[kwiver-only] ui.toolbar.connected_components: connected_components_json failed",
          );
        },
      };
      assert.throws(
        () => toolbar.update(ui),
        /\[kwiver-only\] ui\.toolbar\.connected_components: connected_components_json failed/,
      );
    }

    console.log("toolbar update fail-fast smoke passed: 2/2");
  } finally {
    restoreDom();
  }
}

await run();
