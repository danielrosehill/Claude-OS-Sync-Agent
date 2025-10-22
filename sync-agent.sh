#!/bin/bash

# Desktop-to-Laptop Environment Sync Agent
# A wrapper over Claude CLI that uses an AI agent to intelligently sync environments

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_PROMPT="$SCRIPT_DIR/system-prompt.md"

# Default to system-profiles, but allow override via environment variable
# Set SYNC_PROFILES_DIR to use a custom directory (e.g., daniel-desktop)
PROFILES_DIR="${SYNC_PROFILES_DIR:-$SCRIPT_DIR/system-profiles}"
BASE_PROFILE="$PROFILES_DIR/base"
REMOTE_PROFILE="$PROFILES_DIR/remote"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if laptop is reachable
check_laptop_connectivity() {
    echo -e "${BLUE}Checking laptop connectivity...${NC}"
    if ssh -o ConnectTimeout=5 -o BatchMode=yes laptop "echo 2>&1" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Laptop is reachable via SSH${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ Laptop is not reachable. Will only analyze local state.${NC}"
        return 1
    fi
}

# Function to gather base (desktop) profile
gather_base_profile() {
    echo -e "${BLUE}Gathering base (desktop) environment profile...${NC}"

    mkdir -p "$BASE_PROFILE"

    # Gather installed packages
    dpkg -l > "$BASE_PROFILE/dpkg-packages.txt" 2>/dev/null || true
    apt list --installed > "$BASE_PROFILE/apt-packages.txt" 2>/dev/null || true
    snap list > "$BASE_PROFILE/snap-packages.txt" 2>/dev/null || true
    flatpak list --app > "$BASE_PROFILE/flatpak-packages.txt" 2>/dev/null || true

    # Gather Python environments
    pip list > "$BASE_PROFILE/pip-packages.txt" 2>/dev/null || true
    conda env list > "$BASE_PROFILE/conda-envs.txt" 2>/dev/null || true

    # Gather installed Ollama models
    ollama list > "$BASE_PROFILE/ollama-models.txt" 2>/dev/null || true

    # System info
    uname -a > "$BASE_PROFILE/system-info.txt"
    lscpu | grep -E "Model name|CPU\(s\)|Thread" > "$BASE_PROFILE/cpu-info.txt" 2>/dev/null || true
    free -h > "$BASE_PROFILE/memory-info.txt" 2>/dev/null || true

    # Key dotfiles
    mkdir -p "$BASE_PROFILE/dotfiles"
    for dotfile in .bashrc .zshrc .profile .gitconfig .vimrc .tmux.conf; do
        if [ -f "$HOME/$dotfile" ]; then
            cp "$HOME/$dotfile" "$BASE_PROFILE/dotfiles/" 2>/dev/null || true
        fi
    done

    echo -e "${GREEN}✓ Base profile gathered${NC}"
}

# Function to gather remote (laptop) profile
gather_remote_profile() {
    echo -e "${BLUE}Gathering remote (laptop) environment profile...${NC}"

    if ! check_laptop_connectivity; then
        echo -e "${YELLOW}Cannot gather remote profile - laptop not reachable${NC}"
        return 1
    fi

    mkdir -p "$REMOTE_PROFILE"

    # Gather installed packages from laptop
    ssh laptop "dpkg -l" > "$REMOTE_PROFILE/dpkg-packages.txt" 2>/dev/null || true
    ssh laptop "apt list --installed" > "$REMOTE_PROFILE/apt-packages.txt" 2>/dev/null || true
    ssh laptop "snap list" > "$REMOTE_PROFILE/snap-packages.txt" 2>/dev/null || true
    ssh laptop "flatpak list --app" > "$REMOTE_PROFILE/flatpak-packages.txt" 2>/dev/null || true

    # Gather Python environments
    ssh laptop "pip list" > "$REMOTE_PROFILE/pip-packages.txt" 2>/dev/null || true
    ssh laptop "conda env list" > "$REMOTE_PROFILE/conda-envs.txt" 2>/dev/null || true

    # Gather installed Ollama models
    ssh laptop "ollama list" > "$REMOTE_PROFILE/ollama-models.txt" 2>/dev/null || true

    # System info
    ssh laptop "uname -a" > "$REMOTE_PROFILE/system-info.txt"
    ssh laptop "lscpu | grep -E 'Model name|CPU\(s\)|Thread'" > "$REMOTE_PROFILE/cpu-info.txt" 2>/dev/null || true
    ssh laptop "free -h" > "$REMOTE_PROFILE/memory-info.txt" 2>/dev/null || true

    # Key dotfiles
    mkdir -p "$REMOTE_PROFILE/dotfiles"
    for dotfile in .bashrc .zshrc .profile .gitconfig .vimrc .tmux.conf; do
        scp "laptop:$dotfile" "$REMOTE_PROFILE/dotfiles/" 2>/dev/null || true
    done

    echo -e "${GREEN}✓ Remote profile gathered${NC}"
}

# Function to invoke Claude CLI with the sync agent
invoke_sync_agent() {
    echo -e "${BLUE}Invoking Claude CLI sync agent...${NC}"

    # Create a temporary request file for Claude
    local REQUEST_FILE=$(mktemp)

    cat > "$REQUEST_FILE" << EOF
I need you to act as a Desktop-to-Laptop Environment Sync Agent.

Please read the system prompt from: $SYSTEM_PROMPT

Then analyze the environment profiles stored in:
- Base (desktop): $BASE_PROFILE/
- Remote (laptop): $REMOTE_PROFILE/

Based on the system prompt instructions and the profiles, please:
1. Identify packages that should be synced from desktop to laptop
2. Identify packages that should be removed from laptop (no longer on desktop)
3. Identify dotfile changes that should be synced
4. Be hardware-aware - don't recommend syncing resource-intensive packages to the less capable laptop
5. Provide a clear action plan with commands to execute

Remember: The goal is incremental sync, not perfect replication. Focus on key tools and configurations that would be valuable on the laptop.

When making recommendations, consider:
- The hardware capabilities shown in cpu-info.txt and memory-info.txt
- Whether packages are essential tools vs. resource-heavy applications
- The user's workflow and which tools are most important

Please analyze and provide your recommendations.
EOF

    # Invoke Claude CLI with the request
    # The agent will have access to the system prompt and profile files
    echo -e "${YELLOW}Starting Claude CLI analysis...${NC}"
    echo ""

    cat "$REQUEST_FILE" | claude --dangerously-skip-user-approval

    # Clean up
    rm -f "$REQUEST_FILE"

    echo ""
    echo -e "${GREEN}Analysis complete. Review recommendations above.${NC}"
}

# Function to show usage
usage() {
    echo "Desktop-to-Laptop Environment Sync Agent"
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --gather-profiles    Gather both base and remote profiles"
    echo "  --gather-base        Gather only base (desktop) profile"
    echo "  --gather-remote      Gather only remote (laptop) profile"
    echo "  --sync               Run the sync analysis (invokes Claude CLI agent)"
    echo "  --full               Gather profiles and run sync (default)"
    echo "  --help               Show this help message"
    echo ""
    exit 0
}

# Main execution
main() {
    local MODE="full"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --gather-profiles)
                MODE="gather-profiles"
                shift
                ;;
            --gather-base)
                MODE="gather-base"
                shift
                ;;
            --gather-remote)
                MODE="gather-remote"
                shift
                ;;
            --sync)
                MODE="sync"
                shift
                ;;
            --full)
                MODE="full"
                shift
                ;;
            --help)
                usage
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                usage
                ;;
        esac
    done

    echo -e "${GREEN}=== Desktop-to-Laptop Environment Sync Agent ===${NC}"
    echo ""

    case $MODE in
        gather-base)
            gather_base_profile
            ;;
        gather-remote)
            gather_remote_profile
            ;;
        gather-profiles)
            gather_base_profile
            gather_remote_profile
            ;;
        sync)
            invoke_sync_agent
            ;;
        full)
            gather_base_profile
            gather_remote_profile
            invoke_sync_agent
            ;;
    esac

    echo ""
    echo -e "${GREEN}=== Sync Agent Complete ===${NC}"
}

main "$@"
