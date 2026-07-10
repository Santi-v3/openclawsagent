# Sagent CLI Wrapper

## Purpose

Sagent can be used globally from the terminal with:

```bash
sagent "<task>"
```

Examples:

```bash
sagent "/help"
sagent "/health"
sagent "/security status"
sagent "/approval status"
sagent "Antworte exakt mit: pong"
sagent "Analysiere scripts/sagent-task.sh und ändere keine Dateien."
```

## Why a wrapper instead of a symlink?

A direct symlink does not work reliably:

```bash
ln -sf ~/Projects/sagent-lab/scripts/sagent-task.sh ~/.local/bin/sagent
```

Reason:

`scripts/sagent-task.sh` calls helper scripts using relative paths, for example:

```bash
scripts/sagent-healthcheck.sh
scripts/sagent-opencode-worker.sh
```

When started through a symlink from `~/.local/bin/sagent`, Sagent may look for helper scripts in `~/.local/bin/`.

That causes errors like:

```text
~/.local/bin/sagent-healthcheck.sh: No such file or directory
~/.local/bin/sagent-opencode-worker.sh: No such file or directory
```

## Correct global wrapper

Use a wrapper script:

```bash
mkdir -p ~/.local/bin

cat > ~/.local/bin/sagent <<'WRAPPER'
#!/usr/bin/env bash
cd "$HOME/Projects/sagent-lab" || exit 1
exec "$HOME/Projects/sagent-lab/scripts/sagent-task.sh" "$@"
WRAPPER

chmod +x ~/.local/bin/sagent
```

## PATH

Make sure `~/.local/bin` is in the shell PATH.

```bash
echo $PATH
```

If missing:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

## Test

```bash
sagent "/help"
sagent "/health"
sagent "Antworte exakt mit: pong"
sagent "Analysiere scripts/sagent-task.sh und ändere keine Dateien."
```

Expected behavior:

- `/help` shows Sagent commands
- `/health` runs the OpenClaw healthcheck
- normal prompts go to OpenClaw
- coding prompts auto-route to OpenCode when auto-code routing is enabled

