#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const blocked = [
  /require\([^)]*Alpaca/i,
  /import\s+.*Alpaca/i,
  /require\([^)]*MetaApi/i,
  /import\s+.*MetaTrader/i,
  /ALPACA_TRADING/i,
  /METAAPI_TOKEN/i,
  /broker[-_]?truth/i,
  /ValidationPortfolioRegistry/i,
  /AlpacaTradingExecution/i
];

const allowedTextFiles = new Set([
  'FINANCE_ISOLATION.md',
  'README.md',
  'backend/creature-server.cjs',
  'backend/README.md',
  'scripts/audit-finance-isolation.cjs'
]);

function walk(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  return entries.flatMap(entry => {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name === '.build' || entry.name === '.swiftpm') return [];
      return walk(full);
    }
    return [full];
  });
}

const violations = [];
for (const file of walk(root)) {
  const rel = path.relative(root, file);
  if (allowedTextFiles.has(rel)) continue;
  if (!/\.(swift|cjs|js|json|md|plist)$/.test(file)) continue;
  const source = fs.readFileSync(file, 'utf8');
  for (const pattern of blocked) {
    if (pattern.test(source)) {
      violations.push({ file: rel, pattern: pattern.toString() });
    }
  }
}

if (violations.length > 0) {
  console.error('Finance isolation audit failed:');
  for (const violation of violations) {
    console.error(`- ${violation.file}: ${violation.pattern}`);
  }
  process.exit(1);
}

console.log('Finance isolation audit passed.');
