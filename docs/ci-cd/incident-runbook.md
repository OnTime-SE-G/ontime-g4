# Incident Runbook (G4)

This runbook provides a minimal response flow for staging incidents.

## Quick Triage

1) Identify failing service:
```bash
kubectl get pods -A | grep -i crash
kubectl get events -n transit-platform --sort-by=.lastTimestamp | tail -n 20
```

2) Check release state:
```bash
helm status transit-platform -n transit-platform
kubectl get deploy -n transit-platform
```

3) Review logs:
```bash
kubectl logs deploy/<deployment-name> -n transit-platform --tail=200
```

## Common Issues

### Pods in CrashLoopBackOff
- Check config and secrets.
- Verify required env vars and secret keys.
- Roll back if a new release was just applied.

### Kong is up but services are unreachable
- Confirm Kong route config and service endpoints.
- Check service selectors and readiness.

### Kafka or PostgreSQL unavailable
- Check StatefulSet and PVC status.
- Verify storage class and volume bindings.

## Rollback Path

```bash
helm history transit-platform -n transit-platform
helm rollback transit-platform <revision> -n transit-platform
```

## Escalation

- Notify G4 lead and provide:
  - Current namespace and failing pods
  - Helm status output
  - Recent rollout changes
