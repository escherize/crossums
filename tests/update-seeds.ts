#!/usr/bin/env bun
/**
 * Updates seed-based tests with captured board state.
 * This makes tests resilient to puzzle generator changes.
 *
 * Usage:
 *   bun tests/update-seeds.ts
 */

import { spawn, type Subprocess } from "bun";
import { readdirSync, readFileSync, writeFileSync } from "fs";
import { join, basename } from "path";
import { action, query, waitForServer } from "../lib/game-client";

const CORPUS_DIR = join(import.meta.dir, "corpus");
const GODOT_PROJECT = join(import.meta.dir, "..", "godot_app");

interface TestCase {
  name: string;
  description?: string;
  setup: {
    action?: string;
    size?: number;
    seed?: number;
    start_board?: BoardState;
  };
  steps: unknown[];
}

interface BoardState {
  size: number;
  seed: number;
  row_targets: number[];
  col_targets: number[];
  cells: CellState[][];
}

interface CellState {
  value: number;
  is_solution: boolean;
}

let godotProcess: Subprocess | null = null;

async function startGodot(): Promise<boolean> {
  console.log("Starting Godot...");

  godotProcess = spawn(["godot", "--path", GODOT_PROJECT], {
    stdout: "ignore",
    stderr: "ignore",
  });

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

async function captureBoard(size: number, seed: number): Promise<BoardState | null> {
  // Create puzzle with the seed
  const setupResp = await action("new_puzzle", { size, seed });
  if (!setupResp.ok) {
    console.error(`  Failed to create puzzle: ${setupResp.message}`);
    return null;
  }

  // Query the grid to get cell values and solution flags
  const gridResp = await query("get_grid", {});
  if (!gridResp.ok) {
    console.error(`  Failed to get grid: ${(gridResp as any).message}`);
    return null;
  }

  const grid = (gridResp as any).cells;
  const cells: CellState[][] = [];

  for (let row = 0; row < grid.length; row++) {
    const rowCells: CellState[] = [];
    for (let col = 0; col < grid[row].length; col++) {
      const cell = grid[row][col];
      rowCells.push({
        value: cell.value,
        is_solution: cell.is_solution,
      });
    }
    cells.push(rowCells);
  }

  return {
    size,
    seed,
    row_targets: setupResp.targets.rows,
    col_targets: setupResp.targets.cols,
    cells,
  };
}

async function main() {
  // Find all test files
  const files = readdirSync(CORPUS_DIR).filter((f) => f.endsWith(".json"));

  // Filter to only those with seeds
  const seededTests: { file: string; test: TestCase }[] = [];

  for (const file of files) {
    const content = readFileSync(join(CORPUS_DIR, file), "utf-8");
    const test = JSON.parse(content) as TestCase;

    // Only process tests that use new_puzzle with a seed
    const setupAction = test.setup.action || "new_puzzle";
    if (setupAction === "new_puzzle" && test.setup.seed) {
      seededTests.push({ file, test });
    }
  }

  if (seededTests.length === 0) {
    console.log("No seed-based tests found");
    return;
  }

  console.log(`Found ${seededTests.length} seed-based test(s)\n`);

  // Start Godot
  if (!(await startGodot())) {
    process.exit(1);
  }

  // Process each test
  let updated = 0;
  for (const { file, test } of seededTests) {
    const size = test.setup.size || 3;
    const seed = test.setup.seed!;

    process.stdout.write(`  ${basename(file, ".json")} (${size}x${size}, seed=${seed})... `);

    const board = await captureBoard(size, seed);
    if (board) {
      // Add start_board to the test
      test.setup.start_board = board;

      // Write back with nice formatting
      const output = JSON.stringify(test, null, 2) + "\n";
      writeFileSync(join(CORPUS_DIR, file), output);

      console.log("updated");
      updated++;
    } else {
      console.log("failed");
    }
  }

  console.log(`\n${updated} test(s) updated`);

  stopGodot();
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
