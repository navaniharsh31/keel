#!/bin/bash
# The checkout app at an inline build's Fix step: feat/cart-total reviewed, three findings and a residual risk, none dispositioned.
set -eu
BASE_DATE="1791819000 +0530"
# A tiny TS checkout app: tests run with node's built-in runner (node 22.18+ strips types).
# The git dir sits at .repo-git (git-common-dir), not .git: the eval sandbox denies shell writes to a literal .git/ path.
git init -q -b main --separate-git-dir .repo-git . && echo "/.repo-git/" >> .repo-git/info/exclude && git config user.email eval@example.com && git config user.name eval
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
git checkout -q -b feat/cart-total
cat > src/cart.ts <<'TS'
export type Item = { price: number; qty: number };

export function cartTotal(items: Item[]): number {
  const sum = items.map((i) => i.price * i.qty).reduce((a, b) => a + b);
  return Math.round(sum * 100) / 100;
}
TS
cat > test/cart.test.ts <<'TS'
import { test } from "node:test";
import assert from "node:assert/strict";
import { cartTotal } from "../src/cart.ts";

test("sums price times quantity", () => {
  assert.equal(cartTotal([{ price: 2.5, qty: 2 }, { price: 1.25, qty: 4 }]), 10);
});
TS
git add src/cart.ts test/cart.test.ts
GIT_AUTHOR_DATE="1791819100 +0530" GIT_COMMITTER_DATE="1791819100 +0530" git commit -q -m "feat(cart-total): cartTotal"
ledger="$(git rev-parse --git-common-dir)/keel/feat/cart-total"
mkdir -p "$(dirname "$ledger")"
cat > "$ledger" <<LEDGER
created $(git rev-parse --short main)
review $(git rev-parse --short HEAD): Standards 1 finding (worst: S1 duplicated cents rounding); Spec 2 findings (worst: P1 a negative quantity is accepted); 1 residual risk
finding S1: cents rounding duplicated from src/coupon.ts and src/refund.ts
finding P1: a quantity below 1 is accepted instead of throwing a RangeError
finding P2: an empty cart throws a TypeError instead of totalling 0
LEDGER
