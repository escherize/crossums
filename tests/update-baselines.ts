#!/usr/bin/env bun
/**
 * Update visual regression baselines
 *
 * Usage:
 *   bun tests/update-baselines.ts              # List all baselines
 *   bun tests/update-baselines.ts title_screen # Update specific baseline (requires running game)
 *   bun tests/update-baselines.ts --delete title_screen  # Delete a baseline
 */

import { existsSync, unlinkSync, readdirSync } from "fs";
import { join } from "path";
import { spawn, type Subprocess } from "bun";
import { action, waitForServer } from "../lib/game-client";
import { updateBaseline, listBaselines, BASELINE_DIR, DIFF_DIR } from "../lib/visual-compare";

const GODOT_PROJECT = join(import.meta.dir, "..", "godot_app");

let godotProcess: Subprocess | null = null;

function printUsage(): void {
  console.log(`
Visual Baseline Management

Usage:
  bun tests/update-baselines.ts                    List all baselines
  bun tests/update-baselines.ts <name>             Update baseline (starts game, takes screenshot)
  bun tests/update-baselines.ts --delete <name>    Delete a baseline
  bun tests/update-baselines.ts --clean-diffs      Remove all diff images

Examples:
  bun tests/update-baselines.ts title_screen
  bun tests/update-baselines.ts --delete old_test
`);
}

function listAllBaselines(): void {
  const baselines = listBaselines();
  if (baselines.length === 0) {
    console.log("No baselines found. Run tests with visual steps to create them.");
    return;
  }

  console.log(`Found ${baselines.length} baseline(s):\n`);
  for (const name of baselines.sort()) {
    console.log(`  ${name}`);
  }
}

function deleteBaseline(name: string): void {
  const baselinePath = join(BASELINE_DIR, `${name}.png`);
  const diffPath = join(DIFF_DIR, `${name}-diff.png`);

  if (!existsSync(baselinePath)) {
    console.error(`Baseline '${name}' not found`);
    process.exit(1);
  }

  unlinkSync(baselinePath);
  console.log(`Deleted baseline: ${name}`);

  if (existsSync(diffPath)) {
    unlinkSync(diffPath);
    console.log(`Deleted diff: ${name}-diff`);
  }
}

function cleanDiffs(): void {
  if (!existsSync(DIFF_DIR)) {
    console.log("No diffs directory found");
    return;
  }

  const files = readdirSync(DIFF_DIR).filter((f) => f.endsWith(".png"));
  if (files.length === 0) {
    console.log("No diff images found");
    return;
  }

  for (const file of files) {
    unlinkSync(join(DIFF_DIR, file));
  }
  console.log(`Cleaned ${files.length} diff image(s)`);
}

async function startGodot(): Promise<boolean> {
  console.log("Starting Godot...");

  godotProcess = spawn(["godot", "--path", GODOT_PROJECT], {
    stdout: "ignore",
    stderr: "ignore",
    env: {
      ...process.env,
      CS_DEBUG_SERVER: "1",  // Ensure test instance starts the TCP server
    },
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

async function updateBaselineInteractive(name: string): Promise<void> {
  // Start Godot
  if (!(await startGodot())) {
    process.exit(1);
  }

  try {
    // Take screenshot
    const screenshotPath = `/tmp/crossums_baseline_${name}_${Date.now()}.png`;
    console.log(`Taking screenshot for '${name}'...`);

    // Wait for any animations to settle
    await action("wait_idle");

    const response = await action("screenshot", { path: screenshotPath });
    if (!response.ok) {
      console.error(`Failed to capture screenshot: ${response.message || response.error}`);
      process.exit(1);
    }

    // Update baseline
    updateBaseline(name, screenshotPath);
    console.log(`Updated baseline: ${name}`);
    console.log(`Saved to: ${join(BASELINE_DIR, `${name}.png`)}`);
  } finally {
    stopGodot();
  }
}

async function main(): Promise<void> {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    listAllBaselines();
    return;
  }

  if (args[0] === "--help" || args[0] === "-h") {
    printUsage();
    return;
  }

  if (args[0] === "--delete") {
    if (!args[1]) {
      console.error("Usage: --delete <baseline_name>");
      process.exit(1);
    }
    deleteBaseline(args[1]);
    return;
  }

  if (args[0] === "--clean-diffs") {
    cleanDiffs();
    return;
  }

  // Update specific baseline
  await updateBaselineInteractive(args[0]);
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
