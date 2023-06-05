# Support for multiple namespaces

## Datasources

### Watching for Datasources in all namespaces

***Currently the `Grafana` and `GrafanaDataSource` resources do not support multiple namespaces and are only reconciled
if created in the operators namespace.***

## Dashboards

The operator can import dashboards from either one, some or all namespaces. By default, it will only look for dashboards
in its own namespace. By setting the `--scan-all`,`--namespaces` flags or  `DASHBOARD_NAMESPACES_ALL="true"` env var,
the operator can watch for dashboards in other namespaces.

### Watching for dashboards in all namespaces

Set the `--scan-all` flag or `DASHBOARD_NAMESPACES_ALL="true"` env var to watch for dashboards in all namespaces.
Cluster wide permissions for the
`grafana-operator`
service account are required (see `deploy/cluster_roles`).

*Note: to run the allow the operator to watch all namespaces when deploying through OLM, you need to provide the
`DASHBOARD_NAMESPACES_ALL="true"` env var to the deployment, `--scan-all` isn't supported in this deployment type due to
a limitation in the operator lifecycle manager*

### Watching for dashboards in some namespaces

#### 1. **namespace operator flag**

You can provide a comma separated list of watch namespaces using the `--namespaces` flag. The format
is `--namespaces=<NS_1,NS_2,...,NS_N>`, for example: `--namespaces=grafana,dashboards,example_namespace`. The same
cluster wide permissions as for watching all namespaces are required.

***NOTE***: `--scan-all` and `--namespaces` are mutually exclusive. You can only use one at a time.

#### 2. **dashboardNamespaceSelector**

You can also watch for dashboards in certain namespaces by using the dashboardNamespaceSelector in the Grafana CR. This
watches for dashboards only in the Namespaces that have the specified namespace label. The format to specify labels is

```yaml
dashboardNamespaceSelector:
  matchLabels:
    key: value
```

***NOTE***: `--namespaces` and the `dashboardNamespaceSelector` are mutually exclusive and shoudlnt be used together
