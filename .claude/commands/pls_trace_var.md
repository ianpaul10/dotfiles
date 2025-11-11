---
description: Trace a variable through the request lifecycle with logging
argument-hint: <variable_name> [file:line]
allowed-tools: Read, Grep, Glob, Edit, Bash(git:*)
---

# Variable Tracing with Lifecycle Logging

Trace the variable **$1** through the request lifecycle and add strategic logging statements.

## Starting Point

$2

## Tracing Strategy

1. **Identify the starting point**:

   - If file:line provided, start there
   - Otherwise, search for the variable in the current working area

2. **Trace upstream (callers)**:

   - Find where this method/controller action is called
   - Track how the variable is passed in
   - Trace back through middleware, routing, and entry points

3. **Trace downstream (callees)**:

   - Find all places where this variable is:
     - Passed to other methods
     - Modified or transformed
     - Used in conditionals or operations
     - Stored in database/cache
     - Returned or rendered

4. **Add logging at each critical point**:
   - Variable initialization/receipt
   - Before/after transformations
   - When passed to other methods
   - Before persistence operations
   - Before returning/rendering

## Logging Format

Use this exact format for ALL logging statements:

```ruby
Rails.logger.info("[BANANA] [#{Time.current.strftime('%H:%M:%S.%6N')}] #{__FILE__}:#{__LINE__} $1=#{$1.inspect}")
```

For objects with relevant attributes, include them:

```ruby
Rails.logger.info("[BANANA] [#{Time.current.strftime('%H:%M:%S.%6N')}] #{__FILE__}:#{__LINE__} $1=#{$1.inspect} (id: #{$1.id}, status: #{$1.status})")
```

For nil/error cases:

```ruby
Rails.logger.info("[BANANA] [#{Time.current.strftime('%H:%M:%S.%6N')}] #{__FILE__}:#{__LINE__} $1=#{$1.inspect} [UNEXPECTED NIL]")
```

## Key Logging Points

- **Controller entry**: Log when variable first appears
- **Service/model boundaries**: Log when crossing into different layers
- **Transformations**: Log before and after value changes
- **Conditionals**: Log in each branch that uses the variable
- **Database operations**: Log before save/update/destroy
- **Response**: Log final value before rendering

## Execution Steps

1. Read the starting file to understand context
2. Search for all references to the variable name
3. Build a map of the request flow
4. Add logging statements at strategic points
5. Verify no syntax errors introduced
6. Create a commit with ONLY the logging changes:

```bash
git add -A
git commit -m "$(cat <<'EOF'
feat: add trace logging for $1

Adds [BANANA] logging statements to trace $1 through request lifecycle.
Can be grepped with: grep '\[BANANA\]' log/development.log

To revert: git revert HEAD

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

## Output Format

After completion, provide:

1. Summary of all files modified
2. Number of logging statements added
3. The git commit SHA
4. Command to view logs: `grep '\[BANANA\]' log/development.log | sort`
5. Command to revert: `git revert <SHA>`

## Notes

- Only add logs where they provide value (don't spam every line)
- Focus on transitions between layers and transformations
- Ensure logs are readable and contain useful context
- Keep variable inspection safe (use `.inspect` to handle nil)
