---
name: gokbeet
description: Summarize daily notes into Geekbot standup format
arguments:
  - name: todays_date
    description: Date in YYYY_MM_DD format
    required: true
  - name: previous_date
    description: Date in YYYY_MM_DD format
    required: true
---

# Geekbot Standup Summary Generator

This command reads your daily notes and generates a professional geekbot standup summary.

## Usage

```
/gokbeet 2024_12_20 2024_12_19
```

## What it does

1. Reads the daily note from `~/code/brain_dump/daily/{todays_date}.md`
2. Reads the daily note from the previous day `~/code/brain_dump/daily/{previous_date}.md`
3. Separates TODO items (lines that start with TODO) from completed items (lines that DO NOT start with TODO) for today and yesterday
4. Generates a clean, professional summary for Geekbot
5. Saves the output to a temp file for easy copying

## Output Format

The command will:

- Use conversational language
- Keep the summary brief and professional. No yapping.
- List yesterday's non-TODO items as completed tasks from the day under a '## Here's what I did yesterday' section
- List yesterday's TODO items as tasks that were also completed yesterday under the same section (if there are no or very few completed tasks)
- List today's TODO items as tasks planned for today under a '## Here's what I plan to do today' section
- Preserve links in markdown format (e.g. [link text](url)) and use helpful link_text where possible
- Use code formatting where appropriate (e.g. `code_snippet`)
- Logically group together items that are seemingly related into sub bullet points (e.g. all code reviews can be grouped together). If there is only one sub bullet point, don't use a sub bullet point.
- Write the summary into a markdown file in this path with this type of file name: `~/code/brain_dump/daily/gokbeet_output/gokbeet_{todays_date}.md`
