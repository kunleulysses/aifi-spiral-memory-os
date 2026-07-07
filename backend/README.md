# AI-Fi Spiral Memory Backend

Minimal isolated API for the AI-Fi Spiral Memory OS vertical slice.

The backend uses only built-in Node modules and Qwen Cloud environment variables. It does not import the production finance runtime.

## Run

```bash
DASHSCOPE_API_KEY=... \
AIFI_QWEN_MODEL=qwen3.5-flash \
./scripts/run-demo-backend.sh
```

The Qwen key must stay in the process environment or deployment secret manager. Do not commit it to this repo or embed it in the iOS app.

## Endpoints

- `GET /creature/health`
- `GET /creature/bootstrap`
- `GET /creature/state`
- `POST /creature/event`
- `GET /creature/modules/active`
- `POST /creature/reality/generate`
- `POST /creature/mutation/propose`
- `POST /creature/modules/outcome`
- `POST /creature/mutation/rollback`

## Qwen Cloud File

The hackathon-required Qwen Cloud integration lives in:

```text
backend/qwen-cloud-client.cjs
```

It calls Alibaba/Qwen Cloud through an OpenAI-compatible chat-completions endpoint and returns deterministic fallback output when no key is configured.
