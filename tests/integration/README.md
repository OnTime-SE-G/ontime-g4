# Integration Smoke Tests (Placeholder)

Run the minimal compose stack and verify the mock health endpoint responds.

Example:

```bash
docker compose -f docker/docker-compose.yml up -d
./tests/integration/smoke.sh
docker compose -f docker/docker-compose.yml down
```
