# Privacy Model

This document explains how the repository is structured to allow public sharing while keeping personal data private.

## Repository Structure

```
Claude-OS-Sync-Agent/
├── system-profiles/        # PUBLIC - Example/template directory
│   ├── base/.gitkeep       # Empty placeholder
│   ├── remote/.gitkeep     # Empty placeholder
│   └── README.md           # Documentation (public)
│
├── daniel-desktop/         # PRIVATE - Gitignored personal data
│   ├── base/               # Actual desktop profile (NOT committed)
│   ├── remote/             # Actual laptop profile (NOT committed)
│   └── README.md           # Personal notes (NOT committed)
│
├── sync-agent.sh           # PUBLIC - Main script
├── sync-daniel.sh          # PUBLIC - Personal wrapper (but uses private data)
└── .gitignore              # Excludes daniel-desktop/
```

## What's Public (Committed to Git)

✅ **Scripts**:
- `sync-agent.sh` - Main sync wrapper
- `sync-daniel.sh` - Personal wrapper script (safe to share)

✅ **Documentation**:
- All files in `docs/`
- `README.md`, `QUICKSTART.md`
- `system-prompt.md`

✅ **Templates**:
- `system-profiles/` directory structure (empty)
- `.gitkeep` files to preserve empty directories

✅ **Archive**:
- Original system prompts for reference

## What's Private (NOT Committed)

❌ **Personal Profiles**:
- `daniel-desktop/base/*` - Your desktop package lists, specs, dotfiles
- `daniel-desktop/remote/*` - Your laptop data

These directories are in `.gitignore` and contain:
- Complete package inventories (potential security vulnerabilities)
- Dotfiles (may contain API keys, tokens, credentials)
- Hardware specifications (system fingerprinting)
- Usage patterns (which tools, models you use)

## Why This Matters

### Security Risks of Sharing Profiles

1. **Package Versions**: Reveals which versions you run, potentially exposing known CVEs
2. **Dotfiles**: May contain:
   - GitHub tokens in `.gitconfig`
   - API keys in `.bashrc` or `.profile`
   - SSH configurations in `.ssh/config`
   - Private repository URLs
3. **System Fingerprinting**: CPU/RAM specs help attackers profile your system
4. **Usage Patterns**: Reveals your workflow, tools, development environment

### Example of Sensitive Data

From `daniel-desktop/base/`:
- `apt-packages.txt` - Could show outdated packages with known vulnerabilities
- `dotfiles/.gitconfig` - Might contain your email, signing keys
- `pip-packages.txt` - Shows Python packages that could have security issues
- `ollama-models.txt` - Reveals which AI models you're running

## Using This Pattern

### For Your Personal Use

```bash
# Always use your personal script
./sync-daniel.sh --gather-profiles
./sync-daniel.sh --sync
```

### For Public Sharing

When you push to GitHub:
- ✅ Share the code and scripts
- ✅ Share the documentation
- ✅ Share the system prompt
- ❌ DON'T commit `daniel-desktop/`

### For Others to Fork

Users who fork this repo can:

1. Create their own private directory:
   ```bash
   mkdir -p jane-laptop/{base,remote}
   ```

2. Add to `.gitignore`:
   ```bash
   echo "jane-laptop/" >> .gitignore
   ```

3. Create their wrapper script:
   ```bash
   cat > sync-jane.sh << 'EOF'
   #!/bin/bash
   export SYNC_PROFILES_DIR="$(dirname "$0")/jane-laptop"
   exec "$(dirname "$0")/sync-agent.sh" "$@"
   EOF
   chmod +x sync-jane.sh
   ```

4. Use it:
   ```bash
   ./sync-jane.sh --full
   ```

## Verification

Before pushing to public repo:

```bash
# 1. Check git status
git status

# 2. Verify personal data is ignored
git status --ignored | grep daniel-desktop
# Should show: daniel-desktop/

# 3. Preview what would be committed
git add -n .
# Should NOT include daniel-desktop/

# 4. Double-check ignored files
git check-ignore -v daniel-desktop/
# Should show: .gitignore:2:daniel-desktop/    daniel-desktop/
```

## Safety Checklist

Before pushing commits:

- [ ] Verified `daniel-desktop/` is in `.gitignore`
- [ ] Ran `git status --ignored` to confirm
- [ ] Checked `git add -n .` doesn't include personal data
- [ ] Reviewed all files in `git diff --staged`
- [ ] Confirmed no API keys or tokens in committed files
- [ ] Tested that scripts work with public `system-profiles/`

## Best Practices

### 1. Never Disable Gitignore

Don't do this:
```bash
git add -f daniel-desktop/  # DON'T!
```

### 2. Review Before Committing

Always check what you're about to commit:
```bash
git diff --staged --stat
git diff --staged
```

### 3. Audit Dotfiles

Before committing any example dotfiles:
```bash
grep -i "token\|key\|secret\|password" dotfile
```

### 4. Use Template Data for Examples

If you want to provide example profiles:
- Create fake/sanitized data in `system-profiles/`
- Don't copy from `daniel-desktop/`

### 5. Document Clearly

Make it obvious to others what should be private:
- Add README files
- Include warnings in documentation
- Provide clear examples

## Backup Strategy

Since `daniel-desktop/` is not in git:

### Local Backups
```bash
# Encrypted backup
tar czf ~/backup-sync-$(date +%Y%m%d).tar.gz daniel-desktop/
gpg -c ~/backup-sync-$(date +%Y%m%d).tar.gz
```

### Cloud Backups
```bash
# Use private cloud storage
rclone sync daniel-desktop/ my-private-cloud:sync-profiles/ --exclude "*.log"
```

### Version Control (Private Repo)
```bash
# Create a separate private repo for your profiles
cd daniel-desktop/
git init
gh repo create daniel-sync-profiles --private
git add .
git commit -m "Sync profiles backup"
git push
```

## Multi-User Patterns

### Pattern 1: Each User Has Own Directory
```
repo/
├── alice-desktop/    (gitignored)
├── bob-laptop/       (gitignored)
├── charlie-work/     (gitignored)
└── system-profiles/  (public template)
```

### Pattern 2: Use Branch-Based Isolation
```bash
# Public branch (default)
main - contains only code and templates

# Private branch (local only)
daniel-private - contains daniel-desktop/ data
```

### Pattern 3: Separate Repos
- Public repo: Code and documentation
- Private repo: Your actual profiles and data

## FAQ

**Q: Can I commit my sync-daniel.sh script?**
A: Yes! The script itself is safe. It only references the directory but doesn't contain sensitive data.

**Q: What if I accidentally commit daniel-desktop/?**
A: Immediately:
1. `git reset HEAD daniel-desktop/`
2. `git rm --cached -r daniel-desktop/`
3. Push the fix
4. Consider the data compromised and rotate any keys/tokens

**Q: How do collaborators use this?**
A: They fork the repo, create their own private directory, add to `.gitignore`, and create their wrapper script.

**Q: Should I back up daniel-desktop/?**
A: Yes, separately from git. Use encrypted backups or private cloud storage.

**Q: Can I use system-profiles/ for my data?**
A: You could, but using a separate private directory (like `daniel-desktop/`) is clearer and safer.
