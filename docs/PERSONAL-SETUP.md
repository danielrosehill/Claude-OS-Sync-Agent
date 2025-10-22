# Personal Setup Guide

This document explains how to set up your personal profile directory that won't be shared publicly.

## Directory Structure

```
Claude-OS-Sync-Agent/
├── system-profiles/        # PUBLIC - Example/template profiles
│   ├── base/               # (empty, for documentation)
│   └── remote/             # (empty, for documentation)
│
├── daniel-desktop/         # PRIVATE - Your actual profiles (gitignored)
│   ├── base/               # Your desktop environment
│   └── remote/             # Your laptop environment
│
├── sync-agent.sh           # Main script (uses system-profiles by default)
└── sync-daniel.sh          # Your personal script (uses daniel-desktop)
```

## For Personal Use

Use the `sync-daniel.sh` script instead of `sync-agent.sh`:

```bash
# Gather your actual profiles
./sync-daniel.sh --gather-profiles

# Run sync analysis on your data
./sync-daniel.sh --sync

# Full workflow
./sync-daniel.sh --full
```

This script automatically uses the `daniel-desktop/` directory, which is excluded from git via `.gitignore`.

## For Public Sharing

The main `sync-agent.sh` script uses `system-profiles/` by default. This directory can be shared publicly as it contains only template/example data.

## Manual Override

You can also manually specify the profile directory:

```bash
# Use custom directory
SYNC_PROFILES_DIR=~/my-custom-profiles ./sync-agent.sh --gather-base

# Use daniel-desktop explicitly
SYNC_PROFILES_DIR=./daniel-desktop ./sync-agent.sh --sync
```

## Privacy Protection

The `.gitignore` file ensures:
- ✅ `daniel-desktop/` is never committed to git
- ✅ Your personal package lists stay private
- ✅ Your dotfiles aren't exposed publicly
- ✅ Hardware specs remain confidential

## Checking What Will Be Committed

Before pushing to GitHub:

```bash
# Check git status
git status

# Verify daniel-desktop is ignored
git status --ignored | grep daniel-desktop

# See what would be committed
git add -n .
```

You should NOT see `daniel-desktop/` in any of these outputs.

## Safe Sharing

When sharing this repo publicly:

1. **Always use sync-daniel.sh for personal data**
2. **Never commit from daniel-desktop/**
3. **Keep system-profiles/ empty** (just templates)
4. **Review before pushing**: `git diff --staged`

## Automation

For automated syncs, use your personal script:

```bash
# In crontab
0 20 * * * /path/to/Claude-OS-Sync-Agent/sync-daniel.sh --full >> /tmp/sync.log 2>&1
```

## Example Workflow

```bash
# Personal sync (uses daniel-desktop/)
./sync-daniel.sh --gather-profiles
./sync-daniel.sh --sync

# Public example (uses system-profiles/)
./sync-agent.sh --gather-base  # Would use system-profiles if you populated it
```

## Multiple Users

If others fork this repo, they can:

1. Create their own private directory (e.g., `jane-laptop/`)
2. Add it to `.gitignore`
3. Create their own wrapper script (e.g., `sync-jane.sh`)
4. Use the pattern you've established

## Security Notes

Your `daniel-desktop/` directory contains:
- Complete package inventories (could reveal security vulnerabilities)
- Dotfiles (may contain API keys, tokens, sensitive configs)
- Hardware specs (system fingerprinting data)
- Usage patterns (which tools you use)

This is why it's gitignored and kept private.
