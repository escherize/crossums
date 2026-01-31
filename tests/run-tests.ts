#!/usr/bin/env bun
/**
 * Test runner for Crossums puzzle mechanics
 *
 * Usage:
 *   bun tests/run-tests.ts                  # Run all tests (lint + logic + visual)
 *   bun tests/run-tests.ts basic_solve      # Run tests matching filter
 *   bun tests/run-tests.ts --lint-only      # Only run gdlint
 *   bun tests/run-tests.ts --no-lint        # Skip gdlint, run all tests
 *   bun tests/run-tests.ts --logic-only     # Only run logic tests (no visual)
 *   bun tests/run-tests.ts --visual-only    # Only run visual tests
 *
 * Rubric:
 *   - After editing .gd files: --lint-only (fast, catches syntax/style)
 *   - After logic changes: --logic-only (medium, tests game mechanics)
 *   - After UI/layout changes: --visual-only (slow, catches visual regressions)
 *   - Before commit: (no flags) full suite
 */

import { spawn, spawnSync, type Subprocess } from "bun";
import { readdirSync, readFileSync, existsSync } from "fs";
import { join, basename } from "path";
import { action, waitForServer, type Response } from "../lib/game-client";
import { compareScreenshot, BASELINE_DIR, DIFF_DIR } from "../lib/visual-compare";

// Test case schema
interface TestStep {
  action?: string;
  assert?: string;
  visual?: string;  // Visual regression test name (compares screenshot to baseline)
  params?: Record<string, unknown>;
  expect?: Record<string, unknown>;  // Expected fields in response (exact match)
  expect_nested?: Record<string, unknown>;  // Expected nested fields (dot notation: "run.stage")
  expect_gt?: Record<string, number>;  // Expected fields greater than value
  expect_error?: string;  // Expected error code (action should fail)
  threshold?: number;  // Visual comparison threshold (0-1, default 0.1)
  max_diff_pixels?: number;  // Max allowed pixel difference (default 0)
}

interface BoardState {
  size: number;
  seed: number;
  row_targets: number[];
  col_targets: number[];
  cells: { value: number; is_solution: boolean }[][];
}

interface TestCase {
  name: string;
  description?: string;
  setup: {
    action?: string;  // "new_puzzle" (default) or "start_run"
    size?: number;
    seed?: number;
    start_board?: BoardState;  // Deterministic board state (overrides seed)
  };
  steps: TestStep[];
}

interface TestResult {
  name: string;
  passed: boolean;
  error?: string;
  failedStep?: number;
  newBaselines?: string[];  // Visual baselines created during this test
}

const CORPUS_DIR = join(import.meta.dir, "corpus");
const GODOT_PROJECT = join(import.meta.dir, "..", "godot_app");
const GDLINT_PATH = join(process.env.HOME || "", "Library/Python/3.9/bin/gdlint");

// Helper to get nested value using dot notation (e.g., "run.stage")
function getNestedValue(obj: unknown, path: string): unknown {
  const parts = path.split(".");
  let current: unknown = obj;
  for (const part of parts) {
    if (current === null || current === undefined) return undefined;
    current = (current as Record<string, unknown>)[part];
  }
  return current;
}

let godotProcess: Subprocess | null = null;

async function startGodot(): Promise<boolean> {
  console.log("Starting Godot...");

  godotProcess = spawn(["godot", "--path", GODOT_PROJECT], {
    stdout: "ignore",
    stderr: "ignore",
  });

  // Wait for server to be ready
  const ready = await waitForServer({ maxAttempts: 50, delayMs: 200 });
  if (!ready) {
    console.error("Failed to connect to Godot debug server");
    return false;
  }

  console.log("Godot ready\n");
  return true;
}

function stopGodot(): void {
  if (godotProcess) {
    godotProcess.kill();
    godotProcess = null;
  }
}

