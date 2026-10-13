---
type: regex
target: { source: file, path: .repo-git/keel/feat/cart-total }
pattern: '^(?!(?:S1|P1|P2) |created |review |finding (?:S1|P1|P2):)\S+'
flags: m
match: not_contains
---
