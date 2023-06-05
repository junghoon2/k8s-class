# Grafana Operator Documentation

* [Installing Grafana](./deploy_grafana.md)
* [Dashboards](./dashboards.md)
* [Dashboard folder permissions](./folder_permissions.md)
* [Data Sources](./datasources.md)
* [Develop](./develop.md)
* [Multi namespace support](./multi_namespace_support.md)
* [Plugins](./plugins.md)
* [Mounting extra config files](./extra_files.md)
* [Jsonnet support](./jsonnet.md)
* [Env vars](./env_vars.md)
* [API docs](./api.md)

## Examples

The following example CRs are provided:

### Grafana deployments

* [Grafana.yaml](../deploy/examples/Grafana.yaml): Installs Grafana using the default configuration and an Ingress or Route.
* [GrafanaWithIngressHost.yaml](../deploy/examples/GrafanaWithIngressHost.yaml): Installs Grafana using the default configuration and an Ingress where the host is set for external access.
* [ldap/Grafana.yaml](../deploy/examples/ldap/Grafana.yaml): Installs Grafana and sets up LDAP authentication. LDAP configuration is mounted from the configmap [ldap/ldap-config.yaml](../deploy/examples/ldap/ldap-config.yaml)
* [oauth/Grafana.yaml](../deploy/examples/oauth/Grafana.yaml): Installs Grafana and enable OAuth authentication using the OpenShift OAuthProxy.
* [ha/Grafana.yaml](../deploy/examples/ha): Installs Grafana in high availability mode with Postgres as a database.
* [persistentvolume/Grafana-Kubernetes.yaml](../deploy/examples/persistentvolume/Grafana-Kubernetes.yaml): Installs Grafana but provides a dedicated PVC for the database.
* [persistentvolume/Grafana-OpenShift.yaml](../deploy/examples/persistentvolume/Grafana-OpenShift.yaml): Installs Grafana but provides a dedicated PVC for the database. OpenShift specific example without assigning an `fsGroup`.
* [env/Grafana.yaml](../deploy/examples/env/Grafana.yaml): Shows how to provide env vars including admin credentials from a secret.
* [datasource-env-vars/Grafana.yaml](../deploy/examples/datasource-env-vars/Grafana.yaml): Shows how to provide env vars and use them in a data source to provide credentials.

### Dashboards

* [SimpleDashboard.yaml](../deploy/examples/dashboards/SimpleDashboard.yaml): Minimal empty dashboard.
* [DashboardWithPlugins.yaml](../deploy/examples/dashboards/DashboardWithPlugins.yaml): Minimal empty dashboard with plugin dependencies.
* [DashboardFromURL.yaml](../deploy/examples/dashboards/DashboardFromURL.yaml): A dashboard that downloads its contents from a URL and falls back to embedded json if the URL cannot be resolved.
* [KeycloakDashboard.yaml](../deploy/examples/dashboards/KeycloakDashboard.yaml): A dashboard that shows keycloak metrics and demonstrates how to use datasource inputs.

### Folders

* [public-folder.yaml](../deploy/examples/folders/public-folder.yaml): Folder with access-permissions for users with role "Viewer"
* [restricted-folder.yaml](../deploy/examples/folders/restricted-folder.yaml): Folder only accessible for Editors

### Data sources

* [Prometheus.yaml](../deploy/examples/datasources/Prometheus.yaml): Prometheus data source, expects a service named `prometheus-service` listening on port 9090 in the same namespace.
* [SimpleJson.yaml](../deploy/examples/datasources/SimpleJson.yaml): Simple JSON data source, requires the [grafana-simple-json-datasource](https://grafana.com/grafana/plugins/grafana-simple-json-datasource) plugin to be installed.
