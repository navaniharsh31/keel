// keel router for OpenCode: runs keel's session-start.sh and appends its output
// (flow.md plus any "In flight:" line) to the system prompt of every request.
// Works on OpenCode 1.x (named export, experimental.chat.system.transform) and
// 2.x (default export with setup, session "context" hook).
import { execFileSync } from "node:child_process";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const router = join(dirname(fileURLToPath(import.meta.url)), "keel", "hooks", "session-start.sh");

function routerText(directory) {
  try {
    return execFileSync("sh", [router], {
      cwd: directory,
      env: { ...process.env, CLAUDE_PROJECT_DIR: directory },
      encoding: "utf8",
      timeout: 5000,
    }).trim();
  } catch {
    return ""; // A router failure must never break a session.
  }
}

// OpenCode 1.x
export const KeelPlugin = async ({ directory }) => ({
  "experimental.chat.system.transform": async (_input, output) => {
    const text = routerText(directory);
    if (text) output.system.push(text);
  },
});

// OpenCode 2.x
export default {
  id: "keel",
  server: KeelPlugin,
  setup: async (ctx) => {
    const directory = ctx.location?.directory ?? process.cwd();
    const registration = await ctx.session.hook("context", async (event) => {
      const text = routerText(directory);
      if (text && Array.isArray(event.system)) event.system = [...event.system, { type: "text", text }];
    });
    return async () => registration.dispose();
  },
};
