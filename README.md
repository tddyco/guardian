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

The policy lives in `claude/policy.md` (reference copy) and is inlined into `claude/hooks/hooks.json`. To customize:

1. Fork this repo
2. Edit `claude/policy.md` with your changes
3. Copy the updated text into the `prompt` field in `claude/hooks/hooks.json`
4. To change the model, edit the `"model"` field in `claude/hooks/hooks.json` (default: `"sonnet"`)

## How it works

The plugin registers a `PreToolUse` hook on the `Bash` tool using Claude Code's `type: agent` hook. When a Bash command needs approval:

1. A Sonnet-powered sub-agent receives the command details
2. If the command runs a script file, the agent **reads the script** to inspect its contents
3. The agent returns `"allow"` (auto-approve) or `"ask"` (show normal approval prompt)
4. Commands already covered by your allow-rules in settings.json bypass the hook entirely

The agent has Read/Grep/Glob/Bash tools but **cannot Write or Edit** — it's read-only by design.

## Cost

The agent hook runs a Sonnet call on every non-whitelisted Bash command. For typical data analysis workflows this is a small overhead, but it adds up with many commands. Consider whitelisting your most frequent safe commands in settings.json to bypass the hook entirely.
