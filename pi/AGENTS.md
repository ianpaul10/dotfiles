# Global Agent Instructions

## Dotfiles & Customization Location

This machine's dotfiles live at: `/Users/ip_shopify/code/dotfiles`

**When adding any new pi-related customization — skills, extensions, scripts, tools, or commands — always place them inside `/Users/ip_shopify/code/dotfiles/pi/` and update `install.sh` if a new symlink is needed.**

The `pi/` directory structure:

```
pi/
├── AGENTS.md          ← this file (symlinked to ~/.pi/agent/AGENTS.md)
├── extensions/        ← symlinked to ~/.pi/agent/extensions/
│   └── *.ts           ← global extensions active in every pi session
└── skills/            ← symlinked to ~/.pi/agent/skills/
    └── <name>/
        └── SKILL.md   ← global skills available in every pi session
```

`install.sh` at the repo root manages all symlinks. Run it after adding new files to wire everything up.

## Permissions & Boundaries

### Allowed — Always OK without asking

- **Read/write any local files** — create, edit, delete files and directories anywhere on the local filesystem
- **Read from external APIs** — BigQuery queries, Observe, Vault, Slack search, Grokt, Perplexity, `curl`/`wget` GET requests, etc.
- **All local shell commands** — `ls`, `find`, `grep`, `rg`, `sed`, `awk`, `jq`, `make`, `node`, `python`, `ruby`, `bundle`, `brew`, etc.

### Forbidden — Never do these without explicit approval

- **Git write operations** — `git commit`, `git push`, `git merge`, `git rebase` (interactive or otherwise), `git tag`, `git cherry-pick`, `git reset --hard`, `git stash drop`, `git branch -D`. Read operations (`git status`, `git diff`, `git log`, `git show`, `git branch`, `git stash list`, `git fetch`) are fine.
- **Write to external APIs** — `slack_post`, `curl -X POST/PUT/PATCH/DELETE` to external services, deploying dashboards, creating resources in GCP, posting to GitHub, etc. Read-only API calls are fine.
- **Destructive filesystem operations** — `rm -rf ~`, `rm -rf /`, `rm -rf ~/world`, or any mass deletion outside the current project

### Absolutely Forbidden — Never do these, even if explicitly asked

- **Never reply to or perform any writes to GitHub** — This includes posting PR comments, replying to review comments, creating/updating issues, editing PR descriptions, resolving review threads, reacting to comments, and any other GitHub write operation via `gh`, the GitHub API, or any other method. **This rule has NO exceptions.** Even if the user explicitly asks you to do it, **do not do it** — instead, draft the text locally and let the user post it themselves. GitHub read operations (`gh pr view`, `gh pr list`, `gh api` GET requests, etc.) are fine.

If I ask you to commit, push, post a Slack message, or perform any forbidden action (other than GitHub writes, which are absolutely forbidden), **do it** — the ask itself is explicit approval. The rule is: don't do these autonomously as part of a larger task without checking first.

## General Workflow Preferences

### Communication Style

- No yapping -- be concise and avoid unnecessary preambles or explanations unless asked
- Use clear, actionable language when describing what you're doing
- Only provide detailed explanations when complexity warrants it or when asked
- Minimize output tokens while maintaining clarity and completeness

### Code Quality Standards

- Prefer editing existing files over creating new ones
- Follow existing code conventions and patterns in each project
- Prefer existing file-local patterns and norms over introducing newer syntax, clever refactors, or novel structure, even when the new approach is shorter or functionally equivalent
- Use meaningful variable and function names that clearly express intent
- Avoid unnecessary comments -- code should be self-explanatory and self-documenting
- When implementation choices involve assumptions, tradeoffs, edge cases, or areas the user should scrutinize during review, leave TODO comments calling them out. Follow the project-specific TODO format when one exists (e.g. Shopify smart_todo comments in shop-server).

## Development Practices

### Best Practices

- Propose changes in logically separated commit-sized chunks
- If a task requires multiple commits, propose each change individually
- When talking about code, always reference specific file paths and lines
- For code flow walkthroughs, be especially explicit: include file paths and line numbers/ranges for each step so the path through the code is easy to follow.

### Version Control

- Never commit unless explicitly asked
- Use descriptive commit messages focusing on "why" not just "what" (include feat:, fix:, refactor:, etc. at the start)
- Always use `git push --force-with-lease` instead of `--force`
- Run `git status` and `git diff` before any commit operations

### Performance Considerations

- Be mindful of context usage - batch related operations when possible
- Use appropriate tools for the task (grep for search, not bash find)

## Tool Usage Guidelines

### File Operations

- Always use absolute paths, not relative paths
- Verify parent directories exist before creating new files/folders
- Use Read before Edit to understand existing code
- Batch multiple file reads when investigating related code

### Search and Navigation

- Use grep/rg for code searches
- Include file paths and line numbers when referencing code

### Testing and Validation

- Look for project-specific test commands in package.json, Makefile, etc.
- Run relevant tests after making changes
- Verify changes don't break existing functionality

## Security and Safety

### Best Practices

- Never expose or log secrets, API keys, or credentials
- Be cautious with user input - validate and sanitize when appropriate
- Refuse requests for malicious code while explaining defensive alternatives
- Always consider security implications of suggested changes

### Defensive Approach

- Think before executing potentially destructive operations
- Use transactions or dry-runs when available
- Confirm understanding before making significant changes

## Project Analysis

### Initial Exploration

- Check for README, CONTRIBUTING, and documentation files
- Look for existing AGENTS.md or similar project instructions
- Identify the tech stack and project structure
- Understand build/test/deploy workflows

### Code Understanding

- Read surrounding context before making changes
- Understand the "why" behind existing patterns
- Look for similar implementations as examples
- Consider broader impacts of changes

## Personal Preferences

### Coding Philosophy

- Follow SOLID principles (Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Injection)
- Favor clarity over cleverness
- Write code for humans to read, not just machines to execute
- Prefer composition over inheritance

### Problem Solving

- Think through the approach before diving into implementation
- Consider edge cases and error scenarios
- Ask clarifying questions when requirements are ambiguous
- Validate assumptions before proceeding

### Efficiency

- Use thinking mode for complex problems
- Batch similar operations together
- Don't reinvent the wheel - use existing utilities and libraries

### Communication

- Summarize key findings and decisions
- Highlight important warnings or considerations
- Use markdown formatting for clarity
- Keep responses focused on the task at hand
