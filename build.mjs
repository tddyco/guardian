#!/usr/bin/env node

import { readFileSync, writeFileSync } from "fs";
import { dirname, join } from "path";
import { fileURLToPath } from "url";

const root = dirname(fileURLToPath(import.meta.url));
const policyPath = join(root, "claude", "policy.md");
const hooksPath = join(root, "claude", "hooks", "hooks.json");

const policy = readFileSync(policyPath, "utf-8").trimEnd();
const hooks = JSON.parse(readFileSync(hooksPath, "utf-8"));
const promptText = policy + "\n\n## Evaluate this tool call:\n\n$ARGUMENTS";

for (const hookGroup of hooks.hooks.PreToolUse ?? []) {
  for (const hook of hookGroup.hooks ?? []) {
    if ("prompt" in hook) {
      hook.prompt = promptText;
    }
  }
}

writeFileSync(hooksPath, JSON.stringify(hooks, null, 2) + "\n");
console.log(`updated ${hooksPath}`);
