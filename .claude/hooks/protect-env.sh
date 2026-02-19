#!/usr/bin/env bash
# Hook: block Claude from reading, editing, writing, or accessing .env via any tool.
# Exit 2 = block the tool call.
set -euo pipefail

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Check file-based tools (Read, Edit, Write)
if [[ -n "$FILE_PATH" ]]; then
    base=$(basename "$FILE_PATH")
    if [[ "$base" == ".env" ]]; then
        echo "Blocked: cannot access .env — secrets must stay hidden from Claude" >&2
        exit 2
    fi
fi

# Check Bash tool for commands that could read/leak .env contents
if [[ "$TOOL" == "Bash" && -n "$COMMAND" ]]; then
    # Block: cat .env, source .env, less .env, head .env, tail .env, grep .env, etc.
    # Also block: . .env (dot-source)
    if echo "$COMMAND" | grep -qE '(^|\s|&&|\|\||;)\s*(cat|head|tail|less|more|source|\.|\bsed\b|\bawk\b|\bgrep\b|strings|xxd|od|hexdump|base64|openssl)\s+.*\.env(\s|$|;|&&|\|)'; then
        echo "Blocked: cannot read .env via shell — secrets must stay hidden from Claude" >&2
        exit 2
    fi
    # Block: echo $TF_VAR_state_passphrase, printenv TF_VAR_, echo $AWS_SECRET_ACCESS_KEY
    if echo "$COMMAND" | grep -qE '(echo|printf|printenv|env|set)\s.*(TF_VAR_(state_passphrase|mysql_admin_password)|AWS_SECRET_ACCESS_KEY)'; then
        echo "Blocked: cannot echo secret env vars — secrets must stay hidden from Claude" >&2
        exit 2
    fi
    # Block: direct tofu output of S3 credentials (use `just s3-creds-to-env` instead)
    if echo "$COMMAND" | grep -qE 'tofu\s+.*output\s+.*-raw\s+(s3_secret_key|s3_access_key)'; then
        echo "Blocked: cannot read S3 credentials directly — use 'just s3-creds-to-env' instead" >&2
        exit 2
    fi
fi

exit 0
