#!/bin/bash
# Read JSON input once
input=$(cat)

# Extract the fields this line renders from the statusline JSON on stdin.
# Many more are available (.version, .cost.*, .output_style.name, .agent.name — see the
# Claude Code statusLine docs); add a getter here and append it below to surface one.
get_model_name() { echo "$input" | jq -r '.model.display_name'; }
get_current_dir() { echo "$input" | jq -r '.workspace.current_dir'; }
get_project_dir() { echo "$input" | jq -r '.workspace.project_dir'; }
get_worktree() {
    local name=$(echo "$input" | jq -r '.workspace.git_worktree.name // empty')
    if [ -n "$name" ]; then
        echo " | 🌴 $name"
    fi
}
get_git_branch() {
    local project_dir=$(get_project_dir)
    local git_branch=""
    if [ -n "$project_dir" ] && cd "$project_dir" 2>/dev/null; then
        if git rev-parse --git-dir > /dev/null 2>&1; then
            local branch=$(git branch --show-current 2>/dev/null)
            if [ -n "$branch" ]; then
                git_branch=" | 🌿 $branch"
            fi
        fi
    fi
    echo "$git_branch"
}

# Use the helpers
MODEL=$(get_model_name)
DIR=$(get_current_dir)

# Show path relative to git root if in a repo, otherwise just the dir name
GIT_ROOT=$(git -C "$DIR" rev-parse --show-toplevel 2>/dev/null)
if [ -n "$GIT_ROOT" ]; then
    REPO_NAME=${GIT_ROOT##*/}
    if [ "$DIR" = "$GIT_ROOT" ]; then
        DISPLAY_DIR="$REPO_NAME"
    else
        DISPLAY_DIR="$REPO_NAME/${DIR#$GIT_ROOT/}"
    fi
else
    DISPLAY_DIR="${DIR##*/}"
fi

GIT_BRANCH=$(get_git_branch)
WORKTREE=$(get_worktree)
echo "[$MODEL] 📁 $DISPLAY_DIR$GIT_BRANCH$WORKTREE"