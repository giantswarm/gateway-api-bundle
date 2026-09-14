{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Set the name of each app composed of the clusterId+appName
*/}}
{{- define "app.name" -}}
{{- printf "%s-%s" .cluster .app -}}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "labels.selector" -}}
app.kubernetes.io/name: {{ include "name" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "labels.common" -}}
{{ include "labels.selector" . }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
application.giantswarm.io/team: {{ index .Chart.Annotations "io.giantswarm.application.team" | quote }}
giantswarm.io/managed-by: {{ .Release.Name | quote }}
giantswarm.io/cluster: {{ .Values.clusterID | quote }}
giantswarm.io/organization: {{ .Values.organization | quote }}
giantswarm.io/service-type: managed
helm.sh/chart: {{ include "chart" . | quote }}
{{- end -}}

{{/*
AWS context for the cluster. Values win; anything unset falls back to the
<clusterID>-crossplane-config ConfigMap in the release namespace, maintained by
aws-crossplane-cluster-config-operator. A missing or unparsable ConfigMap is not an
error here, the fields are simply left empty and the accessors decide.
Returns YAML: include "aws.context" $ | fromYaml
*/}}
{{- define "aws.context" -}}
{{- $values := .Values.aws | default dict -}}
{{- $cm := lookup "v1" "ConfigMap" .Release.Namespace (printf "%s-crossplane-config" .Values.clusterID) -}}
{{- $fallback := dict -}}
{{- if and $cm $cm.data (hasKey $cm.data "values") -}}
{{- $parsed := fromYaml $cm.data.values -}}
{{- if not (hasKey $parsed "Error") -}}
{{- $fallback = $parsed -}}
{{- end -}}
{{- end -}}
{{- $accountID := $values.accountID | default $fallback.accountID | default "" -}}
{{- $region := $values.region | default $fallback.region | default "" -}}
{{- $oidcDomain := $values.oidcDomain | default $fallback.oidcDomain | default "" -}}
{{- if and (not $oidcDomain) $values.baseDomain -}}
{{- $oidcDomain = printf "irsa.%s.%s" .Values.clusterID $values.baseDomain -}}
{{- end -}}
{{- dict "accountID" ($accountID | toString) "region" ($region | toString) "oidcDomain" ($oidcDomain | toString) | toYaml -}}
{{- end -}}

{{/*
AWS account ID, required.
*/}}
{{- define "aws.accountID" -}}
{{- $aws := include "aws.context" . | fromYaml -}}
{{- if not $aws.accountID -}}
{{- fail (printf "aws.accountID is not set and could not be read from ConfigMap %s-crossplane-config in namespace %s" .Values.clusterID .Release.Namespace) -}}
{{- end -}}
{{- $aws.accountID -}}
{{- end -}}

{{/*
IRSA OIDC provider host, required.
*/}}
{{- define "aws.oidcDomain" -}}
{{- $aws := include "aws.context" . | fromYaml -}}
{{- if not $aws.oidcDomain -}}
{{- fail (printf "neither aws.oidcDomain nor aws.baseDomain is set and the OIDC domain could not be read from ConfigMap %s-crossplane-config in namespace %s" .Values.clusterID .Release.Namespace) -}}
{{- end -}}
{{- $aws.oidcDomain -}}
{{- end -}}

{{/*
AWS region, required.
*/}}
{{- define "aws.region" -}}
{{- $aws := include "aws.context" . | fromYaml -}}
{{- if not $aws.region -}}
{{- fail (printf "aws.region is not set and could not be read from ConfigMap %s-crossplane-config in namespace %s" .Values.clusterID .Release.Namespace) -}}
{{- end -}}
{{- $aws.region -}}
{{- end -}}
