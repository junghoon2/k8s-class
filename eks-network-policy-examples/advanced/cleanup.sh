#!/bin/bash
echo "Cleaning up Network policies"
kubectl delete -f policies/
echo "Cleaning up the sample apps"
kubectl delete -f manifests/
echo "Clean up completed!"
