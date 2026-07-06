# Alibaba Cloud Deployment Proof

This file is included for the Qwen Cloud hackathon requirement:

> Provide proof that the backend is running on Alibaba Cloud and link to a code file that demonstrates use of Alibaba Cloud services and APIs.

## Qwen Cloud API Usage

The backend uses Qwen Cloud through Alibaba Cloud Model Studio's OpenAI-compatible API.

Code file:

```text
backend/qwen-cloud-client.cjs
```

Environment variables used by the backend:

```bash
DASHSCOPE_API_KEY=...
AIFI_QWEN_MODEL=qwen3.5-flash
AIFI_QWEN_CHAT_URL=https://dashscope-us.aliyuncs.com/compatible-mode/v1/chat/completions
```

## Alibaba Cloud Runtime Proof

Deployment target:

```text
Alibaba Cloud ECS
```

Runtime command:

```bash
node backend/creature-server.cjs
```

Health check:

```bash
curl http://<alibaba-ecs-host>:8787/creature/health
```

Expected response shape:

```json
{
  "ok": true,
  "message": "spiral_memory_backend_live",
  "llm": {
    "provider": "qwen_cloud",
    "enabled": true
  }
}
```

## Proof Video

Add the public proof video here after deployment:

```text
TODO: https://...
```

## Deployment Notes

The public repository intentionally excludes real credentials. Qwen/DashScope keys must be configured through Alibaba Cloud environment variables or a secret manager.
