# Claude-OS-Sync-Agent

An intelligent environment synchronization tool that uses Claude CLI to keep your laptop in sync with your desktop workstation.

## Overview

This tool acts as a wrapper over Claude CLI, using AI to make intelligent decisions about what packages, configurations, and tools should be synced from your primary desktop to your laptop. Unlike simple mirroring tools, it's hardware-aware and designed for incremental, practical syncing.

## Key Features

- **Hardware-Aware**: Won't sync resource-intensive packages to less capable hardware
- **Incremental Sync**: Periodic updates rather than perfect replication
- **Intelligent Analysis**: Uses Claude AI to make context-aware decisions
- **Profile-Based**: Compares environment snapshots for targeted recommendations
- **Package Management**: Handles APT, Snap, Flatpak, pip, conda, and more
- **Dotfile Sync**: Tracks and syncs configuration file changes

## Requirements

- Claude CLI installed and authenticated (`claude` command available)
- SSH access to laptop configured with alias `laptop`
- Both systems running Ubuntu/Debian-based Linux
- Bash shell

## Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/Claude-OS-Sync-Agent.git
cd Claude-OS-Sync-Agent

# Make the script executable
chmod +x sync-agent.sh

# Run a full sync (gather profiles + analyze)
./sync-agent.sh

# Or run specific operations
./sync-agent.sh --gather-profiles   # Just gather environment data
./sync-agent.sh --sync              # Analyze existing profiles
```

### For Personal/Private Use

To keep your actual system profiles private (not committed to git):

```bash
# Use your personal sync script
./sync-daniel.sh --full

# Or set custom profile directory
SYNC_PROFILES_DIR=./my-profiles ./sync-agent.sh --full
```

See `docs/PERSONAL-SETUP.md` for details on keeping your data private.

## How It Works

1. **Profile Gathering**: Collects environment snapshots from both desktop (base) and laptop (remote)
   - Installed packages (apt, snap, flatpak, pip, conda)
   - Hardware specifications (CPU, RAM)
   - Ollama models
   - Configuration files (dotfiles)

2. **AI Analysis**: Invokes Claude CLI with the system prompt and profiles
   - Compares environments
   - Considers hardware capabilities
   - Identifies sync candidates
   - Flags items for removal

3. **Recommendations**: Provides actionable commands for:
   - Installing missing packages on laptop
   - Removing obsolete packages from laptop
   - Syncing dotfile changes
   - Skipping resource-intensive items

## Usage

### Full Sync
```bash
./sync-agent.sh --full
```
Gathers both profiles and runs AI analysis (default behavior).

### Gather Profiles Only
```bash
./sync-agent.sh --gather-profiles
```
Updates environment snapshots without running analysis.

### Analyze Existing Profiles
```bash
./sync-agent.sh --sync
```
Runs AI analysis on previously gathered profiles.

### Individual Profile Updates
```bash
./sync-agent.sh --gather-base    # Desktop only
./sync-agent.sh --gather-remote  # Laptop only
```

## Configuration

### SSH Setup
Ensure you can SSH to your laptop using the alias `laptop`:

```bash
# Add to ~/.ssh/config
Host laptop
    HostName 10.0.0.XXX
    User yourusername
```

### Claude CLI
Make sure Claude CLI is authenticated:
```bash
claude --version
```

## System Profiles

Environment snapshots are stored in `system-profiles/`:
- `base/` - Desktop environment
- `remote/` - Laptop environment

See `system-profiles/README.md` for details on the profile structure.

## Automation

### Cron Job
Run sync automatically when laptop is on the network:

```bash
# Add to crontab (runs daily at 8 PM)
0 20 * * * /path/to/Claude-OS-Sync-Agent/sync-agent.sh --full >> /tmp/sync-agent.log 2>&1
```

### Systemd Timer
Create a systemd service for periodic sync:

```bash
# See docs/systemd-setup.md for instructions
```

## Architecture

- `sync-agent.sh` - Main wrapper script
- `system-prompt.md` - AI agent instructions
- `system-profiles/` - Environment snapshots
- `archive/` - Original/backup files

## Development

The tool uses a specialized system prompt (`system-prompt.md`) that instructs Claude on:
- Hardware capability awareness
- Incremental sync philosophy
- Package evaluation criteria
- Output formatting

Original prompts are preserved in `archive/` for reference.

## Examples

See `docs/examples.md` for common usage patterns and example outputs.

## Troubleshooting

**Laptop not reachable**: Ensure SSH is configured and laptop is on the local network.

**Claude CLI not found**: Install Claude CLI and ensure it's in your PATH.

**Permission errors**: Some package queries may require sudo; the script handles this gracefully.

## License

MIT License - See LICENSE file for details.

## Contributing

Issues and pull requests welcome! See CONTRIBUTING.md for guidelines.
