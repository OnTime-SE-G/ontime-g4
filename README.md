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

---

Maintained by G4.

## Repository Structure (Guide-Aligned)

This repository now follows the G4 development guide layout with isolated epic folders:

- `epic-01-messaging`
- `epic-02-security`
- `epic-03-data`
- `epic-04-observability`
- `epic-05-cicd`
- `shared`
- `docs`

Governance files added for day-one team setup:

- `CODEOWNERS`
- `.gitignore`
- `.gitattributes`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/ISSUE_TEMPLATE/g4-task.md`
- `.github/workflows/ci.yml`
- `.github/workflows/pr-checks.yml`

## Copilot Spec Workflow

To support issue implementation with traceable references:

1. Build a searchable index from SRS, SDD, and G4 docs:
	- `c:/python314/python.exe tools/spec/build_spec_index.py`
2. Query relevant sections:
	- `c:/python314/python.exe tools/spec/query_specs.py --query "<topic>" --top 10`
3. Use project prompt commands in Copilot Chat:
	- `/spec-section`
	- `/spec-issue-map`

Customization files are under `.github/`:
- Agent: `.github/agents/spec-librarian.agent.md`
- Skill: `.github/skills/spec-reference/SKILL.md`
- Prompts: `.github/prompts/`

## Copilot G4 Workflow Pack

Additional guide-specific Copilot customizations are included:

- Agent: `.github/agents/g4-workflow-coach.agent.md`
- Skills:
	- `.github/skills/g4-repo-governance/SKILL.md`
	- `.github/skills/g4-issue-delivery/SKILL.md`
- Prompts:
	- `/g4-bootstrap`
	- `/g4-start-issue`
	- `/g4-pr-ready`

## Team Lead Next Steps

1. Replace placeholder GitHub usernames in `CODEOWNERS`.
2. Enable branch protection on `main` (require PR, approvals, status checks, code owner review).
3. Assign each member one epic folder owner role.
4. Start issues using `/g4-start-issue` so each task is mapped to one epic folder with spec references.
