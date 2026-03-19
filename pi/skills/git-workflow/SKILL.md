---
name: git-workflow
description: Opinionated git workflow helpers for this dotfiles environment. Use when creating commits, writing PR descriptions, rebasing branches, or cleaning up git history. Follows conventional commits format and enforces clean, atomic commits.
---

# Git Workflow

Opinionated git helpers for keeping a clean history.

## Commit Style

Always use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(optional scope): <short summary>

[optional body]

[optional footer]
```

**Types:** `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `style`, `ci`

## Common Workflows

### Staging & Committing

```bash
git add -p                    # interactively stage hunks (prefer over `git add .`)
git commit                    # opens editor for full message
git commit -m "feat: ..."     # inline for short messages
```

### Branch Hygiene

```bash
git fetch --prune             # clean up stale remote refs
git branch --merged | grep -v '^\*\|main\|master' | xargs git branch -d
```

### Safe Interactive Rebase

```bash
git rebase -i HEAD~<n>        # squash/reword last n commits
git rebase -i origin/main     # rebase onto main
```

> Always rebase on a clean working tree. Stash uncommitted changes first with `git stash`.

### PR Description Template

When writing a PR description, structure it as:

```
## What

<one-sentence summary of the change>

## Why

<motivation / context>

## How

<notable implementation details, if non-obvious>

## Testing

<how was this verified>
```
