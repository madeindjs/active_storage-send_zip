# AGENTS.md

## Build/Lint/Test Commands

### Setup
```bash
bin/setup          # Install dependencies
```

### Testing
```bash
rake test          # Run all tests
```

### Development
```bash
bin/console        # Interactive Ruby console
bundle exec rake install    # Install gem locally
```

## Code Style Guidelines

### Imports
- Group standard library requires first, then third-party, then local files
- Use double quotes for require paths
- Place all requires at the top of the file

### Formatting
- Use 2 space indentation (no tabs)
- Max line length 80-100 characters
- Add empty line at end of file
- Use frozen_string_literal: true magic comment
- Add newline after class/module definition

### Naming Conventions
- Use snake_case for methods and variables
- Use PascalCase for classes and modules
- Use SCREAMING_SNAKE_CASE for constants
- Method names should be descriptive verbs

### Types
- Use explicit return types in comments for public methods
- Document parameter types with YARD-style comments
- Use appropriate Ruby types (String, Array, Hash, etc.)

### Error Handling
- Raise specific exception types (ArgumentError, StandardError, etc.)
- Use guard clauses for early returns
- Handle edge cases explicitly
- Provide meaningful error messages

### Documentation
- Add YARD-style comments for all public methods
- Include @param and @return tags
- Document complex logic with inline comments
- Keep comments up-to-date with code changes
