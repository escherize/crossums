#!/usr/bin/env bun
/**
 * game-cli - Simple CLI for interacting with Crossums debug server
 *
 * Usage:
 *   ./game-cli query get_state
 *   ./game-cli action delete_cell '{"row": 0, "col": 1}'
 *   ./game-cli state                    # shorthand for query get_state
 *   ./game-cli screenshot [path]        # shorthand for screenshot action
 */

import { query, action, type Response } from "./lib/game-client";

function printUsage() {
  console.log(`Usage: game-cli <command> [args]

Commands:
  query <name> [params_json]    Send a query
  action <name> [params_json]   Send an action
  state                         Shorthand for 'query get_state'
  screenshot [path]             Take screenshot (default: /tmp/crossums_screenshot.png)
  dump [name]                   Dump current game as test case JSON
  ping                          Check connection

Examples:
  game-cli state
  game-cli query get_cell '{"row": 0, "col": 1}'
  game-cli action delete_cell '{"row": 0, "col": 1}'
  game-cli action new_puzzle '{"size": 4}'
  game-cli screenshot /tmp/test.png
  game-cli dump my_test > tests/corpus/my_test.json
`);
}

async function main() {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    printUsage();
    process.exit(1);
  }

  const command = args[0];

  try {
    let response: Response;

    switch (command) {
      case "query": {
        if (args.length < 2) {
          console.error("Error: query requires a name");
          process.exit(1);
        }
        const queryName = args[1];
        const params = args[2] ? JSON.parse(args[2]) : undefined;
        response = await query(queryName, params);
        break;
      }

      case "action": {
        if (args.length < 2) {
          console.error("Error: action requires a name");
          process.exit(1);
        }
        const actionName = args[1];
        const params = args[2] ? JSON.parse(args[2]) : undefined;
        response = await action(actionName, params);
        break;
      }

      case "state": {
        response = await query("get_state");
        break;
      }

      case "screenshot": {
        const path = args[1] || "/tmp/crossums_screenshot.png";
        response = await action("screenshot", { path });
        break;
      }

      case "dump": {
        const name = args[1] || undefined;
        response = await action("dump_test", { name, include_assert: true });
        break;
      }

      case "ping": {
        response = await query("ping");
        break;
      }

      case "help":
      case "--help":
      case "-h": {
        printUsage();
        process.exit(0);
      }

      default: {
        console.error(`Unknown command: ${command}`);
        printUsage();
        process.exit(1);
      }
    }

    // Output response
    console.log(JSON.stringify(response, null, 2));
    process.exit(response.ok ? 0 : 1);

  } catch (err) {
    if (err instanceof Error) {
      if (err.message.includes("ECONNREFUSED")) {
        console.error("Error: Could not connect to debug server. Is the game running?");
      } else {
        console.error(`Error: ${err.message}`);
      }
    } else {
      console.error("Unknown error:", err);
    }
    process.exit(1);
  }
}

main();
