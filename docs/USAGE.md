# Usage Guide

## Overview

The Claude-OS-Sync-Agent workflow consists of three main steps:

1. **Gather profiles** from both environments
2. **Invoke Claude CLI** to analyze the profiles
3. **Review and execute** the recommendations

## Basic Workflow

### Step 1: Gather Environment Profiles

```bash
# Full profile gathering (both desktop and laptop)
./sync-agent.sh --gather-profiles

# Or gather individually
./sync-agent.sh --gather-base      # Desktop only
./sync-agent.sh --gather-remote    # Laptop only (requires SSH)
```

This creates snapshots in `system-profiles/`:
- `base/` - Your desktop environment
- `remote/` - Your laptop environment

### Step 2: Run Sync Analysis

```bash
# Analyze profiles with Claude CLI
./sync-agent.sh --sync
```

This invokes Claude CLI with the system prompt, which will:
- Read the system prompt instructions from `system-prompt.md`
- Analyze both environment profiles
- Compare packages, configurations, and hardware specs
- Generate intelligent recommendations

### Step 3: Review and Execute

Claude will provide actionable recommendations like:

```bash
### Packages to Install on Laptop
sudo apt install ripgrep fd-find bat exa

### Packages to Remove from Laptop
sudo apt remove old-package-no-longer-used

### Dotfiles to Sync
scp ~/.bashrc laptop:~/
scp ~/.gitconfig laptop:~/

### Skipped (Hardware Constraints)
- ollama model llama3.1:70b - Too large for 8GB laptop RAM
- cuda-toolkit - Laptop has no NVIDIA GPU
```

You can then review these recommendations and execute the ones you approve.

## One-Command Full Sync

For convenience, run everything at once:

```bash
./sync-agent.sh --full
# or simply
./sync-agent.sh
```

This will:
1. Gather desktop profile
2. Gather laptop profile (if reachable)
3. Invoke Claude CLI for analysis
4. Display recommendations

## Advanced Usage

### Scheduled Syncs

#### Cron Job
Add to your crontab to run automatically:

```bash
crontab -e

# Add this line (runs daily at 8 PM):
0 20 * * * /home/daniel/repos/github/Claude-OS-Sync-Agent/sync-agent.sh --full >> /tmp/sync-agent.log 2>&1
```

#### Systemd Timer

Create `/etc/systemd/system/sync-agent.service`:

```ini
[Unit]
Description=Claude OS Sync Agent
After=network.target

[Service]
Type=oneshot
User=daniel
WorkingDirectory=/home/daniel/repos/github/Claude-OS-Sync-Agent
ExecStart=/home/daniel/repos/github/Claude-OS-Sync-Agent/sync-agent.sh --full
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

Create `/etc/systemd/system/sync-agent.timer`:

```ini
[Unit]
Description=Run Claude OS Sync Agent daily
Requires=sync-agent.service

[Timer]
OnCalendar=daily
OnCalendar=20:00
Persistent=true

[Install]
WantedBy=timers.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable sync-agent.timer
sudo systemctl start sync-agent.timer
```

### Manual Profile Inspection

Profiles are plain text files you can inspect manually:

```bash
# View installed packages on desktop
cat system-profiles/base/apt-packages.txt

# Compare hardware between systems
diff system-profiles/base/cpu-info.txt system-profiles/remote/cpu-info.txt

# Check what Ollama models you have
cat system-profiles/base/ollama-models.txt
```

### Selective Sync

If you only want to sync specific aspects:

1. Gather profiles: `./sync-agent.sh --gather-profiles`
2. Ask Claude CLI directly with specific instructions:

```bash
echo "Please analyze the system profiles and recommend only Python package syncs between my desktop and laptop. Focus on development tools." | claude --dangerously-skip-user-approval
```

## Troubleshooting

### Laptop Not Reachable

If you get "Laptop is not reachable":

1. Check SSH connectivity:
   ```bash
   ssh laptop "echo 'Connected'"
   ```

2. Verify SSH config has the `laptop` alias:
   ```bash
   cat ~/.ssh/config | grep -A 3 "Host laptop"
   ```

3. Check if laptop is on the network:
   ```bash
   ping 10.0.0.XXX
   ```

### Claude CLI Not Found

Install Claude CLI:
```bash
# Follow installation instructions for your system
# Ensure 'claude' command is in your PATH
which claude
```

### Permission Errors

Some operations require sudo. The script handles most cases gracefully, but you may need to run certain recommendations with elevated privileges:

```bash
sudo apt install package-name
```

## Tips

1. **Run after major updates**: After installing several new packages on your desktop, run the sync agent to keep your laptop current.

2. **Review before executing**: Always review Claude's recommendations before executing commands, especially for removals.

3. **Incremental approach**: You don't need to accept all recommendations at once. Pick the most important items first.

4. **Hardware awareness**: Trust Claude's hardware-based skips. It won't recommend syncing heavy packages to underpowered hardware.

5. **Profile freshness**: Profiles are snapshots. For best results, gather fresh profiles before each sync analysis.

## Example Session

```bash
daniel@desktop:~/repos/github/Claude-OS-Sync-Agent$ ./sync-agent.sh

=== Desktop-to-Laptop Environment Sync Agent ===

Gathering base (desktop) environment profile...
✓ Base profile gathered

Checking laptop connectivity...
✓ Laptop is reachable via SSH

Gathering remote (laptop) environment profile...
✓ Remote profile gathered

Invoking Claude CLI sync agent...
[Claude analyzes profiles and provides recommendations]

=== Sync Agent Complete ===
```

## Next Steps

After getting recommendations:

1. Review the suggested package installations
2. Execute approved installations: `ssh laptop "sudo apt install <packages>"`
3. Sync approved dotfiles: `scp ~/.bashrc laptop:~/`
4. Remove obsolete packages if desired: `ssh laptop "sudo apt remove <packages>"`
5. Re-run periodically to keep environments in sync
