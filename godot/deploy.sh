#!/bin/bash

# Alien Invaders - Web Deploy Script
# Usage:
#   ./deploy.sh           - export and push to gh-pages branch (GitHub Pages)
#   ./deploy.sh --local   - export and serve locally at http://localhost:8080

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

LOCAL_MODE=false
if [[ "$1" == "--local" ]]; then
    LOCAL_MODE=true
fi

echo "🎮 Alien Invaders - Web Deploy"
echo "=============================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Find Godot executable
GODOT_PATH="/Applications/Godot.app/Contents/MacOS/Godot"
if [ ! -x "$GODOT_PATH" ]; then
    if command -v godot &> /dev/null; then
        GODOT_PATH="godot"
    else
        echo "❌ Error: Godot not found"
        echo "Please install Godot from https://godotengine.org/download"
        exit 1
    fi
fi

# For local mode use a fixed persistent dir; for gh-pages use a temp dir
if $LOCAL_MODE; then
    EXPORT_DIR="$HOME/.cache/alien-invaders-web"
    mkdir -p "$EXPORT_DIR"
else
    EXPORT_DIR=$(mktemp -d)
    trap "rm -rf $EXPORT_DIR" EXIT
fi

echo -e "${BLUE}1. Exporting to HTML5...${NC}"
"$GODOT_PATH" --path . --export-release "Web" "$EXPORT_DIR/index.html" 2>&1 | grep -v "^$" || true

if [ ! -f "$EXPORT_DIR/index.html" ]; then
    echo "❌ Export failed: index.html not created"
    exit 1
fi

echo -e "${GREEN}✓ Export complete${NC}"
echo ""

# --- Local serve mode ---
if $LOCAL_MODE; then
    PORT=8080
    echo -e "${GREEN}✓ Serving at http://localhost:${PORT}${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop.${NC}"
    echo ""
    cd "$EXPORT_DIR"
    python3 -m http.server "$PORT"
    exit 0
fi

# --- GitHub Pages deploy mode ---
REPO_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

echo -e "${BLUE}2. Checking git status...${NC}"
if ! git -C "$REPO_DIR" status > /dev/null 2>&1; then
    echo "❌ Error: Not a git repository"
    exit 1
fi

echo -e "${BLUE}3. Updating gh-pages branch...${NC}"
cd "$REPO_DIR"

COMMIT_MSG="Deploy: Updated web build $(date +%Y-%m-%d\ %H:%M:%S)"

WORKTREE_DIR=$(mktemp -d)
trap "rm -rf $EXPORT_DIR $WORKTREE_DIR" EXIT

if git show-ref --quiet refs/heads/gh-pages; then
    git worktree add "$WORKTREE_DIR" gh-pages
else
    git worktree add --orphan -b gh-pages "$WORKTREE_DIR"
fi

rm -rf "$WORKTREE_DIR"/*
cp "$EXPORT_DIR"/* "$WORKTREE_DIR/"

cd "$WORKTREE_DIR"
git add -A
git commit -m "$COMMIT_MSG" || echo "ℹ️  No changes to commit"

cd "$REPO_DIR"
git worktree remove --force "$WORKTREE_DIR"

echo -e "${BLUE}4. Pushing to GitHub...${NC}"
git push origin gh-pages

echo ""
echo -e "${GREEN}✓ Deployment complete!${NC}"
echo ""
echo -e "${YELLOW}Your game is now live at:${NC}"
echo "https://lex3001.github.io/AlienInvaders/"
