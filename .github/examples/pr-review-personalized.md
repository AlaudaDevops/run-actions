# Repository-Specific PR Review Guidelines

> Copy this file to `.github/prompts/pr-review.md` in your repository and customize it for your project.

## Project Overview

<!-- Describe your project briefly -->
This is a [brief description of your project].

## Tech Stack

<!-- List your main technologies -->
- Language: [e.g., Go, TypeScript, Python]
- Framework: [e.g., Gin, React, Django]
- Database: [e.g., PostgreSQL, MongoDB]
- Other: [e.g., Kubernetes, Docker]

## Code Standards

### Naming Conventions
<!-- Describe your naming conventions -->
- Use camelCase for variables and functions
- Use PascalCase for types and classes
- Use SCREAMING_SNAKE_CASE for constants

### File Organization
<!-- Describe your file structure expectations -->
- Controllers go in `src/controllers/`
- Models go in `src/models/`
- Tests should be colocated with source files

### Testing Requirements
<!-- Describe your testing expectations -->
- All new features must have unit tests
- Integration tests required for API endpoints
- Minimum 80% code coverage for new code

## Security Considerations

<!-- Project-specific security requirements -->
- All user input must be validated using [validation library]
- Database queries must use parameterized statements
- Authentication is handled via [auth method]

## Performance Guidelines

<!-- Project-specific performance requirements -->
- Database queries should be optimized with proper indexes
- API responses should complete within 500ms
- Avoid N+1 query patterns

## Common Patterns

### Error Handling
<!-- Describe your error handling patterns -->
```go
// Example: How errors should be handled in this project
if err != nil {
    return fmt.Errorf("operation failed: %w", err)
}
```

### Logging
<!-- Describe your logging conventions -->
```go
// Example: How logging should be done
log.Info("operation completed", "field", value)
```

## Review Focus Areas

<!-- Highlight areas to pay special attention to -->
1. **API changes**: Check backwards compatibility
2. **Database migrations**: Ensure reversibility
3. **Configuration changes**: Verify defaults are safe
4. **Dependencies**: Check for known vulnerabilities

## Ignore Patterns

<!-- Things the reviewer should NOT flag -->
- Generated files in `gen/` directory
- Vendor dependencies in `vendor/`
- Test fixtures and mock data

## Additional Notes

<!-- Any other project-specific guidance -->
- We follow [style guide link]
- Breaking changes require RFC document
- All PRs need at least one human approval
