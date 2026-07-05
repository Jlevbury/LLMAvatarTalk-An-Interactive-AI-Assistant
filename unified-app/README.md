# Unified App: Hermes Agent + AIRI

A single Docker Compose stack that combines two upstream projects into one
application:

| Role | Project | What it provides |
|------|---------|------------------|
| Brain | [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent) | Agentic LLM backend: orchestration, tools (terminal, files, web search), long-term memory, skills |
| Face | [moeru-ai/airi](https://github.com/moeru-ai/airi) | Browser-based VTuber-style frontend: VRM/Live2D avatar rendering, speech recognition (ASR), speech synthesis (TTS) |

Neither project is forked or modified. Both are vendored as git submodules
under `vendor/`, and the bridge is pure configuration:

- Hermes Agent ships a built-in **OpenAI-compatible API server**
  (`/v1/chat/completions` on port 8642), enabled here via `API_SERVER_*`
  environment variables.
- AIRI ships a built-in **"OpenAI Compatible" provider** you can point at any
  base URL through its Settings UI.

So AIRI talks to Hermes exactly the way it would talk to OpenAI — except the
"model" on the other end is a full agent with tools, memory, and skills.

```
Browser ── http://localhost:6620 ──> [airi]   nginx serving the AIRI SPA
   │
   └───── http://localhost:8642/v1 ─> [hermes] gateway + OpenAI-compatible API
                                         │
                                         └──> your configured LLM provider
                                              (OpenRouter, OpenAI, local, ...)
```

Because AIRI runs entirely in your browser (not server-side), the browser
calls Hermes directly; the compose file therefore sets
`API_SERVER_CORS_ORIGINS` to allow the AIRI origin.

## Prerequisites

- Docker with the compose plugin
- An API key for at least one LLM provider Hermes supports (OpenRouter,
  OpenAI, Anthropic, a local OpenAI-compatible server, etc.)

## Setup

```bash
# from the repo root
cd unified-app
./scripts/setup.sh
```

The script initializes the submodules, creates `.env` from `.env.example`,
and generates a random `API_SERVER_KEY` (the bearer token AIRI will use to
authenticate against Hermes).

### 1. Configure Hermes' LLM provider (one-time)

Hermes needs to know which LLM to use. Run its interactive wizard inside the
container:

```bash
docker compose run --rm hermes setup
```

or edit `data/hermes/config.yaml` / `data/hermes/.env` directly (that
directory is this stack's equivalent of `~/.hermes`; see
`vendor/hermes-agent/README.md`).

### 2. Start the stack

```bash
docker compose up -d --build
```

The first build takes a while — it builds the Hermes image and compiles the
whole AIRI web app (a pnpm monorepo) from source.

### 3. Connect AIRI to Hermes

1. Open **http://localhost:6620**.
2. Go to **Settings → Providers → OpenAI Compatible** and set:
   - **Base URL:** `http://localhost:8642/v1/`
   - **API key:** the `API_SERVER_KEY` value from `unified-app/.env`
3. Go to **Settings → Modules → Consciousness**, choose the OpenAI-compatible
   provider, and pick the `hermes-agent` model.

Speak or type to the avatar — replies now come from Hermes Agent, with its
full toolset. Optionally configure AIRI's Speech/Hearing modules (TTS/ASR
providers) in the same Settings area for a fully voiced experience.

## Configuration

All knobs live in `unified-app/.env` (see `.env.example`):

| Variable | Default | Purpose |
|----------|---------|---------|
| `API_SERVER_KEY` | _(required)_ | Bearer token for the Hermes API server |
| `AIRI_PORT` | `6620` | Host port for the AIRI frontend |
| `HERMES_PORT` | `8642` | Host port for the Hermes API |
| `API_SERVER_CORS_ORIGINS` | `http://localhost:6620,...` | Browser origins allowed to call Hermes; keep in sync with `AIRI_PORT` |
| `API_SERVER_MODEL_NAME` | `hermes-agent` | Model name Hermes advertises to AIRI |
| `HERMES_UID` / `HERMES_GID` | `10000` | Host ownership of files under `data/hermes/` |

Hermes' own configuration (provider keys, memory, skills, toolsets) lives in
`data/hermes/`, which is git-ignored.

## Security notes

- The Hermes API server exposes the agent's **full toolset, including a
  terminal inside the container**. Both services are published on
  `127.0.0.1` only; do not rebind them to `0.0.0.0` on an untrusted network.
- `API_SERVER_KEY` is required and enforced on every request.
- CORS is restricted to the explicit allowlist in `API_SERVER_CORS_ORIGINS`.

## Updating the vendored projects

```bash
git submodule update --remote unified-app/vendor/hermes-agent
git submodule update --remote unified-app/vendor/airi
docker compose build --no-cache
```

## Troubleshooting

- **AIRI shows a provider/network error** — verify the base URL ends with
  `/v1/`, the API key matches `.env`, and `curl http://localhost:8642/health`
  returns `{"status": "ok"}`.
- **Browser console shows CORS errors** — the origin you opened AIRI from
  must appear in `API_SERVER_CORS_ORIGINS` exactly (scheme + host + port),
  then `docker compose up -d` to apply.
- **Hermes container exits at startup** — its LLM provider isn't configured
  yet; run `docker compose run --rm hermes setup` (step 1) and check
  `docker compose logs hermes`.
