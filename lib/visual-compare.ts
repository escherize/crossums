/**
 * Visual regression testing using pixelmatch
 *
 * Compares screenshots against baselines and generates diff images on mismatch.
 */

import { PNG } from "pngjs";
import pixelmatch from "pixelmatch";
import { readFileSync, writeFileSync, existsSync, mkdirSync, copyFileSync } from "fs";
import { dirname, join } from "path";

const TESTS_DIR = join(import.meta.dir, "..", "tests");
export const BASELINE_DIR = join(TESTS_DIR, "baselines");
export const DIFF_DIR = join(TESTS_DIR, "diffs");

// Matching threshold: 0-1, lower = stricter. 0.1 is recommended default.
const DEFAULT_THRESHOLD = 0.1;

// Maximum allowed pixel difference before failing (0 = exact match required)
const DEFAULT_MAX_DIFF_PIXELS = 0;

export interface CompareOptions {
  threshold?: number;
  maxDiffPixels?: number;
}

export interface CompareResult {
  match: boolean;
  diffPixels: number;
  totalPixels: number;
  diffPercent: number;
  baselinePath: string;
  diffPath?: string;
  isNewBaseline: boolean;
}

/**
 * Ensure directories exist
 */
function ensureDir(dir: string): void {
  if (!existsSync(dir)) {
    mkdirSync(dir, { recursive: true });
  }
}

/**
 * Compare a screenshot against its baseline.
 *
 * - If no baseline exists, saves the screenshot as the new baseline.
 * - If baseline exists, compares and generates a diff image on mismatch.
 *
 * @param name - Baseline name (e.g., "title_screen", "puzzle_solved")
 * @param actualPath - Path to the screenshot to compare
 * @param options - Comparison options
 */
export function compareScreenshot(
  name: string,
  actualPath: string,
  options: CompareOptions = {}
): CompareResult {
  const threshold = options.threshold ?? DEFAULT_THRESHOLD;
  const maxDiffPixels = options.maxDiffPixels ?? DEFAULT_MAX_DIFF_PIXELS;

  ensureDir(BASELINE_DIR);
  ensureDir(DIFF_DIR);

  const baselinePath = join(BASELINE_DIR, `${name}.png`);
  const diffPath = join(DIFF_DIR, `${name}-diff.png`);

  // First run: save as baseline
  if (!existsSync(baselinePath)) {
    copyFileSync(actualPath, baselinePath);
    const img = PNG.sync.read(readFileSync(actualPath));
    return {
      match: true,
      diffPixels: 0,
      totalPixels: img.width * img.height,
      diffPercent: 0,
      baselinePath,
      isNewBaseline: true,
    };
  }

  // Load images
  const baseline = PNG.sync.read(readFileSync(baselinePath));
  const actual = PNG.sync.read(readFileSync(actualPath));

  // Check dimensions match
  if (baseline.width !== actual.width || baseline.height !== actual.height) {
    // Save the actual as diff for inspection
    copyFileSync(actualPath, diffPath);
    const totalPixels = Math.max(
      baseline.width * baseline.height,
      actual.width * actual.height
    );
    return {
      match: false,
      diffPixels: totalPixels, // All pixels are "different" due to size mismatch
      totalPixels,
      diffPercent: 100,
      baselinePath,
      diffPath,
      isNewBaseline: false,
    };
  }

  const { width, height } = baseline;
  const totalPixels = width * height;
  const diff = new PNG({ width, height });

  // Compare
  const diffPixels = pixelmatch(
    baseline.data,
    actual.data,
    diff.data,
    width,
    height,
    {
      threshold,
      includeAA: false, // Ignore anti-aliasing differences
      alpha: 0.1, // Blend unchanged pixels at 10% brightness
      diffColor: [255, 0, 0], // Red for differences
      diffColorAlt: [0, 255, 0], // Green for anti-aliased differences
    }
  );

  const diffPercent = (diffPixels / totalPixels) * 100;
  const match = diffPixels <= maxDiffPixels;

  // Save diff image if there are differences
  if (diffPixels > 0) {
    writeFileSync(diffPath, PNG.sync.write(diff));
  }

  return {
    match,
    diffPixels,
    totalPixels,
    diffPercent,
    baselinePath,
    diffPath: diffPixels > 0 ? diffPath : undefined,
    isNewBaseline: false,
  };
}

/**
 * Update a baseline with a new screenshot
 */
export function updateBaseline(name: string, screenshotPath: string): void {
  ensureDir(BASELINE_DIR);
  const baselinePath = join(BASELINE_DIR, `${name}.png`);
  copyFileSync(screenshotPath, baselinePath);

  // Clean up any existing diff
  const diffPath = join(DIFF_DIR, `${name}-diff.png`);
  if (existsSync(diffPath)) {
    const { unlinkSync } = require("fs");
    unlinkSync(diffPath);
  }
}

/**
 * List all baseline names
 */
export function listBaselines(): string[] {
  if (!existsSync(BASELINE_DIR)) return [];

  const { readdirSync } = require("fs");
  return readdirSync(BASELINE_DIR)
    .filter((f: string) => f.endsWith(".png"))
    .map((f: string) => f.replace(/\.png$/, ""));
}
