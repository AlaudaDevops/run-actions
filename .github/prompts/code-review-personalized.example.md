# Repository-Specific Code Review Guidelines

> Copy this file to `.github/prompts/code-review.md` in your repository and customize it.

## Project Overview

<!-- Describe your project briefly -->
This is a [type of project] that [main purpose].

## Tech Stack

<!-- List the main technologies used -->
- **Language**: [e.g., TypeScript, Go, Python]
- **Framework**: [e.g., React, Express, FastAPI]
- **Database**: [e.g., PostgreSQL, MongoDB]
- **Infrastructure**: [e.g., Kubernetes, AWS Lambda]

## Code Standards

### Naming Conventions
<!-- Define your naming conventions -->
- Variables: camelCase
- Functions: camelCase
- Classes: PascalCase
- Constants: UPPER_SNAKE_CASE
- Files: kebab-case

### File Organization
<!-- Describe your file structure -->
- `/src` - Source code
- `/tests` - Test files
- `/docs` - Documentation

### Import Order
<!-- Define import ordering rules -->
1. Standard library imports
2. Third-party imports
3. Local imports

## Security Requirements

<!-- List specific security requirements for your project -->
- All user input must be validated using [validation library]
- API endpoints must use [authentication method]
- Sensitive data must be encrypted with [encryption standard]
- Never log PII or sensitive information

## Performance Guidelines

<!-- Define performance expectations -->
- API responses should complete within 200ms
- Database queries must use indexes
- Avoid N+1 query patterns
- Use pagination for list endpoints

## Testing Requirements

<!-- Define testing expectations -->
- All new features must have unit tests
- Minimum coverage: 80%
- Integration tests for API endpoints
- Use [testing framework] for tests

## Common Patterns

### Error Handling
<!-- Show your preferred error handling pattern -->
```typescript
// Example: Use Result pattern for error handling
type Result<T, E> = { ok: true; value: T } | { ok: false; error: E };
```

### Logging
<!-- Show your logging conventions -->
```typescript
// Use structured logging with context
logger.info("Operation completed", { userId, action, duration });
```

### API Response Format
<!-- Define your API response structure -->
```json
{
  "data": {},
  "meta": { "timestamp": "...", "requestId": "..." },
  "errors": []
}
```

## Review Focus Areas

<!-- List areas that need special attention in reviews -->
- [ ] Authentication and authorization checks
- [ ] Input validation on all endpoints
- [ ] Proper error messages (no internal details exposed)
- [ ] Database migration compatibility
- [ ] API versioning for breaking changes

## Ignore Patterns

<!-- Files or patterns to skip during review -->
- `*.generated.*` - Auto-generated files
- `vendor/` - Third-party vendored code
- `*.min.js` - Minified files
- `package-lock.json` - Lock files (only review if security concern)

## Severity Overrides

<!-- Customize severity for specific issue types -->
- Missing tests for bug fixes: ERROR (normally WARNING)
- Console.log statements: ERROR in production code, INFO in tests
- TODO comments: INFO (tracked separately)
