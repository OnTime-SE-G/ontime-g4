# G4-37: GHCR Setup & GitHub Actions Secrets

This document describes how to set up GitHub Container Registry (GHCR) for image storage and configure the required GitHub Actions secrets for CI/CD.

## Overview

The CI pipeline (G4-36) needs:
- A container registry to push built images
- Credentials to authenticate with the registry
- Other secrets for deployment (Kubernetes config, database passwords, tokens)

## GitHub Container Registry (GHCR)

GHCR is GitHub's built-in container registry. Images are stored in the same GitHub organization as the code, and authentication reuses GitHub tokens.

### Enable GHCR on Organization

GHCR is enabled by default for all GitHub organizations. No additional setup is required.

### Image Naming Convention

All G4 images follow this naming scheme:

```
ghcr.io/<github-org>/<repository>/g4-<service>:<tag>
```

**Examples:**
- `ghcr.io/university-transit/ontime-g4/g4-mosquitto:a1b2c3d` (commit SHA)
- `ghcr.io/university-transit/ontime-g4/g4-kong:9aab275` (commit SHA)

## GitHub Actions Secrets

Secrets are configured in the repository settings and accessed in workflows via `${{ secrets.SECRET_NAME }}`.

### How to Add a Secret

1. Go to your GitHub repository
2. Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Enter the name and value
5. Save

### Required Secrets

#### 1. GHCR_TOKEN (Optional)

Personal access token with `packages:write` scope for pushing images.

**When to use:** If the default `GITHUB_TOKEN` (available in workflows) does not have sufficient permissions. For most setups, `GITHUB_TOKEN` is sufficient.

**How to create:**
- Go to your GitHub profile → Settings → Developer settings → Personal access tokens
- Create a new token with scopes: `packages:write`, `packages:read`
- Copy the token and paste into GitHub repository secrets as `GHCR_TOKEN`

#### 2. KUBE_CONFIG (Required for CD stage)

Base64-encoded kubeconfig file for kubectl access to the Digital Ocean Kubernetes cluster.

**How to create:**
```bash
# Get kubeconfig from Digital Ocean cluster
doctl kubernetes cluster kubeconfig save transit-staging

# Base64 encode it
cat ~/.kube/config | base64 | tr -d '\n' > kube_config_b64.txt

# Copy the output and paste into GitHub repository secret as KUBE_CONFIG
```

#### 3. DIGITALOCEAN_ACCESS_TOKEN (Optional for direct DO API access)

Personal access token for Digital Ocean API. Used for cluster provisioning (G4-39).

**How to create:**
- Go to Digital Ocean dashboard → Account → API
- Create a new Personal Access Token with read+write scope
- Copy and paste into GitHub repository secret

#### 4. Platform Passwords (Required for staging)

These secrets are used to generate Kubernetes Secrets during deploy.

- POSTGRES_ADMIN_PASSWORD
- POSTGRES_APP_PASSWORD
- KEYCLOAK_ADMIN_PASSWORD
- INFLUXDB_ADMIN_PASSWORD
- INFLUXDB_ADMIN_TOKEN
- GRAFANA_ADMIN_PASSWORD
- FLYWAY_PASSWORD
- G2_INFLUXDB_TOKEN

These values are consumed by the apply script:
- epic-05-cicd/scripts/apply-secrets.sh

### Checking Secrets

To verify your secrets are configured:

1. Go to Settings → Secrets and variables → Actions
2. Each secret should show as "Updated [date]" (actual value is hidden)

## CI Workflow Authentication

### Docker Login

The `docker/login-action@v3` step uses `GHCR_TOKEN` (if set) or falls back to `GITHUB_TOKEN`:

```yaml
- name: Log in to GHCR
  uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GHCR_TOKEN || secrets.GITHUB_TOKEN }}
```

This allows the subsequent `docker buildx build --push` commands to authenticate with GHCR.

### kubectl Authentication (CD stage)

The CD stage decodes `KUBE_CONFIG` and writes it to `~/.kube/config`:

```yaml
- name: Configure kubectl
  run: |
    mkdir -p ~/.kube
    echo "${{ secrets.KUBE_CONFIG }}" | base64 -d > ~/.kube/config
    kubectl cluster-info
```

## Troubleshooting

### Build fails: "no basic auth credentials"

**Cause:** Docker is not authenticated with GHCR.

**Fix:** Verify `GHCR_TOKEN` or `GITHUB_TOKEN` is set in repository secrets. Re-run the workflow.

### Build fails: "repository name must be lowercase"

**Cause:** Repository name contains uppercase letters.

**Fix:** The CI workflow automatically lowercases the repo name. If the error persists, verify the `repo_lc` variable in `.github/workflows/ci.yml`.

### kubectl fails: "Unable to connect to the server"

**Cause:** `KUBE_CONFIG` is not set or is invalid.

**Fix:** 
1. Verify the secret is set: Settings → Secrets and variables → Actions
2. Verify it's base64-encoded: `base64 -d <<< "$KUBE_CONFIG" | head` should show YAML
3. Re-create the secret if needed

### Deploy stage skipped

**Cause:** The deploy stage only runs on push to `main`, not on pull requests.

**Expected:** PRs should only run Stages 1–5 (lint, unit, contract, build, integration). Deploy runs only after merge.

## Next Steps

- **G4-39:** Provision the Digital Ocean cluster and create/set the `KUBE_CONFIG` secret
- **G4-40:** Add helm upgrade commands to the deploy stage
- **G4-41+:** Expand the Helm charts and test end-to-end deployment

## References

- [GitHub Container Registry Documentation](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions)
- [Docker Login GitHub Action](https://github.com/docker/login-action)
