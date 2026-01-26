/**
 * Shared game client for communicating with Crossums debug server
 */

import { connect, Socket } from "net";
import { randomUUID } from "crypto";

export const DEFAULT_HOST = "127.0.0.1";
export const DEFAULT_PORT = 9999;
export const DEFAULT_TIMEOUT_MS = 5000;

export interface Message {
  id: string;
  type: "query" | "action";
  query?: string;
  action?: string;
  params?: Record<string, unknown>;
}

export interface Response {
  id: string;
  ok: boolean;
  pass?: boolean;
  error?: string;
  message?: string;
  [key: string]: unknown;
}

export interface ClientOptions {
  host?: string;
  port?: number;
  timeout?: number;
}

export function sendMessage(
  msg: Message,
  options: ClientOptions = {}
): Promise<Response> {
  const host = options.host ?? DEFAULT_HOST;
  const port = options.port ?? DEFAULT_PORT;
  const timeout = options.timeout ?? DEFAULT_TIMEOUT_MS;

  return new Promise((resolve, reject) => {
    const socket: Socket = connect(port, host);
    let buffer = "";

    const timer = setTimeout(() => {
      socket.destroy();
      reject(new Error(`Timeout after ${timeout}ms`));
    }, timeout);

    socket.on("connect", () => {
      socket.write(JSON.stringify(msg) + "\n");
    });

    socket.on("data", (data) => {
      buffer += data.toString();
      const newlineIdx = buffer.indexOf("\n");
      if (newlineIdx !== -1) {
        clearTimeout(timer);
        const rawStr = buffer.slice(0, newlineIdx);
        socket.end();

        // Handle potential garbage bytes before JSON (Godot StreamPeerTCP quirk)
        // Try parsing from each '{' until we find valid JSON
        let parsed: Response | null = null;
        let searchStart = 0;
        while (searchStart < rawStr.length) {
          const braceIdx = rawStr.indexOf("{", searchStart);
          if (braceIdx < 0) break;

          try {
            const candidate = rawStr.slice(braceIdx);
            parsed = JSON.parse(candidate);
            break;
          } catch {
            searchStart = braceIdx + 1;
          }
        }

        if (parsed) {
          resolve(parsed);
        } else {
          reject(new Error(`Invalid JSON response: ${rawStr}`));
        }
      }
    });

    socket.on("error", (err) => {
      clearTimeout(timer);
      reject(err);
    });

    socket.on("close", () => {
      clearTimeout(timer);
      if (buffer && !buffer.includes("\n")) {
        try {
          resolve(JSON.parse(buffer));
        } catch {
          reject(new Error(`Connection closed. Buffer: ${buffer}`));
        }
      }
    });
  });
}

export async function query(
  queryName: string,
  params?: Record<string, unknown>,
  options?: ClientOptions
): Promise<Response> {
  const msg: Message = {
    id: randomUUID(),
    type: "query",
    query: queryName,
  };
  if (params) msg.params = params;
  return sendMessage(msg, options);
}

export async function action(
  actionName: string,
  params?: Record<string, unknown>,
  options?: ClientOptions
): Promise<Response> {
  const msg: Message = {
    id: randomUUID(),
    type: "action",
    action: actionName,
  };
  if (params) msg.params = params;
  return sendMessage(msg, options);
}

/**
 * Wait for the debug server to be ready (ping loop)
 */
export async function waitForServer(
  options: ClientOptions & { maxAttempts?: number; delayMs?: number } = {}
): Promise<boolean> {
  const maxAttempts = options.maxAttempts ?? 30;
  const delayMs = options.delayMs ?? 200;

  for (let i = 0; i < maxAttempts; i++) {
    try {
      const response = await query("ping", undefined, { ...options, timeout: 1000 });
      if (response.ok) return true;
    } catch {
      // Server not ready yet
    }
    await new Promise((r) => setTimeout(r, delayMs));
  }
  return false;
}
