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
app.sortedValuesFrom — reproduce the App platform's config merge order as a
single Flux `valuesFrom` list (Flux merges the list top-to-bottom, later
entries win). The App platform instead merges by numeric priority and always
lets secrets win over configMaps, so we emit entries in ascending precedence.

Band order (lowest precedence first):
  pre-cluster extras (priority < 50) -> cluster values (slot 50)
  -> post-cluster extras (50..100)   -> user values (slot 100)
  -> post-user extras (priority > 100)
and, independently, all configMaps sort before all secrets so secrets win.
Equal-priority extras keep their authored order; at equal priority an extra
precedes the platform entry (so platform config wins the tie).

Each entry is encoded as a sort key `KIND_PRIORITY_SOURCE_INDEX`:
  KIND     0=configMap 1=secret      (all configMaps sort before all secrets)
  PRIORITY %03d                       (numeric order via zero-pad)
  SOURCE   0=extraConfig 1=platform   (extra precedes platform at equal priority)
  INDEX    %03d authored position     (stable tie-break for equal-priority extras)
then sortAlpha the keys and emit. Returns a YAML array of valuesFrom entries.

Params (dict):
  clusterValuesConfigMap  name of the <clusterID>-cluster-values ConfigMap (or "")
  userValuesConfigMap     name of the user-values ConfigMap (or "")
  userValuesSecret        name of the user-secrets Secret (or "")
  extraConfigs            list of {name, kind, priority, optional}
  root                    $ (for tpl-ing extraConfig names)
*/}}
{{- define "app.sortedValuesFrom" -}}
{{- $keyed := dict -}}
{{- $keys := list -}}
{{- if .clusterValuesConfigMap -}}
{{- $k := "0_050_1_000" -}}
{{- $keyed = set $keyed $k (dict "kind" "ConfigMap" "name" .clusterValuesConfigMap "valuesKey" "values" "optional" true) -}}
{{- $keys = append $keys $k -}}
{{- end -}}
{{- if .userValuesConfigMap -}}
{{- $k := "0_100_1_000" -}}
{{- $keyed = set $keyed $k (dict "kind" "ConfigMap" "name" .userValuesConfigMap "valuesKey" "values" "optional" false) -}}
{{- $keys = append $keys $k -}}
{{- end -}}
{{- if .userValuesSecret -}}
{{- $k := "1_100_1_000" -}}
{{- $keyed = set $keyed $k (dict "kind" "Secret" "name" .userValuesSecret "valuesKey" "values" "optional" false) -}}
{{- $keys = append $keys $k -}}
{{- end -}}
{{- range $i, $extraConfig := (.extraConfigs | default list) -}}
{{- $isSecret := $extraConfig.kind | default "configMap" | lower | eq "secret" -}}
{{- $kindOrder := $isSecret | ternary "1" "0" -}}
{{- $priority := $extraConfig.priority | default 25 | int -}}
{{- $k := printf "%s_%03d_0_%03d" $kindOrder $priority $i -}}
{{- $keyed = set $keyed $k (dict "kind" ($isSecret | ternary "Secret" "ConfigMap") "name" (tpl $extraConfig.name $.root) "valuesKey" "values" "optional" ($extraConfig.optional | default false)) -}}
{{- $keys = append $keys $k -}}
{{- end -}}
{{- $out := list -}}
{{- range $k := sortAlpha $keys -}}
{{- $out = append $out (get $keyed $k) -}}
{{- end -}}
{{- $out | toYaml -}}
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
