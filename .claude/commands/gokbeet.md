---
name: gokbeet
description: Summarize daily notes into Geekbot standup format
arguments:
  - name: date
    description: Date in YYYY-MM-DD format
    required: true
---

# Geekbot Standup Summary Generator

This command reads your daily notes and generates a professional standup summary.

## Usage

```
/gokbeet 2024-12-20
```

## What it does

1. Reads the daily note from ~/code/brain_dump/daily/{date}.md
2. Separates TODO items (things to do today) from completed items
3. Generates a clean, professional summary for Geekbot
4. Saves the output to a temp file for easy copying

## Output Format

The command will:

- List completed items from the day
- List TODO items as things planned for today
- Preserve links in markdown format
- Use code formatting where appropriate
- Keep the summary brief and professional
