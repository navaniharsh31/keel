#!/bin/bash
# The checkout app at an inline build's Finish: feat/format-money reviewed, every finding fixed in the ledger, retro done.
set -eu
BASE_DATE="1791818000 +0530"
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
git checkout -q -b feat/format-money
cat > src/money.ts <<'TS'
export function formatMoney(cents: number): string {
  return "$" + (cents / 100).toFixed(2);
}
TS
cat > test/money.test.ts <<'TS'
import { test } from "node:test";
import assert from "node:assert/strict";
import { formatMoney } from "../src/money.ts";

test("formats cents as dollars", () => {
  assert.equal(formatMoney(1234), "$12.34");
});

test("pads whole dollars", () => {
  assert.equal(formatMoney(500), "$5.00");
});
TS
git add src/money.ts test/money.test.ts
GIT_AUTHOR_DATE="1791818100 +0530" GIT_COMMITTER_DATE="1791818100 +0530" git commit -q -m "feat(format-money): formatMoney helper"
cat > src/money.ts <<'TS'
const CENTS_PER_DOLLAR = 100;

export function formatMoney(cents: number): string {
  const sign = cents < 0 ? "-" : "";
  return sign + "$" + (Math.abs(cents) / CENTS_PER_DOLLAR).toFixed(2);
}
TS
cat >> test/money.test.ts <<'TS'

test("puts the sign before the dollar sign", () => {
  assert.equal(formatMoney(-150), "-$1.50");
});
TS
git add src/money.ts test/money.test.ts
GIT_AUTHOR_DATE="1791818200 +0530" GIT_COMMITTER_DATE="1791818200 +0530" git commit -q -m "fix(format-money): review findings"
base=$(git rev-parse --short main); feat=$(git rev-parse --short HEAD~1); fix=$(git rev-parse --short HEAD)
ledger="$(git rev-parse --git-common-dir)/keel/feat/format-money"
mkdir -p "$(dirname "$ledger")"
cat > "$ledger" <<LEDGER
created $base
review $feat: Standards 1 finding (worst: S1 magic number 100); Spec 1 finding (worst: P1 a negative amount prints as \$-1.50); code review 0 findings
finding S1: magic number 100 in formatMoney
finding P1: a negative amount prints as \$-1.50, not -\$1.50
S1 fixed: $fix
P1 fixed: $fix
LEDGER
