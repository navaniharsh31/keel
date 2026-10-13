#!/bin/bash
# The checkout app mid-debug: the loop (an untracked scratch test) is red, nothing minimised or fixed, nothing committed.
set -eu
BASE_DATE="1791816612 +0530"
# A tiny TS checkout app: tests run with node's built-in runner (node 22.18+ strips types).
git init -q -b main . && git config user.email eval@example.com && git config user.name eval
printf '{ "name": "app", "type": "module", "scripts": { "test": "node --test" } }\n' > package.json
printf '# app\n\nCheckout helpers. Run the tests with `npm test`.\n' > README.md
mkdir -p src test
cat > src/percent.ts <<'TS'
// Every percentage the app accepts goes through here.
export function clampPercent(p: number): number {
  if (!Number.isFinite(p)) throw new RangeError("percent must be a finite number");
  return Math.min(100, Math.max(0, p));
}
TS
cat > src/bill.ts <<'TS'
import { clampPercent } from "./percent.ts";

export function splitBill(total: number, people: number, tipPercent: number): number {
  const withTip = total * (1 + clampPercent(tipPercent) / 100);
  return Math.ceil((withTip / people) * 100) / 100;
}
TS
cat > src/coupon.ts <<'TS'
export function applyCoupon(total: number, percentOff: number): number {
  return Math.round(total * (1 - percentOff / 100) * 100) / 100;
}
TS
cat > src/refund.ts <<'TS'
export function refundAmount(paid: number, percent: number): number {
  return Math.round(paid * (percent / 100) * 100) / 100;
}
TS
cat > test/bill.test.ts <<'TS'
import { test } from "node:test";
import assert from "node:assert/strict";
import { splitBill } from "../src/bill.ts";

test("each share covers the bill", () => {
  assert.equal(splitBill(100, 3, 0), 33.34);
});

test("the tip is added before splitting", () => {
  assert.equal(splitBill(80, 4, 25), 25);
});
TS
cat > test/coupon.test.ts <<'TS'
import { test } from "node:test";
import assert from "node:assert/strict";
import { applyCoupon } from "../src/coupon.ts";

test("a coupon takes its percentage off", () => {
  assert.equal(applyCoupon(50, 10), 45);
});
TS
git add -A && GIT_AUTHOR_DATE="$BASE_DATE" GIT_COMMITTER_DATE="$BASE_DATE" git commit -q -m "init: checkout helpers"
mkdir -p scratch
cat > scratch/repro-coupon.test.ts <<'EOF_FILE'
import { test } from "node:test";
import assert from "node:assert/strict";
import { applyCoupon } from "../src/coupon.ts";

test("a 150% coupon never produces a negative total", () => {
  assert.ok(applyCoupon(100, 150) >= 0, `total was ${applyCoupon(100, 150)}`);
});
EOF_FILE
