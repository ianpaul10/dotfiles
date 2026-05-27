---
name: pls_write_a_pr
description: Generate a PR description from recent commits and changes
arguments:
  - name: branch
    description: Target branch name (optional, defaults to current branch)
    required: false
---

# PR Description Generator

This command analyzes recent commits and changes to generate a professional pull request description.

## Usage

```
/pls_write_a_pr
/pls_write_a_pr feature-branch
```

## What it does

1. Analyzes git diff and recent commits in the repository
2. Extracts key changes and their purpose
3. Generates a structured PR description following team conventions
4. Saves the output to a temp file for easy copying

## Output Format

The command generates a PR description with these exact sections

```
### TL;DR

A 1-2 sentence summary of the changes

### What

- Bullet points summarizing the changes
- No verbose descriptions
- Focus on what was modified, added, or removed. If relevant, give specific files or components affected.

### Why

- Bullet points explaining the necessity
- Rationale for the chosen approach
- Business or technical justification

### PagerDuty

`@spy page shop-network`
```

## Requirements

- Must be run in a git repository
- Should have uncommitted changes or recent commits to analyze
- Output saved to `/tmp/pr-description-[timestamp].md`

## Notes

- No fancy formatting (bold, italics, etc.), but you can use `code_formatting` for file names, functions, or specific terms
- Concise bullet points preferred
- Use a professional tone 
- Most important: no yapping

ARGUMENTS: $ARGUMENTS
