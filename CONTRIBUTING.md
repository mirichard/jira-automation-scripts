# Contributing to Jira Automation Scripts

Thank you for your interest in contributing to this project! This document provides guidelines for contributing to the Jira automation scripts repository.

## How to Contribute

### Reporting Issues

1. Check if the issue already exists in [GitHub Issues](https://github.com/mirichard/jira-automation-scripts/issues)
2. Use the appropriate issue template (Bug Report or Feature Request)
3. Provide detailed information including:
   - Script name and version
   - Environment details
   - Steps to reproduce
   - Expected vs actual behavior

### Submitting Changes

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test your changes thoroughly
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## Development Guidelines

### Script Requirements

- **Shell Scripts**: Use bash with proper error handling (`set -e`)
- **Documentation**: Include comprehensive comments and usage examples
- **Error Handling**: Implement proper error handling and logging
- **Security**: Never include hardcoded credentials
- **Rate Limiting**: Include appropriate rate limiting for API calls

### Code Style

- Use consistent indentation (2 spaces)
- Include descriptive variable names
- Add logging functions for better debugging
- Implement dry-run modes where applicable

### Testing

- Test scripts in safe environments first
- Verify API rate limits are respected
- Test error conditions and edge cases
- Document any environment-specific requirements

### Documentation

- Update README.md for new scripts
- Include setup instructions
- Provide usage examples
- Document any dependencies

## Security Considerations

- Never commit API tokens or sensitive credentials
- Use environment variables for configuration
- Implement proper input validation
- Include security warnings in documentation

## Questions?

Feel free to open an issue for any questions about contributing to this project.

---

Thank you for contributing! 🎉
