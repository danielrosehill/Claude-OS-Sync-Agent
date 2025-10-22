# Architecture

## Overview

The Claude-OS-Sync-Agent is a bash wrapper around Claude CLI that leverages AI to make intelligent environment synchronization decisions.

## Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    sync-agent.sh                             │
│                   (Main Wrapper)                             │
└───────────┬─────────────────────────────────────┬───────────┘
            │                                     │
            │ Profile Gathering                   │ AI Analysis
            │                                     │
    ┌───────▼────────┐                   ┌────────▼───────────┐
    │  System        │                   │  Claude CLI        │
    │  Profiling     │                   │  Agent             │
    │                │                   │                    │
    │  - apt list    │                   │  Reads:            │
    │  - dpkg -l     │                   │  - system-prompt   │
    │  - pip list    │                   │  - profiles/base   │
    │  - conda env   │                   │  - profiles/remote │
    │  - ollama list │                   │                    │
    │  - lscpu       │                   │  Outputs:          │
    │  - free -h     │                   │  - Install cmds    │
    │  - dotfiles    │                   │  - Remove cmds     │
    └───────┬────────┘                   │  - Sync cmds       │
            │                            │  - Skip reasoning  │
            │                            └────────────────────┘
            │
    ┌───────▼─────────────────────────┐
    │  system-profiles/               │
    │                                 │
    │  ├── base/                      │
    │  │   ├── apt-packages.txt       │
    │  │   ├── cpu-info.txt           │
    │  │   ├── memory-info.txt        │
    │  │   ├── ollama-models.txt      │
    │  │   └── dotfiles/              │
    │  │                              │
    │  └── remote/                    │
    │      └── (same structure)       │
    └─────────────────────────────────┘
```

## Data Flow

### Phase 1: Profile Gathering

```
Desktop System ──┐
                 ├──> gather_base_profile() ──> system-profiles/base/
                 │
Laptop System ───┘──> gather_remote_profile() ─> system-profiles/remote/
(via SSH)
```

**Gathered Data**:
- Package inventories (apt, snap, flatpak, pip, conda)
- Hardware specifications (CPU, RAM)
- Application-specific data (Ollama models)
- Configuration files (dotfiles)

### Phase 2: AI Analysis

```
system-prompt.md ──┐
                   │
system-profiles/   ├──> Claude CLI ──> Recommendations
                   │    (AI Agent)     (bash commands)
User Request ──────┘
```

**Claude CLI receives**:
1. System prompt with instructions
2. Both environment profiles
3. User's request for sync analysis

**Claude CLI outputs**:
- Categorized package recommendations
- Hardware-aware skip decisions
- Dotfile sync commands
- Reasoning for each decision

### Phase 3: User Review & Execution

```
Recommendations ──> User Review ──┐
                                  ├──> Execute on Laptop
                                  │    (via SSH)
                                  └──> Update Complete
```

## File Structure

```
Claude-OS-Sync-Agent/
├── sync-agent.sh              # Main wrapper script
├── system-prompt.md           # AI agent instructions
├── README.md                  # Project overview
│
├── system-profiles/           # Environment snapshots
│   ├── README.md
│   ├── base/                  # Desktop profile
│   │   ├── apt-packages.txt
│   │   ├── dpkg-packages.txt
│   │   ├── snap-packages.txt
│   │   ├── flatpak-packages.txt
│   │   ├── pip-packages.txt
│   │   ├── conda-envs.txt
│   │   ├── ollama-models.txt
│   │   ├── system-info.txt
│   │   ├── cpu-info.txt
│   │   ├── memory-info.txt
│   │   └── dotfiles/
│   │       ├── .bashrc
│   │       ├── .gitconfig
│   │       └── ...
│   └── remote/                # Laptop profile
│       └── (same structure)
│
├── docs/                      # Documentation
│   ├── ARCHITECTURE.md        # This file
│   ├── USAGE.md              # Usage guide
│   └── EXAMPLE-OUTPUT.md     # Example analysis
│
├── archive/                   # Backups
│   └── system-prompt-original.md
│
└── tasks/                     # Task tracking
    └── setup.md
