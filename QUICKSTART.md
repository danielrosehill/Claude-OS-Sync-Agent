# Quick Start Guide

Get up and running with Claude-OS-Sync-Agent in 5 minutes.

## Prerequisites Check

```bash
# 1. Verify Claude CLI is installed
claude --version

# 2. Test SSH access to laptop
ssh laptop "echo 'Connected successfully'"

# 3. Ensure you're in the project directory
cd ~/repos/github/Claude-OS-Sync-Agent
```

## First Run

### Step 1: Test Local Profile Gathering

```bash
# Gather just your desktop profile (no laptop needed)
./sync-agent.sh --gather-base
```

Expected output:
```
=== Desktop-to-Laptop Environment Sync Agent ===

Gathering base (desktop) environment profile...
✓ Base profile gathered

=== Sync Agent Complete ===
```

### Step 2: Inspect Your Profile

```bash
# Check what was gathered
ls -lh system-profiles/base/

# Preview your system specs
cat system-profiles/base/cpu-info.txt
cat system-profiles/base/memory-info.txt

# See installed packages (first 20 lines)
head -20 system-profiles/base/apt-packages.txt
```

### Step 3: Full Sync (If Laptop Available)

```bash
# Run full sync: gather both profiles + analyze
./sync-agent.sh --full
```

This will:
1. Gather desktop profile (5-10 seconds)
2. Connect to laptop via SSH and gather remote profile (10-15 seconds)
3. Invoke Claude CLI to analyze both profiles (10-30 seconds)
4. Display recommendations

### Step 4: Review Recommendations

Claude will output something like:

```markdown
## Packages to Install on Laptop
ssh laptop "sudo apt install ripgrep fd-find bat"

## Packages to Remove from Laptop
ssh laptop "sudo apt remove old-package"

## Dotfiles to Sync
scp ~/.bashrc laptop:~/

## Skipped Items
- ollama:70b - Too large for 8GB laptop RAM
```

### Step 5: Execute Approved Commands

Copy and paste the commands you approve:

```bash
# Install approved packages
ssh laptop "sudo apt install ripgrep fd-find bat"

# Sync approved dotfiles
scp ~/.bashrc laptop:~/
```

## Common First-Time Issues

### Issue: "claude: command not found"

**Solution**: Install Claude CLI:
```bash
# Follow installation instructions at https://claude.com/cli
# Then authenticate
claude --login
```

### Issue: "laptop: Host not found"

**Solution**: Set up SSH alias in `~/.ssh/config`:
```bash
cat >> ~/.ssh/config << 'EOF'

Host laptop
    HostName 10.0.0.XXX  # Replace with your laptop's IP
    User yourusername
    IdentityFile ~/.ssh/id_rsa
EOF
```

Test connection:
```bash
ssh laptop "hostname"
```

### Issue: "Permission denied" when gathering profiles

**Solution**: Some commands need sudo. Re-run with specific gathering:
```bash
# If apt/dpkg fail, try pip/conda only
ssh laptop "pip list" > system-profiles/remote/pip-packages.txt
ssh laptop "conda env list" > system-profiles/remote/conda-envs.txt
```

## What's Next?

After your first successful sync:

1. **Schedule Regular Syncs**: Add to crontab for weekly runs
   ```bash
   crontab -e
   # Add: 0 20 * * 0 /path/to/sync-agent.sh --full >> /tmp/sync.log 2>&1
   ```

2. **Customize System Prompt**: Edit `system-prompt.md` to add specific preferences
   ```bash
   nano system-prompt.md
   # Add: "Never sync package X" or "Always prioritize Y tools"
   ```

3. **Review Documentation**:
   - `docs/USAGE.md` - Detailed usage guide
   - `docs/EXAMPLE-OUTPUT.md` - See example analysis
   - `docs/ARCHITECTURE.md` - Understand how it works

4. **Test Edge Cases**:
   - Run with laptop offline: `./sync-agent.sh --gather-base`
   - Manually compare profiles: `diff system-profiles/base/apt-packages.txt system-profiles/remote/apt-packages.txt`

## Pro Tips

1. **Start Conservative**: First run, only install obviously safe packages (CLI tools)

2. **Review Before Removing**: Be careful with removal recommendations - verify you don't need those packages

3. **Incremental Approach**: You don't need to sync everything at once

4. **Keep Profiles Fresh**: Re-gather profiles after major desktop updates

5. **Check Hardware Skips**: Pay attention to what Claude skips due to hardware - those decisions are usually correct

## Example First Workflow

```bash
# 1. Gather profiles
./sync-agent.sh --gather-profiles

# 2. Analyze
./sync-agent.sh --sync

# 3. Pick 3-5 high-priority items from recommendations
ssh laptop "sudo apt install ripgrep fd-find bat"
scp ~/.bashrc laptop:~/

# 4. Test on laptop
ssh laptop "which rg && rg --version"

# 5. Run again next week for incremental updates
```

## Success Indicators

You'll know it's working when:
- ✅ Profiles are generated in `system-profiles/`
- ✅ Claude provides categorized recommendations
- ✅ Hardware-intensive items are correctly skipped
- ✅ Sync commands execute successfully on laptop
- ✅ Laptop has key tools from your desktop workflow

## Getting Help

If something doesn't work:
1. Check this guide's "Common Issues" section
2. Review `docs/USAGE.md` for detailed troubleshooting
3. Inspect generated profiles manually
4. Test SSH connectivity independently
5. Verify Claude CLI authentication

## Next Steps

Once comfortable with the basics:
- Set up automated syncs (cron/systemd)
- Customize the system prompt for your workflow
- Add additional package managers (npm, cargo, etc.)
- Create backup scripts for profiles
- Share your setup with colleagues
