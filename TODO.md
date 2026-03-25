# Guardian TODO

## Script file inspection not working reliably

The guardian's `claude -p` subprocess can read files via the Read tool, but it's not reliably connecting relative script paths (e.g., `python3 script.py`) with the working directory passed in the prompt text to construct the full path to read. It fails safe (returns `ask`), which is correct behavior per policy, but means safe scripts don't get auto-approved.

Possible fixes:
- Have `guardian.sh` resolve the script path itself and include the file contents directly in the prompt (no Read tool needed)
- Improve the prompt to be more explicit about how to construct the full path from CWD + relative script path
- Pass `--add-dir` to the `claude -p` call so the Read tool has access to the right directory

The test suite covers this: safe script tests currently expect `"ask"` (the degraded behavior). Once fixed, they should expect `"allow"` for safe scripts and `"ask"` for dangerous ones.
