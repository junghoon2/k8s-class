#!/bin/bash

for context in $(kubectl config get-contexts -o=name); do
  echo "Context: $context"
  kubectl version --output=json --context="$context"|jq  '.serverVersion'
  echo ""
done
