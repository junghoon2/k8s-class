{{/* ######### Redis related templates */}}

{{/*
Return the redis hostname
If the redis host is provided, it will use that, otherwise it will fallback
to the service name
*/}}
{{- define "gitlab.redis.host" -}}
{{- include "gitlab.redis.configMerge" . -}}
{{- if .redisMergedConfig.host -}}
{{-   .redisMergedConfig.host -}}
{{- else -}}
{{-   $name := default "redis" .Values.redis.serviceName -}}
{{-   $redisRelease := .Release.Name -}}
{{-   if contains $name $redisRelease -}}
{{-     $redisRelease = .Release.Name | trunc 63 | trimSuffix "-" -}}
{{-   else -}}
{{-     $redisRelease = printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{-   end -}}
{{-   printf "%s-master.%s.svc" $redisRelease .Release.Namespace -}}
{{- end -}}
{{- end -}}

{{/*
Return the redis port
If the redis port is provided, it will use that, otherwise it will fallback
to 6379 default
*/}}
{{- define "gitlab.redis.port" -}}
{{- include "gitlab.redis.configMerge" . -}}
{{- default 6379 .redisMergedConfig.port -}}
{{- end -}}

{{/*
Return the redis scheme, or redis. Allowing people to use rediss clusters
*/}}
{{- define "gitlab.redis.scheme" -}}
{{- include "gitlab.redis.configMerge" . -}}
{{- $valid := list "redis" "rediss" "tcp" -}}
{{- $name := default "redis" .redisMergedConfig.scheme -}}
{{- if has $name $valid -}}
{{    $name }}
{{- else -}}
{{    cat "Invalid redis scheme" $name | fail }}
{{- end -}}
{{- end -}}

{{/*
Return the redis url.
*/}}
{{- define "gitlab.redis.url" -}}
{{ template "gitlab.redis.scheme" . }}://{{ template "gitlab.redis.url.user" . }}{{ template "gitlab.redis.url.password" . }}{{ template "gitlab.redis.host" . }}:{{ template "gitlab.redis.port" . }}
{{- end -}}

{{/*
Return the user section of the Redis URI, if needed.
*/}}
{{- define "gitlab.redis.url.user" -}}
{{- include "gitlab.redis.configMerge" . -}}
{{ .redisMergedConfig.user }}
{{- end -}}

{{/*
Return the password section of the Redis URI, if needed.
*/}}
{{- define "gitlab.redis.url.password" -}}
{{- include "gitlab.redis.configMerge" . -}}
{{- if .redisMergedConfig.password.enabled -}}:<%= ERB::Util::url_encode(File.read("/etc/gitlab/redis/{{ printf "%s-password" (default "redis" .redisConfigName) }}").strip) %>@{{- end -}}
{{- end -}}

{{/*
Build the structure describing sentinels
*/}}
{{- define "gitlab.redis.sentinels" -}}
{{- include "gitlab.redis.selectedMergedConfig" . -}}
{{- if .redisMergedConfig.sentinels -}}
sentinels:
{{- range $i, $entry := .redisMergedConfig.sentinels }}
  - host: {{ $entry.host }}
    port: {{ default 26379 $entry.port }}
{{- end }}
{{- end -}}
{{- end -}}

{{/*Set redisMergedConfig*/}}
{{- define "gitlab.redis.selectedMergedConfig" -}}
{{- if .redisConfigName }}
{{-   $_ := set . "redisMergedConfig" ( index .Values.global.redis .redisConfigName ) -}}
{{- else -}}
{{-   $_ := set . "redisMergedConfig" .Values.global.redis -}}
{{- end -}}
{{-   if not (kindIs "map" (get $.redisMergedConfig "password")) -}}
{{-     $_ := set $.redisMergedConfig "password" $.Values.global.redis.auth -}}
{{-   end -}}
{{- range $key := keys $.Values.global.redis.auth -}}
{{-   if not (hasKey $.redisMergedConfig.password $key) -}}
{{-     $_ := set $.redisMergedConfig.password $key (index $.Values.global.redis.auth $key) -}}
{{-   end -}}
{{- end -}}
{{- end -}}

{{/*
Return Sentinel list in format for Workhorse
Note: Workhorse only uses the primary Redis (global.redis)
*/}}
{{- define "gitlab.redis.workhorse.sentinel-list" }}
{{- $sentinelList := list }}
{{- range $i, $entry := .Values.global.redis.sentinels }}
  {{- $sentinelList = append $sentinelList (quote (print "tcp://" (trim $entry.host) ":" ( default 26379 $entry.port | int ) ) ) }}
{{- end }}
{{- $sentinelList | join "," }}
{{- end -}}

{{- define "gitlab.redis.secrets" -}}
{{- range $redis := list "cache" "clusterCache" "sharedState" "queues" "actioncable" "traceChunks" "rateLimiting" "clusterRateLimiting" "sessions" "repositoryCache" -}}
{{-   if index $.Values.global.redis $redis -}}
{{-     $_ := set $ "redisConfigName" $redis }}
{{      include "gitlab.redis.secret" $ }}
{{-   end }}
{{- end -}}
{{/* reset 'redisConfigName', to get global.redis.auth's Secret item */}}
{{- $_ := set . "redisConfigName" "" }}
{{- if include "gitlab.redis.password.enabled" $ }}
{{    include "gitlab.redis.secret" . }}
{{- end }}
{{- end -}}

{{- define "gitlab.redis.secret" -}}
{{- include "gitlab.redis.configMerge" . -}}
{{- if .redisMergedConfig.password.enabled }}
- secret:
    name: {{ template "gitlab.redis.password.secret" . }}
    items:
      - key: {{ template "gitlab.redis.password.key" . }}
        path: redis/{{ printf "%s-password" (default "redis" .redisConfigName) }}
{{- end }}
{{- end -}}
