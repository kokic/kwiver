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

function createHistoryUiStub() {
  const flushCalls = [];
  const deleteCalls = [];
  const removedIds = new Set();
  const cell = {
    kwiver_id: 1,
    kwiver_render_level() {
      return 0;
    },
    is_edge() {
      return false;
    },
    render() {},
  };

  const ui = {
    selection: new Set(),
    focus_position: { x: 0, y: 0 },
    toolbar: { update() {} },
    panel: {
      update() {},
      hide_if_unselected() {},
    },
    colour_picker: {
      update_diagram_colours() {},
    },
    focus_point: {
      class_list: {
        remove() {},
      },
    },
    kwiver_history_capture_records() {
      return [];
    },
    kwiver_history_flush(when, origin) {
      flushCalls.push({ when, origin });
      return true;
    },
    kwiver_history_delete(cells, when) {
      deleteCalls.push({
        when,
        ids: Array.from(cells).map((entry) => entry.kwiver_id),
      });
      for (const entry of cells) {
        removedIds.add(entry.kwiver_id);
      }
      return {};
    },
    kwiver_runtime_cells_by_id() {
      return new Map();
    },
    view_all_cells() {
      return removedIds.has(cell.kwiver_id) ? [] : [cell];
    },
    view_contains_cell(entry) {
      return !removedIds.has(entry.kwiver_id);
    },
    remove_cell(entry) {
      removedIds.add(entry.kwiver_id);
    },
    kwiver_apply_runtime_selection_from_envelope() {
      return true;
    },
    kwiver_require_runtime_transitive_dependency_cells() {
      return new Set();
    },
    deselect() {},
    select() {},
    reposition_focus_point() {},
  };

  return { ui, flushCalls, deleteCalls, cell };
}

async function run() {
  const restoreDom = installMinimalDomStubs();
  try {
    const { History } = await import(`../ui.mjs?history-flush-driver-test=${Date.now()}`);

    {
      const { ui, flushCalls } = createHistoryUiStub();
      const history = new History();

      history.add(ui, [{ kind: "label", labels: [] }], false);

      assert.equal(history.present, 1);
      assert.deepEqual(flushCalls, [{ when: 1, origin: "ui.history.add" }]);
    }

    {
      const { ui, flushCalls } = createHistoryUiStub();
      const history = new History();

      history.add(ui, [{ kind: "label", labels: [] }], false);
      history.pop(ui);

      assert.equal(history.present, 0);
      assert.deepEqual(flushCalls, [
        { when: 1, origin: "ui.history.add" },
        { when: 0, origin: "ui.history.pop" },
      ]);
    }

    {
      const { ui, flushCalls, deleteCalls, cell } = createHistoryUiStub();
      const history = new History();

      history.add(
        ui,
        [{
          kind: "delete",
          cells: new Set([cell]),
          kwiver_records: [],
        }],
        true,
      );

      assert.deepEqual(deleteCalls, [{ when: 1, ids: [1] }]);
      assert.deepEqual(flushCalls, [{ when: 1, origin: "ui.history.add" }]);
    }

    console.log("history flush driver smoke passed: 3/3");
  } finally {
    restoreDom();
  }
}

await run();
