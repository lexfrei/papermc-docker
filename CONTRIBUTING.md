# Contributing to PaperMC Docker

Thank you for your interest in contributing to this project! This document provides guidelines and instructions for contributing.

## Code of Conduct

Please be respectful and considerate when interacting with other contributors.

## How to Contribute

### Reporting Bugs

If you find a bug, please create an issue with the following information:

- Clear description of the bug
- Steps to reproduce
- Expected behavior
- Actual behavior
- Screenshots or logs (if applicable)
- Environment details (Docker version, OS, etc.)

### Suggesting Enhancements

For feature requests, please create an issue with:

- Clear description of the proposed feature
- Rationale for why this would be valuable
- Any implementation ideas you have

### Pull Requests

1. Fork the repository
2. Create a new branch for your changes
3. Make your changes
4. Test your changes thoroughly
5. Submit a pull request with a clear description of the changes

## Development Setup

### Prerequisites

- Docker
- Git

### Setup Steps

1. Clone the repository:
   ```bash
   git clone https://github.com/lexfrei/papermc-docker.git
   cd papermc-docker
   ```

2. Build the Docker image:
   ```bash
   docker build -t lexfrei/papermc:local .
   ```

3. Test the image:
   ```bash
   docker run -d -p 25565:25565 --name mc-test lexfrei/papermc:local
   ```

## Coding Standards

- Follow the existing code style
- Use meaningful commit messages
- Keep changes focused and atomic
- Document new features or significant changes

## Testing

Before submitting a PR, please test your changes with:

- Different versions of Minecraft
- Different platforms (if applicable)
- Basic server functionality

## Additional Resources

- [PaperMC Documentation](https://docs.papermc.io/)
- [Docker Documentation](https://docs.docker.com/)

Thank you for contributing!
