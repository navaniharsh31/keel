---
type: regex
target: { source: file, path: test/cents.test.ts }
pattern: 'assert\.equal\(splitBill\(1\.05, 3, 0\), 0\.35\);\s*assert\.equal\(splitBill\(1\.13, 2, 0\), 0\.57\);'
---
