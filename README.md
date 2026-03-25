# Guardian Plugin for Claude Code

An LLM-based PreToolUse hook that auto-approves read-only Bash commands and defers everything else to the normal user approval prompt.

Tired of manually approving `ls`, `cat`, `python analyze.py`, and `git log`? This plugin invokes `claude -p` as a security reviewer to inspect each Bash command (including reading script files the agent may have written) and auto-approves when it's confident the operation is read-only.

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

Run `/hooks` inside Claude Code to confirm the PreToolUse hook is loaded (`[command]` type).

## Customization

The policy lives in `claude/policy.md` and is read at runtime by the hook script. No build step needed.

To customize:

1. Fork this repo
2. Edit `claude/policy.md` with your changes
3. To change the model, edit the `--model` flag in `claude/hooks/guardian.sh`
4. To change the timeout, edit `claude/hooks/hooks.json`

## How it works

The plugin registers a `PreToolUse` command hook on the `Bash` tool. When a Bash command needs approval:

1. `guardian.sh` reads the hook input JSON from stdin
2. It invokes `claude -p --bare --model sonnet` with the policy as system prompt and the command details as user input
3. `--json-schema` enforces `{"ok": boolean, "reason": string}` output
4. `--tools "Read"` lets the reviewer inspect script files but not write or execute anything
5. `--bare` prevents recursive hook calls
6. If `ok: true` → auto-approve. Otherwise → show normal approval prompt
7. Commands already covered by your allow-rules in settings.json bypass the hook entirely

## Debugging

- **`Ctrl+O`** in Claude Code toggles verbose mode — shows hook stdout/stderr inline
- **`--debug`** flag shows full hook execution details
- **`/hooks`** menu to verify the hook is loaded and check its source

## Known limitations

- **Fail-open on errors**: if the guardian times out or crashes, the command falls through to the normal approval prompt. This is safe — the worst case is you see the prompt you'd normally see anyway.
- **No conversation context**: the guardian only sees the current command and can read files, but doesn't have the full conversation history.
- **Allow-rules take precedence**: commands already whitelisted in your settings.json bypass the guardian entirely.

## Cost

The hook invokes `claude -p` (Sonnet) on every non-whitelisted Bash command. For typical data analysis workflows this is a small overhead, but it adds up with many commands. Consider whitelisting your most frequent safe commands in settings.json to bypass the hook entirely.
