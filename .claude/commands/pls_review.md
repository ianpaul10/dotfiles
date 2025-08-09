---
name: pls_review
description: Review code changes with Ruby best practices feedback
arguments:
  - name: target
    description: "uncommitted" for staged changes or "HEAD" for last commit
    required: true
---

# Ruby Code Review Assistant

This command reviews your changes with a focus on Ruby idioms and best practices, helping experienced engineers level up their Ruby skills.

## Usage

```
/pls_review uncommitted         # Review staged/unstaged changes
/pls_review HEAD                # Review the last commit
/pls_review HEAD~2              # Review the last 2 commits
/pls_review ./path/to/file.rb   # Review this file
```

## What it does

1. Analyzes the diff for the specified target
2. Reviews code for Ruby idioms and conventions
3. Suggests more idiomatic Ruby alternatives
4. Identifies potential bugs and edge cases
5. Provides actionable feedback for improvement

## Review Focus Areas

### Ruby Idioms & Style

- More elegant Ruby alternatives to verbose code
- Proper use of blocks, procs, and lambdas
- Enumerable methods over manual loops
- Symbol vs string usage
- Duck typing opportunities
- Guard clauses vs nested conditionals

### Common Ruby Patterns

- Use of `||=` for memoization
- Tap, then, and method chaining
- Safe navigation operator (`&.`)
- Hash default values and fetch
- Splat operators and keyword arguments
- Module composition over inheritance

### Rails Conventions (if applicable)

- ActiveRecord query optimizations
- Proper use of scopes vs class methods
- Callback usage and alternatives
- Service object patterns
- Strong parameters best practices
- Rails helpers and concerns

### Performance Considerations

- N+1 query detection
- Unnecessary database calls
- Memory-efficient iterations
- Lazy evaluation opportunities
- Caching candidates
- Background job candidates

### Code Smells to Flag

- Long methods (Ruby methods should be small)
- Too many instance variables
- Feature envy between classes
- Data clumps that should be objects
- Primitive obsession
- Tell, don't ask violations

## Review Output Format

### 🟢 Strengths

Things done well that show good Ruby understanding

### 🟡 Suggestions

Ruby-specific improvements with examples:

```ruby
# Current approach
result = []
items.each do |item|
  result << item.name if item.active?
end

# More idiomatic Ruby
result = items.select(&:active?).map(&:name)
```

### 🔴 Issues

Potential bugs or anti-patterns:

- Missing nil checks
- Race conditions
- Security concerns
- Test coverage gaps

### 📚 Learning Opportunities

Ruby concepts to explore further:

- Links to Ruby style guides
- Relevant metaprogramming techniques
- Framework-specific features
- Performance optimization techniques

## Feedback Philosophy

### Constructive & Educational

- Explains WHY something is more idiomatic
- Shows before/after comparisons
- References Ruby community standards
- Celebrates good Ruby patterns used

### Practical & Actionable

- Prioritizes high-impact improvements
- Provides copy-paste alternatives
- Groups similar issues together
- Suggests refactoring strategies

### Growth-Oriented

- Points out Ruby-specific gotchas
- Highlights language features to explore
- Recommends relevant gems/tools
- Shares debugging techniques

## Examples of Feedback

### Method Definition

```ruby
# Your code
def get_user_name(user_id)
  user = User.find(user_id)
  return user.name
end

# More idiomatic
def user_name(user_id)
  User.find(user_id).name
end
# - Drop 'get_' prefix (Ruby convention)
# - Implicit return is preferred
# - Consider nil safety with &.name
```

### Collection Processing

```ruby
# Your code
users.map { |u| u.email }.select { |e| e != nil }

# More idiomatic
users.filter_map(&:email)
# - filter_map combines map + compact
# - Symbol-to-proc is cleaner
```

### Conditional Logic

```ruby
# Your code
if user != nil && user.active == true
  process(user)
end

# More idiomatic
process(user) if user&.active?
# - Use safe navigation (&.)
# - Predicate methods (active?)
# - Modifier if for simple conditions
```

## Requirements

- Git repository with changes to review
- Focuses on Ruby/Rails code improvements
- Saves detailed review to temp file
- Highlights Ruby learning opportunities

## Notes

- Assumes strong engineering background
- Focuses on Ruby-specific improvements
- Celebrates good patterns already in use
- Provides resources for continued learning
- Non-patronizing, peer-to-peer tone

ARGUMENTS: $ARGUMENTS
