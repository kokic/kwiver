import assert from "node:assert/strict";

function createClassList() {
  const values = new Set();
  return {
    add(...tokens) {
      for (const token of tokens) {
        values.add(token);
      }
    },
    remove(...tokens) {
      for (const token of tokens) {
        values.delete(token);
      }
    },
    toggle(token, force) {
      if (force === true) {
        values.add(token);
        return true;
      }
      if (force === false) {
        values.delete(token);
        return false;
      }
      if (values.has(token)) {
        values.delete(token);
        return false;
      }
      values.add(token);
      return true;
    },
    contains(token) {
      return values.has(token);
    },
  };
}

class FakeTextNode {
  constructor(text) {
    this.textContent = text;
    this.parentElement = null;
  }

  remove() {
    if (this.parentElement) {
      this.parentElement.removeChild(this);
    }
  }
}

class FakeElement {
  constructor(tagName) {
    this.tagName = String(tagName).toUpperCase();
    this.parentElement = null;
    this.childNodes = [];
    this.style = {};
    this.attributes = new Map();
    this.classList = createClassList();
    this.eventListeners = new Map();
    this.id = "";
  }

  appendChild(child) {
    child.parentElement = this;
    this.childNodes.push(child);
    return child;
  }

  removeChild(child) {
    const index = this.childNodes.indexOf(child);
    if (index >= 0) {
      this.childNodes.splice(index, 1);
      child.parentElement = null;
    }
    return child;
  }

  remove() {
    if (this.parentElement) {
      this.parentElement.removeChild(this);
    }
  }

  addEventListener(type, listener) {
    if (!this.eventListeners.has(type)) {
      this.eventListeners.set(type, []);
    }
    this.eventListeners.get(type).push(listener);
  }

  dispatchEvent(event) {
    const listeners = this.eventListeners.get(event?.type) ?? [];
    for (const listener of listeners) {
      listener(event);
    }
    return true;
  }

  setAttribute(name, value) {
    const stringValue = String(value);
    this.attributes.set(name, stringValue);
    if (name === "id") {
      this.id = stringValue;
    }
    if (name === "class") {
      this.classList = createClassList();
      for (const token of stringValue.split(/\s+/).filter(Boolean)) {
        this.classList.add(token);
      }
    }
  }

  removeAttribute(name) {
    this.attributes.delete(name);
    if (name === "id") {
      this.id = "";
    }
    if (name === "class") {
      this.classList = createClassList();
    }
  }

  getAttribute(name) {
    return this.attributes.has(name) ? this.attributes.get(name) : null;
  }

  get firstChild() {
    return this.childNodes.length > 0 ? this.childNodes[0] : null;
  }

  get children() {
    return this.childNodes.filter((child) => child instanceof FakeElement);
  }

  querySelector(selector) {
    return this.querySelectorAll(selector)[0] ?? null;
  }

  querySelectorAll(selector) {
    const selectors = selector.split(",").map((item) => item.trim()).filter(Boolean);
    const matches = [];
    const visit = (node) => {
      if (!(node instanceof FakeElement)) {
        return;
      }
      if (selectors.some((candidate) => this.matchesSelector(node, candidate))) {
        matches.push(node);
      }
      for (const child of node.childNodes) {
        visit(child);
      }
    };
    for (const child of this.childNodes) {
      visit(child);
    }
    return matches;
  }

  matchesSelector(node, selector) {
    if (selector.startsWith(".")) {
      return node.classList.contains(selector.slice(1));
    }
    return node.tagName.toLowerCase() === selector.toLowerCase();
  }

  cloneNode() {
    return new FakeElement(this.tagName);
  }

  contains(other) {
    let current = other;
    while (current) {
      if (current === this) {
        return true;
      }
      current = current.parentElement;
    }
    return false;
  }

  getBoundingClientRect() {
    return { left: 0, top: 0, width: 0, height: 0 };
  }

  focus() {}

  blur() {}

  setSelectionRange() {}

  get offsetWidth() {
    return 0;
  }

  get offsetHeight() {
    return 0;
  }
}

function installDomStubs() {
  const hadDocument = Object.prototype.hasOwnProperty.call(globalThis, "document");
  const hadWindow = Object.prototype.hasOwnProperty.call(globalThis, "window");
  const previousDocument = globalThis.document;
  const previousWindow = globalThis.window;

  globalThis.document = {
    documentElement: {},
    body: new FakeElement("body"),
    createElement(tagName) {
      return new FakeElement(tagName);
    },
    createElementNS(_namespace, tagName) {
      return new FakeElement(tagName);
    },
    createTextNode(text) {
      return new FakeTextNode(text);
    },
    createRange() {
      return {
        selectNodeContents() {},
      };
    },
    addEventListener() {},
    removeEventListener() {},
  };
  globalThis.window = {
    addEventListener() {},
    removeEventListener() {},
    devicePixelRatio: 1,
    location: { href: "http://localhost/#" },
    getSelection() {
      return {
        removeAllRanges() {},
        addRange() {},
      };
    },
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

async function run() {
  const restoreDom = installDomStubs();
  try {
    const { Colour, Offset, Point, Position } = await import(`../ds.mjs?vertex-kwiver-id-timing-ds=${Date.now()}`);
    const { Vertex } = await import(`../ui.mjs?vertex-kwiver-id-timing-ui=${Date.now()}`);

    const observedIds = [];
    const ui = {
      default_cell_size: 128,
      cell_width: new Map(),
      cell_height: new Map(),
      codes: new Map(),
      panel: {
        render_maths(_ui, cell) {
          observedIds.push(cell.kwiver_id);
        },
      },
      add_cell() {},
      view_position(cell) {
        return cell.position;
      },
      offset_from_position() {
        return Offset.zero();
      },
      cell_centre_at_position() {
        return Point.zero();
      },
      cell_size() {
        return 128;
      },
    };

    const vertex = new Vertex(
      ui,
      "\\bullet",
      new Position(0, 0),
      Colour.black(),
      7,
    );

    assert.equal(vertex.kwiver_id, 7);
    assert.deepEqual(observedIds, [7]);

    console.log("vertex kwiver id timing smoke passed: 1/1");
  } finally {
    restoreDom();
  }
}

await run();