async function runTest(test: TestCase): Promise<TestResult> {
  const result: TestResult = { name: test.name, passed: true, newBaselines: [] };

  try {
    // Setup: create new puzzle or start run
    const setupAction = test.setup.action || "new_puzzle";
    let setupResponse: Response;

    // Use start_board for deterministic setup if available
    if (test.setup.start_board && setupAction === "new_puzzle") {
      setupResponse = await action("load_board", test.setup.start_board);
    } else {
      const setupParams: Record<string, unknown> = {};
      if (test.setup.size) setupParams.size = test.setup.size;
      if (test.setup.seed) setupParams.seed = test.setup.seed;
      setupResponse = await action(setupAction, setupParams);
    }

    if (!setupResponse.ok) {
      result.passed = false;
      result.error = `Setup failed: ${setupResponse.message || "unknown error"}`;
      return result;
    }

    // Run steps
    for (let i = 0; i < test.steps.length; i++) {
      const step = test.steps[i];
      let response: Response;

      if (step.action) {
        response = await action(step.action, step.params);

        // Check for expected error
        if (step.expect_error) {
          if (response.ok) {
            result.passed = false;
            result.error = `Action '${step.action}' should have failed with '${step.expect_error}' but succeeded`;
            result.failedStep = i;
            return result;
          }
          if (response.error !== step.expect_error) {
            result.passed = false;
            result.error = `Action '${step.action}' failed with '${response.error}' but expected '${step.expect_error}'`;
            result.failedStep = i;
            return result;
          }
          // Expected error occurred, continue
          continue;
        }

        if (!response.ok) {
          result.passed = false;
          result.error = `Action '${step.action}' failed: ${response.message || response.error || "unknown"}`;
          result.failedStep = i;
          return result;
        }

        // Check expected fields (exact match)
        if (step.expect) {
          for (const [key, expectedValue] of Object.entries(step.expect)) {
            const actualValue = (response as Record<string, unknown>)[key];
            if (actualValue !== expectedValue) {
              result.passed = false;
              result.error = `Action '${step.action}' returned ${key}=${JSON.stringify(actualValue)}, expected ${JSON.stringify(expectedValue)}`;
              result.failedStep = i;
              return result;
            }
          }
        }

        // Check expected fields (greater than)
        if (step.expect_gt) {
          for (const [key, minValue] of Object.entries(step.expect_gt)) {
            const actualValue = (response as Record<string, unknown>)[key] as number;
            if (typeof actualValue !== 'number' || actualValue <= minValue) {
              result.passed = false;
              result.error = `Action '${step.action}' returned ${key}=${actualValue}, expected > ${minValue}`;
              result.failedStep = i;
              return result;
            }
          }
        }

        // Check nested expected fields (dot notation: "run.stage")
        if (step.expect_nested) {
          for (const [path, expectedValue] of Object.entries(step.expect_nested)) {
            const actualValue = getNestedValue(response, path);
            if (actualValue !== expectedValue) {
              result.passed = false;
              result.error = `Action '${step.action}' returned ${path}=${JSON.stringify(actualValue)}, expected ${JSON.stringify(expectedValue)}`;
              result.failedStep = i;
              return result;
            }
          }
        }
      } else if (step.assert) {
        response = await action(step.assert, step.params);
        if (!response.pass) {
          result.passed = false;
          result.error = `Assertion '${step.assert}' failed: ${response.message || "assertion returned false"}`;
          result.failedStep = i;
          return result;
        }
      } else if (step.visual) {
        // Visual regression test: take screenshot and compare to baseline
        const screenshotPath = `/tmp/crossums_visual_${step.visual}_${Date.now()}.png`;
        response = await action("screenshot", { path: screenshotPath });
        if (!response.ok) {
          result.passed = false;
          result.error = `Visual test '${step.visual}' failed to capture screenshot: ${response.message || response.error}`;
          result.failedStep = i;
          return result;
        }

        const compareResult = compareScreenshot(step.visual, screenshotPath, {
          threshold: step.threshold,
          maxDiffPixels: step.max_diff_pixels,
        });

        if (compareResult.isNewBaseline) {
          result.newBaselines!.push(step.visual);
        } else if (!compareResult.match) {
          result.passed = false;
          result.error = `Visual test '${step.visual}' failed: ${compareResult.diffPixels} pixels differ (${compareResult.diffPercent.toFixed(2)}%). See: ${compareResult.diffPath}`;
          result.failedStep = i;
          return result;
        }
      }
    }
  } catch (err) {
    result.passed = false;
    result.error = err instanceof Error ? err.message : String(err);
  }

  return result;
}

