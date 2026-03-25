#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
POLICY="$SCRIPT_DIR/../policy.md"
INPUT=$(cat)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

# Only review Bash commands
if [ "$TOOL_NAME" != "Bash" ] || [ -z "$COMMAND" ]; then
  exit 0
fi

SCHEMA='{"type":"object","properties":{"ok":{"type":"boolean"},"reason":{"type":"string"}},"required":["ok"]}'

RESPONSE=$(printf 'Evaluate this command:\nTool: %s\nCommand: %s\nWorking directory: %s' \
  "$TOOL_NAME" "$COMMAND" "$CWD" | \
  claude -p \
    --model sonnet \
    --system-prompt-file "$POLICY" \
    --output-format json \
    --json-schema "$SCHEMA" \
    --tools "Read" \
    --no-session-persistence \
    --no-chrome \
    --disable-slash-commands \
    --setting-sources "" \
    --settings '{"disableAllHooks":true}' \
    --strict-mcp-config \
    --mcp-config '{"mcpServers":{}}' \
    --permission-mode dontAsk \
  2>/dev/null) || {
  # TODO: replace the above flags with --bare once it supports OAuth
  # API error or timeout → fail open (show normal approval prompt)
  exit 0
}

# Parse the result — structured output is at .structured_output
OK=$(echo "$RESPONSE" | jq -r '.structured_output.ok // false')

if [ "$OK" = "true" ]; then
  REASON=$(echo "$RESPONSE" | jq -r '.structured_output.reason // "Guardian approved: read-only command"')
  jq -n --arg reason "$REASON" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "allow",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
fi

# Not approved → exit 0 with no output → normal approval prompt
exit 0
