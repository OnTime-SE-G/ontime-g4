# G4: Platform, Security and Integration

This repository is focused only on Group G4 responsibilities for the public transport tracking and ETA platform.

## Scope

Group G4 covers:
- Service deployment and infrastructure management
- API management and gateway integration
- Monitoring and observability
- Security and system integration

## Core Responsibilities

- Containerize services with Docker
- Deploy and operate workloads on Kubernetes
- Configure API gateway routing and policies (Kong)
- Set up metrics collection and dashboards (Prometheus)
- Enforce secure communication, authentication, and access control

## G4 Future Deliverables

- Dockerfiles and container build strategy
- Kubernetes manifests (or Helm charts) for environments
- Kong gateway configuration for routes, rate limits, and auth
- Prometheus scrape configs and baseline alert rules
- Deployment, rollback, and incident response notes

## Initial Plan

1. Define deployment architecture and environment standards.
2. Add Docker and Kubernetes configuration.
3. Add Kong API gateway setup.
4. Add Prometheus monitoring setup.
5. Document security baseline and integration checklist.

## CI/CD Guide (G4)

This repository uses a 6-stage GitHub Actions pipeline in `.github/workflows/ci.yml`.

Stages (in order):
1. Lint: YAML, Kubernetes manifests, and shell scripts (only if files exist)
2. Unit Test: Python and Node tests with coverage gate at 70% (only if tests exist)
3. Contract Test: Kong config and OpenAPI spec validation (only if files exist)
4. Build Image: Build Docker images and push to GHCR on main (only if Dockerfiles exist)
5. Integration Test: docker-compose + smoke test script (only if files exist)
6. Deploy: Apply k8s manifests on push to main (only if `KUBE_CONFIG_B64` is set)

How to use:
- Add your Kubernetes manifests under `k8s/`
- Keep Kong config in `kong/kong.yaml`
- Keep OpenAPI specs under `specs/`
- Add service Dockerfiles next to each service folder
- Add integration smoke test at `tests/integration/smoke.sh`

Required deploy variable:
- `KUBE_CONFIG_B64`: base64-encoded kubeconfig for the staging cluster

---

Maintained by G4.
