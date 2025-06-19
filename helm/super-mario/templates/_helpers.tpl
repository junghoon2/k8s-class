{{/*
Expand the name of the chart.
*/}}
{{- define "starter-template.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "starter-template.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "starter-template.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "starter-template.labels" -}}
helm.sh/chart: {{ include "starter-template.chart" . }}
{{ include "starter-template.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "starter-template.selectorLabels" -}}
app.kubernetes.io/name: {{ include "starter-template.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "starter-template.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "starter-template.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the configmap
*/}}
{{- define "starter-template.configMapName" -}}
{{- printf "%s-config" (include "starter-template.fullname" .) }}
{{- end }}

{{/*
Create the name of the secret
*/}}
{{- define "starter-template.secretName" -}}
{{- printf "%s-secret" (include "starter-template.fullname" .) }}
{{- end }}

{{/*
Create image name with registry and tag
*/}}
{{- define "starter-template.image" -}}
{{- $registry := .Values.global.imageRegistry | default .Values.image.registry -}}
{{- $repository := .Values.image.repository -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion | toString -}}
{{- if $registry }}
{{- printf "%s/%s:%s" $registry $repository $tag -}}
{{- else }}
{{- printf "%s:%s" $repository $tag -}}
{{- end }}
{{- end }}

{{/*
Return the proper image pull secrets
*/}}
{{- define "starter-template.imagePullSecrets" -}}
{{- $pullSecrets := list }}
{{- if .Values.global.imagePullSecrets }}
{{- $pullSecrets = .Values.global.imagePullSecrets }}
{{- else if .Values.image.pullSecrets }}
{{- $pullSecrets = .Values.image.pullSecrets }}
{{- end }}
{{- if $pullSecrets }}
imagePullSecrets:
{{- range $pullSecrets }}
  - name: {{ . }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create common annotations
*/}}
{{- define "starter-template.annotations" -}}
{{- with .Values.commonAnnotations }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Validate values
*/}}
{{- define "starter-template.validateValues" -}}
{{- if and .Values.hpa.enabled (lt (.Values.deployment.replicaCount | int) (.Values.hpa.minReplicas | int)) }}
{{- fail "deployment.replicaCount must be greater than or equal to hpa.minReplicas when HPA is enabled" }}
{{- end }}
{{- if and .Values.deployment.podDisruptionBudget.enabled (not .Values.deployment.podDisruptionBudget.minAvailable) (not .Values.deployment.podDisruptionBudget.maxUnavailable) }}
{{- fail "Either minAvailable or maxUnavailable must be set when PodDisruptionBudget is enabled" }}
{{- end }}
{{- end }} 