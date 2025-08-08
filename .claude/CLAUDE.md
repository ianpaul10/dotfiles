# Global Claude Code Instructions

## General Workflow Preferences

### Communication Style

- No yapping -- be concise and avoid unnecessary preambles or explanations unless asked
- Use clear, actionable language when describing what you're doing
- Only provide detailed explanations when complexity warrants it or when asked
- Minimize output tokens while maintaining clarity and completeness

### Task Management

- Use TodoWrite for any complex task with 3+ steps or complex workflows
- Mark tasks as in_progress BEFORE starting work
- Complete tasks immediately after finishing - don't batch updates

### Code Quality Standards

- Prefer editing existing files over creating new ones
- Follow existing code conventions and patterns in each project
- Use meaningful variable and function names that clearly express intent
- Avoid unnecessary comments -- code should be self-explanatory and self-documenting

## Development Practices

### Best Practices

- Propose changes in logically separated commit-sized chunks
- If a task requires multiple commits, propose each change individually
- When talking about code, always reference specific file paths and lines

### Version Control

- Never commit unless explicitly asked
- Use descriptive commit messages focusing on "why" not just "what" (include feat:, fix:, refactor:, etc. at the start)
- Always use `git push --force-with-lease` instead of `--force`
- Run `git status` and `git diff` before any commit operations

### Performance Considerations

- Be mindful of context usage - batch related operations when possible
- Use appropriate tools for the task (grep for search, not bash find)
- Clear context with /clear when starting new unrelated tasks

## Tool Usage Guidelines

### File Operations

- Always use absolute paths, not relative paths
- Verify parent directories exist before creating new files/folders
- Use Read before Edit to understand existing code
- Batch multiple file reads when investigating related code

### Search and Navigation

- Use Grep for code searches, not bash grep/find commands
- Use Glob for file pattern matching
- Use Task tool for complex multi-step searches
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
- Look for existing CLAUDE.md or similar project instructions
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

## Productivity Tips

### Efficiency

- Use thinking mode ("think", "think hard") for complex problems
- Batch similar operations together
- Leverage visual capabilities for UI/UX tasks
- Don't reinvent the wheel - use existing utilities and libraries

### Communication

- Summarize key findings and decisions
- Highlight important warnings or considerations
- Use markdown formatting for clarity
- Keep responses focused on the task at hand

