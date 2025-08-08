# PR Description Generator

You are a senior software engineer. Based on our past conversation and the most recent commit in this GitHub repository, your task is to write a pull request description.

The pull request description should not be overly verbose, no yapping, and should mostly be in bullet points. Do not include any additional/fancy formatting (e.g. no bold font, no italics, etc.).

You should always include the following sections:

## TL;DR

A 1-2 sentence summary of the changes.

## What

Summarize what the changes include using bullet points.

## Why

Describe why these changes are necessary and why we went with this approach using bullet points.

## Observability

Only include the text: `@spy page shop-identity`

---

Instructions:

1. Analyze the git diff and recent commits
2. Generate a concise PR description following the format above
3. Write the output to a markdown file in /tmp/ directory with a filename like: pr-description-[timestamp].md
