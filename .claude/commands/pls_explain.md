---
name: pls_explain
description: Deep technical explanation of code at file or line level
arguments:
  - name: target
    description: File path or file:line (e.g., app/models/user.rb:42)
    required: true
---

# Deep Code Explainer

This command provides comprehensive technical explanations of code, diving deep into implementation details, design patterns, and system interactions.

## Usage

```
/pls_explain app/models/user.rb          # Explain entire file
/pls_explain app/models/user.rb:42       # Explain specific line/method
/pls_explain lib/auth/jwt.rb:15-30      # Explain line range
```

## What it does

1. Reads the target file and surrounding context
2. Analyzes dependencies and related files
3. Traces execution flow and data transformations
4. Identifies patterns, algorithms, and architectural decisions
5. Explains technical implications and trade-offs

## Analysis Depth

### Code Structure

- Class/module hierarchy and inheritance chain
- Method signatures and parameter handling
- Return values and side effects
- Exception handling and error flows
- Memory management and performance implications

### Technical Details

- Algorithm complexity (time/space)
- Data structure choices and implications
- Concurrency/threading considerations
- Database queries and N+1 problems
- Network calls and API interactions

### System Context

- Dependencies and coupling
- Design patterns employed
- Framework-specific magic/conventions
- Metaprogramming and dynamic behavior
- Security implications

### Runtime Behavior

- Execution order and control flow
- State mutations and transformations
- Callback chains and hooks
- Event propagation
- Resource lifecycle

## Explanation Format

The explanation will include:

### Overview

High-level purpose and responsibility

### Line-by-Line Breakdown

- What each line/block does
- Why it's implemented this way
- Alternative approaches considered
- Performance/security implications

### Data Flow

- Input sources and validation
- Transformation pipeline
- Output destinations
- Error propagation paths

### Integration Points

- External dependencies
- Database interactions
- Cache usage
- Queue/job processing
- API calls

### Gotchas & Edge Cases

- Non-obvious behavior
- Framework magic
- Hidden assumptions
- Potential bugs or race conditions
- Upgrade/migration concerns

## Special Focus Areas

### For Ruby/Rails Code

- Metaprogramming techniques
- ActiveRecord callbacks and associations
- Middleware and Rack integration
- Lazy loading and eager loading
- Module mixins and concerns

### For Complex Logic

- State machines
- Recursive algorithms
- Concurrent operations
- Transaction boundaries
- Distributed system concerns

### For Performance-Critical Code

- Query optimization
- Caching strategies
- Memory allocation
- Background job design
- Rate limiting

## Output Examples

For a specific line like `User.includes(:posts).where(active: true).find_each`:

- Explains eager loading strategy
- Details batch processing with find_each
- Memory implications of includes vs joins
- Query execution plan
- N+1 prevention technique
- When this approach fails

For a method with metaprogramming:

- How define_method works
- Method resolution order
- Performance vs flexibility trade-offs
- Debugging challenges
- Testing considerations

## Requirements

- Must read file and surrounding context
- Should trace through related files
- Identifies framework/library specific behavior
- Explains both what and why
- Highlights non-obvious implications

## Notes

- Technical depth over surface-level description
- Assumes reader has programming knowledge
- Includes performance and security considerations
- References documentation when relevant
- Explains historical context if apparent

ARGUMENTS: $ARGUMENTS
