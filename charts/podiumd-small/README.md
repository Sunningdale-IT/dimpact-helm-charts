# PodiumD Small

A minimal Helm chart for deploying only Keycloak from the PodiumD stack.

## Description

This chart provides a lightweight deployment of Keycloak with the same configuration as the full PodiumD chart. It's designed for scenarios where you only need the authentication and authorization services without the full PodiumD application stack.

## Features

- Keycloak authentication server
- Configurable realm and client settings
- Monitoring client included
- SMTP configuration support
- Identity provider support (configurable)

## Usage

```bash
# Install the chart
helm install podiumd-small ./charts/podiumd-small

# Install with custom values
helm install podiumd-small ./charts/podiumd-small -f values.yaml
```

## Configuration

The chart uses the same Keycloak configuration structure as the main PodiumD chart. See the `values.yaml` file for all available options.

### Key Configuration Options

- `keycloak.auth.adminUser`: Admin username (default: admin)
- `keycloak.auth.adminPassword`: Admin password (default: changemenow)
- `keycloak.config.realm`: Realm name (default: podiumd)
- `keycloak.config.realmFrontendUrl`: Frontend URL for the realm
- `keycloak.config.adminFrontendUrl`: Admin frontend URL

## Future Enhancements

This chart is designed to be extensible. Additional PodiumD components can be added later by:

1. Adding new dependencies to `Chart.yaml`
2. Including additional template files
3. Extending the `values.yaml` configuration

## Dependencies

- Keycloak (Bitnami) - version 24.8.0
