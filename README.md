# Guardian Plugin for Claude Code

An LLM-based PreToolUse hook that auto-approves read-only Bash commands and defers everything else to the normal user approval prompt.

Tired of manually approving `ls`, `cat`, `python analyze.py`, and `git log`? This plugin uses a Sonnet-powered agent hook to inspect each Bash command (including reading script files the agent may have written) and auto-approves when it's confident the operation is read-only.

## What gets auto-approved

- **Read-only commands**: `cat`, `ls`, `grep`, `find`, `jq`, `diff`, `wc`, `head`, `tail`, etc.
- **Git read-only**: `git log`, `git diff`, `git status`, `git show`, `git blame`, etc.
- **GitHub CLI read-only**: `gh pr view`, `gh pr list`, `gh issue list`, `gh api` (GET only)
- **System info**: `du`, `df`, `ps`, `uname`, `whoami`
- **Data-analysis I/O**: writing to `./tmp/`, `./out/`, `./output/`, `./results/`, `/tmp/`, or redirecting output to files within the project
- **Scripts**: Python/Node/Bash scripts in the project directory — the guardian **reads the script contents** to verify they're safe before approving

## What gets deferred to the user

Everything else, including:
- Mutating git operations (`git commit`, `git push`)
- Package installation (`npm install`, `pip install`)
- File deletion, creation, moves
- Downloads (`curl`, `wget`)
- `gh api` with mutating HTTP methods
- `sudo`, `chmod`, `chown`

There is no "deny" category — the user always has the final say via the normal approval prompt.

## Install

### For teammates

```
/plugin marketplace add tddyco/guardian
/plugin install guardian@tddyco-guardian
```

### Development / testing

```bash
claude --plugin-dir /path/to/claude-guardian/claude
```

### Verify

Run `/hooks` inside Claude Code to confirm the PreToolUse hook is loaded.

## Customization

The policy lives in `claude/policy.md`. A build script inlines it into `claude/hooks/hooks.json`.

To customize:

1. Fork this repo
2. Edit `claude/policy.md` with your changes
3. Run `node build.mjs` to update `claude/hooks/hooks.json`
4. To change the model or timeout, edit `claude/hooks/hooks.json` directly

## How it works

The plugin registers a `PreToolUse` hook on the `Bash` tool using Claude Code's `type: agent` hook. When a Bash command needs approval:

1. A Sonnet-powered sub-agent receives the command details
2. If the command runs a script file, the agent **reads the script** to inspect its contents
3. The agent returns `"allow"` (auto-approve) or `"ask"` (show normal approval prompt)
4. Commands already covered by your allow-rules in settings.json bypass the hook entirely

The agent has Read/Grep/Glob/Bash tools but **cannot Write or Edit** — it's read-only by design.

## Observability

- **While reviewing**: the status bar shows "Guardian reviewing command..." during each review
- **Debug mode**: run Claude Code with `--debug` to see full hook execution details

## Known limitations

- **Fail-open on errors**: Claude Code hooks are inherently fail-open — if the guardian agent times out or crashes, the command proceeds to the normal approval prompt. Since the guardian never returns "deny" (only "allow" or "ask"), the worst case is the user sees the normal approval prompt. This is a safe fallback, not a security hole.
- **No conversation context**: the guardian only sees the current command and can read files, but doesn't have the full conversation history. It can't distinguish "user asked to delete this" from "agent decided to delete this on its own."
- **Allow-rules take precedence**: commands already whitelisted in your settings.json bypass the guardian entirely.

## Cost

The agent hook runs a Sonnet call on every non-whitelisted Bash command. For typical data analysis workflows this is a small overhead, but it adds up with many commands. Consider whitelisting your most frequent safe commands in settings.json to bypass the hook entirely.
