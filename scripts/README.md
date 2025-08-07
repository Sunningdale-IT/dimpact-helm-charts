# Scripts Directory

This directory contains utility scripts for working with Helm charts in the dimpact-helm-charts repository.

## package-and-push.sh

A comprehensive script for packaging and pushing Helm charts with support for both development and production workflows.

### Usage

```bash
# Basic packaging (production mode)
./scripts/package-and-push.sh

# Development mode - push to custom registry
./scripts/package-and-push.sh --dev --registry oci://my-registry.com/charts --username myuser --password mypass

# Package a specific chart
./scripts/package-and-push.sh --chart kiss

# Show help
./scripts/package-and-push.sh --help
```

### Features

- **Automatic dependency management**: Adds all required Helm repositories and updates chart dependencies
- **Chart validation**: Performs Helm linting before packaging
- **Development mode**: Supports pushing to custom OCI registries for testing
- **Production mode**: Provides guidance for using GitHub Actions workflows
- **Error handling**: Clear error messages and validation
- **Multi-chart support**: Can package any chart in the repository

### Environment Variables

For development mode, you can set these environment variables instead of using command-line flags:

- `HELM_REGISTRY_URL`: Registry URL for development mode
- `HELM_REGISTRY_USERNAME`: Registry username for development mode  
- `HELM_REGISTRY_PASSWORD`: Registry password for development mode

### Development Mode

Development mode allows you to push charts to a custom OCI registry for testing purposes. This is useful for:

- Testing chart changes before merging
- Sharing development versions with team members
- Integration testing with custom registries

### Production Mode

Production mode packages the chart locally but does not push it. Instead, it provides guidance on using the repository's GitHub Actions workflows for official releases:

- **Automatic releases**: Push to `main` or `release/*` branches triggers the release workflow
- **Manual releases**: Use the "Release Charts met changelogs" workflow for specific version releases

## test-package-and-push.sh

A test script that validates the functionality of `package-and-push.sh`. Run this script to ensure the package-and-push script is working correctly.

```bash
./scripts/test-package-and-push.sh
```

## Contributing

When modifying scripts:

1. Ensure they remain compatible with the existing workflow patterns
2. Add appropriate error handling and user-friendly messages
3. Update this README if adding new scripts or changing functionality
4. Test thoroughly using the test scripts