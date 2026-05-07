# Kong Routing Configuration

## Overview
Kong API Gateway is deployed in **dbless mode** with declarative configuration. All routes to G2 microservices and platform services are defined in `values.yaml` and deployed as a Kubernetes ConfigMap.

## Architecture

```
┌─────────────────┐
│ Client (Web/App)│
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│ Kong LoadBalancer       │
│ (transit-platform-kong) │
└────────┬────────────────┘
         │
    ┌────┴─────────┬──────────┬─────────────┐
    ▼              ▼          ▼             ▼
 /api/v1     /v1/live    /auth/*       /grafana
    │              │          │             │
    ▼              ▼          ▼             ▼
 API Gateway  WebSocket  Keycloak       Grafana
 (8000)       (8004)    (80)            (80)
```

## Service Routes

### API Gateway (Main REST API)
- **Service Name:** `api-gateway`
- **Backend Host:** `transit-platform-g2-api-gateway`
- **Backend Port:** 8000
- **Routes:**
  - `GET /api/v1/*` — All API endpoints
  - `POST /api/v1/*` — Create/update endpoints
  - `PUT /api/v1/*` — Full updates
  - `DELETE /api/v1/*` — Delete endpoints
  - `PATCH /api/v1/*` — Partial updates
  - `OPTIONS /api/v1/*` — CORS preflight

### WebSocket Service (Real-time Updates)
- **Service Name:** `websocket-service`
- **Backend Host:** `transit-platform-g2-websocket-service`
- **Backend Port:** 8004
- **Routes:**
  - `GET /v1/live` — WebSocket upgrade endpoint
  - `POST /v1/live` — Alternative WebSocket entry

### Keycloak (Authentication)
- **Service Name:** `keycloak`
- **Backend Host:** `transit-platform-keycloak`
- **Backend Port:** 80
- **Routes:**
  - `GET /auth/*` — OpenID Connect endpoints, user info, etc.
  - `POST /auth/*` — Token requests, logout

### Grafana (Monitoring Dashboard)
- **Service Name:** `grafana`
- **Backend Host:** `transit-platform-grafana`
- **Backend Port:** 80
- **Routes:**
  - `GET /grafana/*` — Dashboard views
  - `POST /grafana/*` — Dashboard updates
  - **Note:** Strip path enabled; `/grafana/api/...` becomes `/api/...` at Grafana

### Health Endpoint
- **Service Name:** `health-service`
- **Backend Host:** `transit-platform-g2-api-gateway`
- **Backend Port:** 8000
- **Routes:**
  - `GET /health` — Simple health check

## Configuration Location

Kong declarative configuration is defined in:
```
epic-05-cicd/helm/transit-platform/values.yaml
├── kong:
│   ├── database: "off"  (dbless mode)
│   ├── configMap:
│   │   ├── enabled: true
│   │   └── config: |   (YAML formatted)
│   │       services: [...]
│   │       routes: [...]
│   └── extraVolumes: [ConfigMap mount]
```

## Deployment Flow

1. **Helm Install/Upgrade**
   ```bash
   helm upgrade --install transit-platform \
     ./epic-05-cicd/helm/transit-platform \
     -n transit-platform \
     -f values.yaml \
     -f values-staging.yaml
   ```

2. **Create Kong Declarative ConfigMap**
   - Kubernetes automatically creates ConfigMap `transit-platform-kong-declarative`
   - Contains `kong.yaml` file with all routes

3. **Mount ConfigMap in Kong Pod**
   - Kong pod mounts ConfigMap at `/etc/kong`
   - Kong environment variable: `KONG_DECLARATIVE_CONFIG=/etc/kong/kong.yaml`

4. **Kong Starts in Dbless Mode**
   - Kong reads declarative config on startup
   - Applies all routes and services
   - Admin API disabled (config is read-only at runtime)

## Accessing Services

### External Access (via Kong LoadBalancer)
Get Kong LoadBalancer IP:
```bash
kubectl get svc transit-platform-kong-proxy -n transit-platform -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

Access services:
```bash
# API Gateway health
curl http://<kong-lb-ip>:8000/health

# WebSocket
websocat ws://<kong-lb-ip>:8000/v1/live

# Keycloak
curl http://<kong-lb-ip>:8000/auth/.well-known/openid-configuration

# Grafana
curl http://<kong-lb-ip>:8000/grafana/api/health
```

### Internal Access (from within cluster)
```bash
# Services accessible directly:
curl http://transit-platform-g2-api-gateway:8000/health
curl http://transit-platform-g2-websocket-service:8004/health
```

## Modifying Routes

To add, modify, or remove Kong routes:

1. **Edit values.yaml:**
   ```yaml
   kong:
     configMap:
       config: |
         services:
           - name: my-service
             host: service-hostname
             port: 8080
             routes:
               - name: my-route
                 paths:
                   - /my/path
   ```

2. **Redeploy:**
   ```bash
   helm upgrade transit-platform ./epic-05-cicd/helm/transit-platform \
     -n transit-platform
   ```

3. **Kong automatically reloads** (no pod restart needed for dbless mode)

## Troubleshooting

### Kong Pod Not Starting
```bash
# Check logs
kubectl logs -f deployment/transit-platform-kong -n transit-platform

# Look for ConfigMap mount errors or YAML parsing issues
```

### Routes Not Working
```bash
# Verify Kong sees routes (from inside Kong pod)
kubectl exec -it transit-platform-kong-<pod> -n transit-platform -- \
  curl localhost:8001/config

# Check route syntax in values.yaml
# Ensure service hostnames match actual Kubernetes service names
```

### Backend Service Not Reachable
```bash
# Verify service exists
kubectl get svc -n transit-platform | grep api-gateway

# Test connectivity from Kong pod
kubectl exec -it transit-platform-kong-<pod> -n transit-platform -- \
  curl http://transit-platform-g2-api-gateway:8000/api/v1/health
```

## See Also
- [Helm Chart Values](../../epic-05-cicd/helm/transit-platform/values.yaml)
- [Kong ConfigMap Template](../../epic-05-cicd/helm/transit-platform/templates/kong-declarative-config.yaml)
- [Smoke Tests](../../epic-05-cicd/tests/smoke-test.sh)
