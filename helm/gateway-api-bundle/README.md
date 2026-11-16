# gateway-api-bundle

Gateway API bundle

**Homepage:** <https://github.com/giantswarm/gateway-api-bundle>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| clusterID | string | `"test"` |  |
| organization | string | `""` |  |
| migration.appToHelmRelease.enabled | bool | `true` |  |
| migration.appToHelmRelease.image | string | `"gsoci.azurecr.io/giantswarm/docker-kubectl:1.37.2"` |  |
| apps.gatewayApiCrds.appName | string | `"gateway-api-crds"` |  |
| apps.gatewayApiCrds.chartName | string | `"gateway-api-crds"` |  |
| apps.gatewayApiCrds.catalog | string | `"giantswarm"` |  |
| apps.gatewayApiCrds.enabled | bool | `true` |  |
| apps.gatewayApiCrds.namespace | string | `"kube-system"` |  |
| apps.gatewayApiCrds.version | string | `"1.9.1"` |  |
| apps.gatewayApiCrds.userConfig | object | `{}` |  |
| apps.gatewayApiCrds.extraConfigs | list | `[]` |  |
| apps.envoyGateway.appName | string | `"envoy-gateway"` |  |
| apps.envoyGateway.chartName | string | `"envoy-gateway"` |  |
| apps.envoyGateway.catalog | string | `"giantswarm"` |  |
| apps.envoyGateway.dependsOn[0] | string | `"gateway-api-crds"` |  |
| apps.envoyGateway.enabled | bool | `true` |  |
| apps.envoyGateway.namespace | string | `"envoy-gateway-system"` |  |
| apps.envoyGateway.version | string | `"1.10.5"` |  |
| apps.envoyGateway.userConfig | object | `{}` |  |
| apps.envoyGateway.extraConfigs | list | `[]` |  |
| apps.gatewayApiConfig.appName | string | `"gateway-api-config"` |  |
| apps.gatewayApiConfig.chartName | string | `"gateway-api-config"` |  |
| apps.gatewayApiConfig.catalog | string | `"giantswarm"` |  |
| apps.gatewayApiConfig.dependsOn[0] | string | `"envoy-gateway"` |  |
| apps.gatewayApiConfig.enabled | bool | `true` |  |
| apps.gatewayApiConfig.namespace | string | `"envoy-gateway-system"` |  |
| apps.gatewayApiConfig.version | string | `"1.13.1"` |  |
| apps.gatewayApiConfig.userConfig | object | `{}` |  |
| apps.gatewayApiConfig.extraConfigs | list | `[]` |  |
| apps.gatewayApiStateMetrics.appName | string | `"gateway-api-state-metrics"` |  |
| apps.gatewayApiStateMetrics.chartName | string | `"kube-state-metrics"` |  |
| apps.gatewayApiStateMetrics.catalog | string | `"giantswarm"` |  |
| apps.gatewayApiStateMetrics.dependsOn[0] | string | `"gateway-api-crds"` |  |
| apps.gatewayApiStateMetrics.enabled | bool | `true` |  |
| apps.gatewayApiStateMetrics.namespace | string | `"envoy-gateway-system"` |  |
| apps.gatewayApiStateMetrics.version | string | `"0.1.0"` |  |
| apps.gatewayApiStateMetrics.valuesFile | string | `"files/gateway-api-state-metrics/values.yaml"` |  |
| apps.gatewayApiStateMetrics.userConfig | object | `{}` |  |
| apps.gatewayApiStateMetrics.extraConfigs | list | `[]` |  |
| apps.cloudwatchExporter.appName | string | `"cloudwatch-exporter"` |  |
| apps.cloudwatchExporter.chartName | string | `"cloudwatch-exporter"` |  |
| apps.cloudwatchExporter.catalog | string | `"giantswarm"` |  |
| apps.cloudwatchExporter.enabled | bool | `false` |  |
| apps.cloudwatchExporter.namespace | string | `"envoy-gateway-system"` |  |
| apps.cloudwatchExporter.version | string | `"0.1.4"` |  |
| apps.cloudwatchExporter.userConfig.configMap.values.clusterID | string | `"{{ .Values.clusterID }}"` |  |
| apps.cloudwatchExporter.userConfig.configMap.values.region | string | `"{{ include \"aws.region\" . }}"` |  |
| apps.cloudwatchExporter.userConfig.configMap.values.serviceAccount.create | bool | `true` |  |
| apps.cloudwatchExporter.userConfig.configMap.values.serviceAccount.name | string | `"yace"` |  |
| apps.cloudwatchExporter.userConfig.configMap.values.serviceAccount.annotations."eks.amazonaws.com/role-arn" | string | `"{{ .Values.clusterID }}-cloudwatch-exporter"` |  |
| apps.cloudwatchExporter.extraConfigs | list | `[]` |  |
| aws.accountID | string | `""` |  |
| aws.oidcDomain | string | `""` |  |
| aws.baseDomain | string | `""` |  |
| aws.region | string | `""` |  |
| iamRoles.cloudwatchExporter.enabled | bool | `true` |  |
| iamRoles.cloudwatchExporter.namespace | string | `"envoy-gateway-system"` |  |
| iamRoles.cloudwatchExporter.serviceAccount | string | `"yace"` |  |