function runGdlint(): boolean {
  if (!existsSync(GDLINT_PATH)) {
    console.log("gdlint not found, skipping lint check\n");
    return true;
  }

  process.stdout.write("Running gdlint... ");

  // Use shell to expand glob pattern
  const result = spawnSync(["sh", "-c", `${GDLINT_PATH} **/*.gd`], {
    cwd: GODOT_PROJECT,
    stdout: "pipe",
    stderr: "pipe",
  });

  if (result.exitCode === 0) {
    console.log("✓\n");
    return true;
  } else {
    console.log("✗\n");
    console.log(result.stdout.toString());
    console.log(result.stderr.toString());
    return false;
  }
}

interface TestFilter {
  nameFilter?: string;
  visualOnly?: boolean;
  logicOnly?: boolean;
}

function isVisualTest(test: TestCase): boolean {
  return test.steps.some(step => step.visual !== undefined);
}

function loadTestCases(filter: TestFilter): TestCase[] {
  const files = readdirSync(CORPUS_DIR).filter((f) => f.endsWith(".json"));
  const tests: TestCase[] = [];

  for (const file of files) {
    const name = basename(file, ".json");
    if (filter.nameFilter && !name.includes(filter.nameFilter)) continue;

    const content = readFileSync(join(CORPUS_DIR, file), "utf-8");
    const test = JSON.parse(content) as TestCase;
    test.name = test.name || name;

    // Filter by test type
    const isVisual = isVisualTest(test);
    if (filter.visualOnly && !isVisual) continue;
    if (filter.logicOnly && isVisual) continue;

    tests.push(test);
  }

  return tests;
}

async function main() {
  // Parse arguments
  const args = process.argv.slice(2);
  const flags = {
    lintOnly: args.includes("--lint-only"),
    noLint: args.includes("--no-lint"),
    visualOnly: args.includes("--visual-only"),
    logicOnly: args.includes("--logic-only"),
  };
  const nameFilter = args.find(a => !a.startsWith("--"));

  // Run gdlint (unless skipped)
  if (!flags.noLint) {
    if (!runGdlint()) {
      process.exit(1);
    }
  }

  // Exit early if lint-only
  if (flags.lintOnly) {
    process.exit(0);
  }

  // Load test cases
  const tests = loadTestCases({
    nameFilter,
    visualOnly: flags.visualOnly,
    logicOnly: flags.logicOnly,
  });
  if (tests.length === 0) {
    console.error("No test cases found");
    process.exit(1);
  }

  const testType = flags.visualOnly ? "visual " : flags.logicOnly ? "logic " : "";
  console.log(`Found ${tests.length} ${testType}test(s)\n`);

  // Start Godot
  if (!(await startGodot())) {
    process.exit(1);
  }

  // Run tests
  const results: TestResult[] = [];
  let passed = 0;
  let failed = 0;
  let newBaselinesTotal = 0;

  for (const test of tests) {
    process.stdout.write(`  ${test.name}... `);
    const result = await runTest(test);
    results.push(result);

    if (result.passed) {
      const baselineInfo = result.newBaselines?.length
        ? ` (${result.newBaselines.length} new baseline${result.newBaselines.length > 1 ? 's' : ''})`
        : '';
      console.log(`✓${baselineInfo}`);
      newBaselinesTotal += result.newBaselines?.length || 0;
      passed++;
    } else {
      console.log("✗");
      console.log(`    ${result.error}`);
      if (result.failedStep !== undefined) {
        console.log(`    Failed at step ${result.failedStep}`);
      }
      failed++;
    }
  }

  // Summary
  let summary = `\n${passed} passed, ${failed} failed`;
  if (newBaselinesTotal > 0) {
    summary += ` (${newBaselinesTotal} new visual baseline${newBaselinesTotal > 1 ? 's' : ''} created)`;
  }
  console.log(summary);

  // Cleanup
  stopGodot();

  process.exit(failed > 0 ? 1 : 0);
}

// Handle cleanup on exit
process.on("SIGINT", () => {
  stopGodot();
  process.exit(1);
});

process.on("SIGTERM", () => {
  stopGodot();
  process.exit(1);
});

main();
