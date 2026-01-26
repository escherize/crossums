#!/usr/bin/env bun
/**
 * Test runner for Crossums puzzle mechanics
 *
 * Usage:
 *   bun tests/run-tests.ts              # Run all tests
 *   bun tests/run-tests.ts basic_solve  # Run specific test
 */

import { spawn, type Subprocess } from "bun";
import { readdirSync, readFileSync } from "fs";
import { join, basename } from "path";
import { action, waitForServer, type Response } from "../lib/game-client";

// Test case schema
interface TestStep {
  action?: string;
  assert?: string;
  params?: Record<string, unknown>;
}

interface TestCase {
  name: string;
  description?: string;
  setup: {
    size?: number;
    seed?: number;
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
    // Setup: create new puzzle
    const setupParams: Record<string, unknown> = {};
    if (test.setup.size) setupParams.size = test.setup.size;
    if (test.setup.seed) setupParams.seed = test.setup.seed;

    const setupResponse = await action("new_puzzle", setupParams);
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
        if (!response.ok) {
          result.passed = false;
          result.error = `Action '${step.action}' failed: ${response.message || response.error || "unknown"}`;
          result.failedStep = i;
          return result;
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
