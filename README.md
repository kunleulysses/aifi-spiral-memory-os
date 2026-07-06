# AI-Fi Spiral Memory OS

AI-Fi Spiral Memory OS is a Qwen-powered memory agent that turns real-world outcomes into evolving behavior, corrective pressure, and self-improving system DNA.

This repository is a hackathon-safe, finance-isolated vertical slice of the broader AI-Fi architecture. It demonstrates persistent memory, outcome labeling, anti-pattern formation, module validation, and governed self-improvement without exposing live trading systems, credentials, or production infrastructure.

## Hackathon Track

Primary track: **MemoryAgent**

Secondary fit: **Agent Society**

## What It Does

The core loop is:

```text
experience -> spiral memory -> pattern or anti-pattern -> decision pressure -> action -> external truth -> updated memory
```

AI-Fi Spiral Memory OS can:

- Store treatment and outcome memories across sessions.
- Turn high-salience events into memory crystals.
- Use Qwen Cloud to generate memory events, repair quests, and module proposals.
- Label repeated negative outcomes as anti-pattern pressure.
- Validate generated modules before activation.
- Record outcome labels so self-improvement is accountable to external truth.
- Keep a strict finance boundary so this public demo cannot touch broker credentials or trading services.

## Qwen Cloud Integration

The backend uses Alibaba/Qwen Cloud through the OpenAI-compatible chat API.

Relevant file:

- [`backend/qwen-cloud-client.cjs`](backend/qwen-cloud-client.cjs)

Environment variables:

```bash
export DASHSCOPE_API_KEY="your-qwen-cloud-api-key"
export AIFI_QWEN_MODEL="qwen3.5-flash"
export AIFI_QWEN_CHAT_URL="https://dashscope-intl.aliyuncs.com/compatible-mode/v1/chat/completions"
node backend/creature-server.cjs
```

If no Qwen key is present, the backend uses a deterministic local fallback so judges can still run and test the project.

## Run Backend

```bash
node backend/creature-server.cjs
```

Health check:

```bash
curl http://127.0.0.1:8787/creature/health
```

Generate a spiral memory event:

```bash
curl -s http://127.0.0.1:8787/creature/reality/generate \
  -H 'content-type: application/json' \
  -d '{"event":"the agent repeated a mistake and needs to form an anti-pattern"}'
```

## Run Swift Core Tests

```bash
swift test
```

## Run Demo Simulation

```bash
swift run aifi-creature-demo
```

## Architecture

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Alibaba Cloud Deployment Proof

See [`docs/alibaba-cloud-deployment-proof.md`](docs/alibaba-cloud-deployment-proof.md).

## Finance Boundary

This repo intentionally excludes live finance infrastructure. See [`FINANCE_ISOLATION.md`](FINANCE_ISOLATION.md).

## Devpost Summary

Most agents remember facts. AI-Fi Spiral Memory OS remembers outcomes.

Positive experiences can become pattern candidates. Negative experiences become anti-pattern pressure. Qwen Cloud reasons over the memory field, proposes repair actions, and helps transform experience into safer future behavior.

The long-term vision is a memory operating system for autonomous agents in finance, robotics, logistics, healthcare operations, manufacturing, and any domain where agents need to mature over time.
