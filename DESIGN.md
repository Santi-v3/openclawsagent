# Sagent v2 Design Direction

Sagent should feel like a clean local AI workspace inspired by ChatGPT, Codex, and modern developer tools.

## Visual style

- Light theme first.
- Calm white/gray background.
- Rounded cards.
- Subtle borders.
- Minimal shadows.
- Clear spacing.
- No colorful clutter.

## Layout

Main layout:
- Left sidebar: chats/projects/workspaces.
- Center: chat and agent interaction.
- Right workspace panel: Terminal, Browser, Files, Tasks.
- Bottom-left user/settings menu.

## Behavior

- Agent actions should be visible.
- Shell/file actions require approval.
- Diffs should be reviewable.
- Tasks should be broken into small steps.
- User can pause/stop agent execution.

## MVP

The first MVP should prove:
- local model works
- local agent core works
- workspace folder is isolated
- UI can control agent actions later
- approval workflow exists
