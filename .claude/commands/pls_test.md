---
name: pls_test
description: Generate Ruby tests for specific files or uncommitted changes
arguments:
  - name: file_path
    description: Path to file to test (optional, defaults to uncommitted changes)
    required: false
---

# Ruby Test Generator

This command generates comprehensive Ruby tests following project conventions and best practices.

## Usage

```
/pls_test                        # Generate tests for uncommitted changes
/pls_test app/models/user.rb     # Generate tests for specific file
/pls_test lib/services/auth.rb   # Generate tests for service class
```

## What it does

1. Analyzes the target code (file or uncommitted changes)
2. Examines existing test patterns in the codebase
3. Generates tests that match project conventions
4. Creates meaningful test cases with clear descriptions
5. Outputs tests to appropriate test file location

## Test Generation Principles

### Ruby Best Practices

- Use descriptive test names that explain behavior
- Follow AAA pattern (Arrange, Act, Assert)
- Test behavior, not implementation
- Prefer integration over unit tests where sensible
- Use factories or fixtures consistently with project

### Mocking Philosophy

- Avoid unnecessary mocking
- Mock external dependencies only
- Prefer real objects and database transactions
- Use stubs sparingly for expensive operations
- Never mock the system under test

### Coverage Guidelines

- Test happy path thoroughly
- Include edge cases and boundary conditions
- Test error handling and exceptions
- Validate data transformations
- Check side effects where applicable

## Output Structure

Tests will follow the existing project structure:

- RSpec: `describe/context/it` blocks
- Minitest: `class/def test_` methods
- Test names clearly describe expected behavior
- Setup/teardown follows project patterns
- Assertions use project's preferred matchers

## Requirements

- Must identify test framework (RSpec, Minitest, etc.)
- Should analyze existing test files for patterns
- Output saved to appropriate spec/ or test/ directory
- Follows project's test file naming convention

## Examples

For a User model, generates tests like:

- Valid/invalid record creation
- Associations and validations
- Scopes and class methods
- Instance methods and callbacks
- Edge cases for business logic

For a service object, generates tests like:

- Success and failure paths
- Input validation
- Expected return values
- Side effects (emails, jobs, etc.)
- Error handling scenarios

## Notes

- Matches indentation and style of existing tests
- Uses existing factories, fixtures, or helpers
- Includes necessary test setup/teardown
- Comments only for complex setup scenarios
- Focuses on readability and maintainability

ARGUMENTS: $ARGUMENTS
