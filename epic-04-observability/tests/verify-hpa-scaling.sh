#!/bin/bash

# G4-35: HPA Scale-Up Verification Script
# This script provides commands to verify HPA scaling by simulating load.

NAMESPACE="transit-ui"
DEPLOYMENT="commuter-nextjs"
HPA_NAME="commuter-nextjs-hpa"

echo "=== HPA Scaling Verification ==="

# 1. Check current status
echo "Current HPA Status:"
kubectl get hpa $HPA_NAME -n $NAMESPACE

# 2. Simulate CPU Load (Manual)
# Run a busy loop in a temporary pod to drive CPU up
echo "To simulate CPU load, run this in a separate terminal:"
echo "kubectl run -i --tty load-generator --rm --image=busybox:1.28 --restart=Never -- /bin/sh -c \"while true; do :; done\""

# 3. Observe Scaling
echo "Observe the pod count increasing:"
echo "kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT -w"

# 4. Observe HPA metrics
echo "Observe the HPA metrics updating:"
echo "kubectl get hpa $HPA_NAME -n $NAMESPACE -w"

# 5. Clean up
echo "After verification, stop the load-generator pod (Ctrl+C)."
echo "Pod count should return to 2 after the 300s stabilization window."
