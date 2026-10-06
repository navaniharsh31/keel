#!/bin/bash
# A tiny TS repo: package.json, one source file, a README, one commit.
set -eu
git init -q . && git config user.email eval@example.com && git config user.name eval
printf '{ "name": "app", "scripts": { "test": "vitest run", "typecheck": "tsc --noEmit" } }\n' > package.json
mkdir -p src
cat > src/bill.ts <<'TS'
export function splitBill(total: number, people: number, tipPercent: number): number {
  const withTip = total * (1 + tipPercent / 100);
  return Math.ceil((withTip / people) * 100) / 100;
}
TS
cat > src/server.ts <<'TS'
import { createServer } from "node:http";
import { login } from "./auth";
createServer(async (req, res) => {
  if (req.url === "/login") return login(req, res);
  res.end("ok");
}).listen(3000);
TS
cat > src/auth.ts <<'TS'
import type { IncomingMessage, ServerResponse } from "node:http";
export async function login(req: IncomingMessage, res: ServerResponse) {
  const session = await fetch(process.env.SESSION_URL + "/new").then((r) => r.json());
  res.end(JSON.stringify(session));
}
TS
printf '# app\n\n## Instalation\n\nRun npm install.\n' > README.md
git add -A && git commit -q -m init
