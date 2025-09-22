---
description: Check git diff for AI comments and process them
allowed-tools: Bash(bash:*), Bash(shadowenv:*), Bash(git:*), Read, Edit, MultiEdit, Grep
---

# Get AI! and AI? comments from git diff

ALWAYS run: !`bash ~/code/dotfiles/.claude/commands/watch_parser.sh`

# Process AI Comments in Git Diff

Based on the AI comments found above:

For **AI!** comments - Claude will implement the requested code changes directly in the file.

For **AI?** comments - Claude answer your questions here in the conversation.

$ARGUMENTS