```

## Key Design Decisions

### 1. Wrapper Over Claude CLI

**Rationale**: Rather than implementing a standalone AI agent, we wrap Claude CLI to:
- Leverage Anthropic's official CLI tool
- Benefit from Claude's context handling
- Use Claude's authentication and API management
- Get automatic updates as Claude CLI improves

**Trade-off**: Requires Claude CLI to be installed and authenticated.

### 2. Profile-Based Analysis

**Rationale**: Gathering complete environment snapshots allows:
- Offline analysis (profiles can be gathered once, analyzed multiple times)
- Debugging (profiles are plain text, easy to inspect)
- Incremental comparison (compare profiles over time)
- Hardware-aware decisions (specs are part of the profile)

**Trade-off**: Profiles can become stale; need periodic refresh.

### 3. Plain Text Storage

**Rationale**: All profiles stored as plain text files:
- Human-readable for debugging
- Easy to version control
- Simple to parse and compare
- No database dependency

**Trade-off**: Larger file sizes than structured formats (JSON, SQLite).

### 4. SSH-Based Remote Access

**Rationale**: Use standard SSH for laptop access:
- Secure by default
- No custom protocols needed
- Works across networks
- Leverage existing SSH config

**Trade-off**: Requires laptop to be on same network or VPN.

## Security Considerations

### Data Sensitivity

Profiles may contain:
- ✅ Package names (generally safe)
- ✅ System specs (public information)
- ⚠️ Dotfiles (may contain sensitive configs)
- ⚠️ Package versions (could reveal vulnerabilities)

**Mitigation**:
- Add `system-profiles/` to `.gitignore` if sharing publicly
- Review dotfiles before committing to version control
- Consider encrypting profiles if storing in cloud

### Command Execution

**Risk**: Claude generates bash commands that could be destructive.

**Mitigation**:
- All commands are displayed to user, not auto-executed
- User reviews and approves before running
- Focus on safe operations (apt install, copy files)
- Avoid destructive operations (rm -rf, dd, etc.)

### SSH Security

**Risk**: Automated SSH access could be exploited.

**Mitigation**:
- Use SSH key-based authentication
- Limit sync agent to specific user account
- Consider SSH agent forwarding restrictions
- Use restrictive SSH config

## Performance

### Profile Gathering
- **Time**: 5-10 seconds (local), 10-20 seconds (remote via SSH)
- **Data Size**: ~1-2 MB per profile (mostly package lists)
- **Network**: Minimal bandwidth (text files only)

### AI Analysis
- **Time**: 10-30 seconds (depends on profile size, Claude API response)
- **Cost**: ~1-2 cents per analysis (Claude API usage)
- **Tokens**: ~5,000-10,000 tokens (profiles + prompt)

### Total Workflow
- **End-to-End**: 30-60 seconds for full sync analysis
- **Scalability**: Profiles grow linearly with package count

## Extension Points

The architecture supports these extensions:

### 1. Additional Package Managers
Add to `gather_*_profile()` functions:
```bash
npm list -g > "$PROFILE/npm-packages.txt"
cargo install --list > "$PROFILE/cargo-packages.txt"
```

### 2. More System Metrics
```bash
df -h > "$PROFILE/disk-usage.txt"
systemctl list-units > "$PROFILE/services.txt"
```

### 3. Alternative AI Backends
Replace Claude CLI with:
- OpenAI API
- Local Ollama instance
- Other LLM APIs

### 4. Web Dashboard
Create a GUI that:
- Visualizes profile differences
- Shows sync history
- Provides one-click sync execution

### 5. Automatic Execution
With user approval, auto-execute safe commands:
```bash
if [[ "$AUTO_EXECUTE" == "true" ]]; then
    eval "$CLAUDE_RECOMMENDATION"
fi
```

## Comparison to Alternatives

| Feature | Claude-OS-Sync-Agent | rsync | Ansible | Custom Script |
|---------|---------------------|-------|---------|---------------|
| Intelligence | ✅ AI-powered | ❌ Dumb sync | ⚠️ Rule-based | ⚠️ Manual logic |
| Hardware-aware | ✅ Yes | ❌ No | ⚠️ With config | ⚠️ With coding |
| Easy to use | ✅ Natural language | ⚠️ Complex flags | ❌ YAML learning curve | ⚠️ Need scripting |
| Incremental | ✅ Yes | ✅ Yes | ✅ Yes | ⚠️ Depends |
| Human review | ✅ Built-in | ❌ No | ⚠️ Via --check | ⚠️ Manual |

## Future Enhancements

1. **Diff Visualization**: Show side-by-side package comparisons
2. **Rollback Support**: Track applied changes for easy rollback
3. **Multiple Remotes**: Support syncing to multiple laptops
4. **Selective Profiles**: Choose which aspects to sync (only Python, only dotfiles, etc.)
5. **Change Tracking**: Log what was synced and when
6. **Conflict Resolution**: Handle cases where laptop has newer configs
7. **Dry-Run Mode**: Preview all changes without gathering remote profile
