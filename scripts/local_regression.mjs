import { spawnSync } from "node:child_process";

const args = new Set(process.argv.slice(2));
const smokeOnly = args.has("--smoke-only");

const STEPS = smokeOnly
  ? [
      ["node", ["scripts/sync_parser_corpus_manifest.mjs"]],
      ["moon", ["build", "--release"]],
      ["node", ["browser_ui_upstream/tests/kwiver_bridge_smoke.test.mjs"]],
      ["node", ["browser_ui_upstream/tests/toolbar_update_fail_fast.test.mjs"]],
      ["node", ["browser_ui_upstream/tests/runtime_smoke_non_mock.test.mjs"]],
      ["node", ["browser_ui_upstream/tests/parser_corpus_runtime_non_mock.test.mjs"]],
    ]
  : [
      ["node", ["scripts/sync_parser_corpus_manifest.mjs"]],
      ["moon", ["build", "--release"]],
      ["moon", ["test", "-v"]],
      ["node", ["browser_ui_upstream/tests/kwiver_bridge_smoke.test.mjs"]],
      ["node", ["browser_ui_upstream/tests/toolbar_update_fail_fast.test.mjs"]],
      ["node", ["browser_ui_upstream/tests/runtime_smoke_non_mock.test.mjs"]],
      ["node", ["browser_ui_upstream/tests/parser_corpus_runtime_non_mock.test.mjs"]],
    ];

function runStep(command, commandArgs, index, total) {
  const pretty = [command, ...commandArgs].join(" ");
  console.log(`\n[${index}/${total}] ${pretty}`);
  const result = spawnSync(command, commandArgs, {
    stdio: "inherit",
    shell: false,
  });

  if (typeof result.status === "number" && result.status !== 0) {
    console.error(`\nfailed: ${pretty} (exit ${result.status})`);
    process.exit(result.status);
  }
  if (result.error) {
    console.error(`\nfailed: ${pretty}`);
    console.error(result.error.message);
    process.exit(1);
  }
}

function run() {
  const total = STEPS.length;
  for (let i = 0; i < STEPS.length; i += 1) {
    const [command, commandArgs] = STEPS[i];
    runStep(command, commandArgs, i + 1, total);
  }
  const mode = smokeOnly ? "smoke-only" : "full";
  console.log(`\nlocal regression passed (${mode})`);
}

run();
