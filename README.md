# api-e2e — Claude Code Skill

A Claude Code skill that analyzes your branch diff, discovers every API endpoint that was added or modified, builds a structured test plan, executes it against your local server with `curl`, and reports a pass/fail summary.

Works with **any backend framework**: Express, Fastify, NestJS, FastAPI, Flask, Django, Rails, Go/chi, Go/gin, Laravel, Spring Boot, and others.

## What it does

1. **Detects your tech stack** and finds the local server port
2. **Diffs the branch** (`origin/main...HEAD`) and classifies changed files into routes, controllers, services, schemas, and client code
3. **Extracts affected endpoints** using framework-specific patterns
4. **Prompts for auth tokens** (Bearer, API key, cookie — whatever your API uses)
5. **Builds a test plan** covering happy path, auth missing, wrong role, invalid body, state verification, and cleanup — shows it to you before running
6. **Executes each test** sequentially with `curl` + `python3` for JSON assertions
7. **Reports** a pass/fail table and suggests causes for any failures

## Installation

### Option A — Claude Code CLI (recommended)

```bash
claude skills install https://github.com/<your-username>/claude-skill-api-e2e
```

### Option B — Manual

```bash
mkdir -p ~/.claude/skills/api-e2e
curl -sSL https://raw.githubusercontent.com/<your-username>/claude-skill-api-e2e/main/SKILL.md \
  -o ~/.claude/skills/api-e2e/SKILL.md
```

## Usage

In any Claude Code session, with your local server running:

```
/api-e2e
```

To diff against a different base branch:

```
/api-e2e origin/dev
```

## Test cases generated

| Scenario | Applies to |
|----------|-----------|
| Happy path (2xx) | All endpoints |
| Auth missing (401) | All authenticated endpoints |
| Wrong role (403) | Role-restricted endpoints |
| Invalid body (400/422) | Endpoints with validation |
| State verification (GET after mutation) | POST/PUT/PATCH/DELETE |
| Cleanup (restore original state) | POST/PUT/PATCH/DELETE |
| Order preserved after add/update | Ordering endpoints |
| Idempotent reorder | Ordering endpoints |
| Empty result / boundary values | Paginated/filtered endpoints |

## Requirements

- Claude Code CLI
- `curl` and `python3` available in your shell
- Local dev server running before invoking the skill

## Supported frameworks

| Language | Frameworks |
|----------|-----------|
| Node.js | Express, Fastify, Hono, NestJS |
| Python | FastAPI, Flask, Django |
| Ruby | Rails |
| Go | chi, gin, echo, gorilla/mux |
| Java/Kotlin | Spring Boot |
| PHP | Laravel |

## License

MIT
