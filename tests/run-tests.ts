#!/usr/bin/env bun
/**
 * Test runner for Crossums puzzle mechanics
 *
 * Usage:
 *   bun tests/run-tests.ts              # Run all tests
 *   bun tests/run-tests.ts basic_solve  # Run specific test
 */

import { spawn, spawnSync, type Subprocess } from "bun";
import { readdirSync, readFileSync, existsSync } from "fs";
import { join, basename } from "path";
import { action, waitForServer, type Response } from "../lib/game-client";

// Test case schema
interface TestStep {
  action?: string;
  assert?: string;
  params?: Record<string, unknown>;
  expect?: Record<string, unknown>;  // Expected fields in response (exact match)
  expect_nested?: Record<string, unknown>;  // Expected nested fields (dot notation: "run.stage")
  expect_gt?: Record<string, number>;  // Expected fields greater than value
  expect_error?: string;  // Expected error code (action should fail)
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
  const result: TestResult = { name: test.name, passed: true };

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

function loadTestCases(filter?: string): TestCase[] {
  const files = readdirSync(CORPUS_DIR).filter((f) => f.endsWith(".json"));
  const tests: TestCase[] = [];

  for (const file of files) {
    const name = basename(file, ".json");
    if (filter && !name.includes(filter)) continue;

    const content = readFileSync(join(CORPUS_DIR, file), "utf-8");
    const test = JSON.parse(content) as TestCase;
    test.name = test.name || name;
    tests.push(test);
  }

  return tests;
}

async function main() {
  const filter = process.argv[2];

  // Run gdlint first
  if (!runGdlint()) {
    process.exit(1);
  }

  // Load test cases
  const tests = loadTestCases(filter);
  if (tests.length === 0) {
    console.error("No test cases found");
    process.exit(1);
  }

  console.log(`Found ${tests.length} test(s)\n`);

  // Start Godot
  if (!(await startGodot())) {
    process.exit(1);
  }

  // Run tests
  const results: TestResult[] = [];
  let passed = 0;
  let failed = 0;

  for (const test of tests) {
    process.stdout.write(`  ${test.name}... `);
    const result = await runTest(test);
    results.push(result);

    if (result.passed) {
      console.log("✓");
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
  console.log(`\n${passed} passed, ${failed} failed`);

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
