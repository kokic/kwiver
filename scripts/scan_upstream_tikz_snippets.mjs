import { readdirSync, readFileSync, statSync } from "node:fs";
import path from "node:path";
import {
  kwiver_bridge_import_tikz_result,
  kwiver_bridge_ready,
  kwiver_bridge_reset,
  kwiver_bridge_status,
  kwiver_bridge_test_reset,
  kwiver_bridge_test_set_autoload,
} from "../browser_ui/kwiver_bridge.mjs";

const UPSTREAM_ROOT = path.resolve("../quiver");
const TEXT_EXTENSIONS = new Set([".tex", ".md", ".markdown", ".txt", ".js", ".mjs"]);

function shouldSkipDirectory(name) {
  return name === ".git" || name === "node_modules" || name === "_site";
}

function walkFiles(root, out = []) {
  for (const name of readdirSync(root)) {
    const fullPath = path.join(root, name);
    const stat = statSync(fullPath);
    if (stat.isDirectory()) {
      if (!shouldSkipDirectory(name)) {
        walkFiles(fullPath, out);
      }
      continue;
    }
    if (TEXT_EXTENSIONS.has(path.extname(name).toLowerCase())) {
      out.push(fullPath);
    }
  }
  return out;
}

function extractTikzcdBlocks(content) {
  const blocks = [];
  const beginRegex = /\\begin\{tikzcd\*?\}(?:\[[^\]]*\])?/g;
  let match;
  while ((match = beginRegex.exec(content)) !== null) {
    const start = match.index;
    const endToken = match[0].includes("{tikzcd*}") ? "\\end{tikzcd*}" : "\\end{tikzcd}";
    const end = content.indexOf(endToken, beginRegex.lastIndex);
    if (end < 0) {
      break;
    }
    blocks.push({
      start,
      snippet: content.slice(start, end + endToken.length),
    });
    beginRegex.lastIndex = end + endToken.length;
  }
  return blocks;
}

function parseArgs(argv) {
  const args = new Set(argv.slice(2));
  return {
    includeTests: args.has("--include-tests"),
    includeParserSource: args.has("--include-parser-source"),
    showAllFailures: args.has("--all-failures"),
  };
}

function includeFile(relativePath, options) {
  const normalized = relativePath.replace(/\\/g, "/");
  if (!options.includeTests && normalized.startsWith("src/tests/")) {
    return false;
  }
  if (!options.includeParserSource && normalized === "src/parser.mjs") {
    return false;
  }
  return true;
}

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

async function main() {
  const options = parseArgs(process.argv);
  const allFiles = walkFiles(UPSTREAM_ROOT);
  const files = allFiles.filter((fullPath) => {
    const relative = path.relative(UPSTREAM_ROOT, fullPath);
    return includeFile(relative, options);
  });

  const snippets = [];
  for (const fullPath of files) {
    const relative = path.relative(UPSTREAM_ROOT, fullPath);
    const content = readFileSync(fullPath, "utf8");
    for (const block of extractTikzcdBlocks(content)) {
      snippets.push({
        file: relative,
        offset: block.start,
        snippet: block.snippet,
      });
    }
  }

  kwiver_bridge_test_reset();
  kwiver_bridge_test_set_autoload(true);
  const ready = await kwiver_bridge_ready(5000);
  if (!ready) {
    console.error(JSON.stringify({
      ok: false,
      reason: "bridge unavailable",
      bridge_status: kwiver_bridge_status(),
    }, null, 2));
    process.exitCode = 1;
    return;
  }

  let okCount = 0;
  let failCount = 0;
  const byKind = new Map();
  const failures = [];

  for (let i = 0; i < snippets.length; i += 1) {
    const item = snippets[i];
    kwiver_bridge_reset(`scan.upstream.${i}.reset`);

    const result = kwiver_bridge_import_tikz_result(item.snippet, defaultSettings());
    if (result && result.ok === true) {
      okCount += 1;
      continue;
    }

    failCount += 1;
    const kind = result?.error?.kind || "unknown";
    byKind.set(kind, (byKind.get(kind) || 0) + 1);
    failures.push({
      file: item.file,
      offset: item.offset,
      kind,
      message: result?.error?.message || null,
      line: Number.isInteger(result?.error?.line) ? result.error.line : null,
      column: Number.isInteger(result?.error?.column) ? result.error.column : null,
      snippet_head: item.snippet.slice(0, 200).replace(/\n/g, "\\n"),
    });
  }

  const output = {
    ok: true,
    upstream_root: UPSTREAM_ROOT,
    file_count: files.length,
    snippet_count: snippets.length,
    imported: okCount,
    failed: failCount,
    by_kind: Object.fromEntries(byKind),
    failures: options.showAllFailures ? failures : failures.slice(0, 30),
    failure_truncated: !options.showAllFailures && failures.length > 30,
  };
  console.log(JSON.stringify(output, null, 2));
}

await main();
