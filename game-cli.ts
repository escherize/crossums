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

import { connect, Socket } from "net";
import { randomUUID } from "crypto";

const HOST = "127.0.0.1";
const PORT = 9999;
const TIMEOUT_MS = 5000;

interface Message {
  id: string;
  type: "query" | "action";
  query?: string;
  action?: string;
  params?: Record<string, unknown>;
}

interface Response {
  id: string;
  ok: boolean;
  [key: string]: unknown;
}

function sendMessage(msg: Message): Promise<Response> {
  return new Promise((resolve, reject) => {
    const socket: Socket = connect(PORT, HOST);
    let buffer = "";

    const timeout = setTimeout(() => {
      socket.destroy();
      reject(new Error(`Timeout after ${TIMEOUT_MS}ms`));
    }, TIMEOUT_MS);

    socket.on("connect", () => {
      socket.write(JSON.stringify(msg) + "\n");
    });

    socket.on("data", (data) => {
      buffer += data.toString();
      const newlineIdx = buffer.indexOf("\n");
      if (newlineIdx !== -1) {
        clearTimeout(timeout);
        let jsonStr = buffer.slice(0, newlineIdx);
        // Handle potential garbage bytes before JSON (Godot StreamPeerTCP quirk)
        const jsonStart = jsonStr.indexOf("{");
        if (jsonStart > 0) {
          jsonStr = jsonStr.slice(jsonStart);
        }
        socket.end();
        try {
          resolve(JSON.parse(jsonStr));
        } catch (e) {
          reject(new Error(`Invalid JSON response: ${jsonStr}`));
        }
      }
    });

    socket.on("error", (err) => {
      clearTimeout(timeout);
      reject(err);
    });

    socket.on("close", () => {
      clearTimeout(timeout);
      if (buffer && !buffer.includes("\n")) {
        // Got data but no newline - try to parse anyway
        try {
          resolve(JSON.parse(buffer));
        } catch {
          reject(new Error(`Connection closed. Buffer: ${buffer}`));
        }
      }
    });
  });
}

async function query(queryName: string, params?: Record<string, unknown>): Promise<Response> {
  const msg: Message = {
    id: randomUUID(),
    type: "query",
    query: queryName,
  };
  if (params) msg.params = params;
  return sendMessage(msg);
}

async function action(actionName: string, params?: Record<string, unknown>): Promise<Response> {
  const msg: Message = {
    id: randomUUID(),
    type: "action",
    action: actionName,
  };
  if (params) msg.params = params;
  return sendMessage(msg);
}

function printUsage() {
  console.log(`Usage: game-cli <command> [args]

Commands:
  query <name> [params_json]    Send a query
  action <name> [params_json]   Send an action
  state                         Shorthand for 'query get_state'
  screenshot [path]             Take screenshot (default: /tmp/crossums_screenshot.png)
  ping                          Check connection

Examples:
  game-cli state
  game-cli query get_cell '{"row": 0, "col": 1}'
  game-cli action delete_cell '{"row": 0, "col": 1}'
  game-cli action new_puzzle '{"size": 4}'
  game-cli screenshot /tmp/test.png
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
