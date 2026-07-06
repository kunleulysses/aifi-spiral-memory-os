# AI-Fi Spiral Memory OS Demo Video

Target length: 2:45 to 3:10.

Core story: most agents remember facts. AI-Fi remembers outcomes, then turns repeated outcomes into patterns, anti-patterns, corrective pressure, and governed self-improvement.

## Before Recording

Run the key export off camera so the API key never appears in the video:

```bash
cd /Users/ulyssesadejokun/Documents/Codex/2026-06-25/is/aifi-spiral-memory-os-public
export DASHSCOPE_API_KEY="paste-your-qwen-cloud-key-here"
export AIFI_QWEN_MODEL="qwen3.5-flash"
```

Start the backend in one terminal:

```bash
node backend/creature-server.cjs
```

Use a second terminal for the demo commands. Increase terminal text size before recording.

## One-Take Command Path

Health check:

```bash
curl -s http://127.0.0.1:8787/creature/health | python3 -m json.tool
```

Show the live memory state:

```bash
curl -s http://127.0.0.1:8787/creature/state | python3 -m json.tool
```

Trigger a negative experience:

```bash
curl -s -X POST http://127.0.0.1:8787/creature/event \
  -H 'content-type: application/json' \
  -d '{"action":"ignore","intensity":0.95}' | python3 -m json.tool
```

Ask Qwen Cloud to turn the moment into spiral memory:

```bash
curl -s -X POST http://127.0.0.1:8787/creature/reality/generate \
  -H 'content-type: application/json' \
  -d '{"event":"The agent repeated a mistake. Create an anti-pattern repair memory."}' | python3 -m json.tool
```

Propose a governed self-improvement module:

```bash
curl -s -X POST http://127.0.0.1:8787/creature/mutation/propose \
  -H 'content-type: application/json' \
  -d '{"id":"careful-memory-gate","type":"behavior_module","permissions":["creature.read_pet_state","creature.write_memory"],"description":"Only strengthen memories after repeated positive outcomes."}' | python3 -m json.tool
```

Record an outcome label:

```bash
curl -s -X POST http://127.0.0.1:8787/creature/modules/outcome \
  -H 'content-type: application/json' \
  -d '{"moduleId":"careful-memory-gate","outcome":"positive","notes":"The module reduced repeated negative memory loops."}' | python3 -m json.tool
```

Show active modules:

```bash
curl -s http://127.0.0.1:8787/creature/modules/active | python3 -m json.tool
```

## Shot-By-Shot Script

### 0:00-0:20 Hook

Show `media/devpost/01-cover.png`.

Voiceover:

> Most agents remember facts. AI-Fi Spiral Memory OS remembers outcomes. The idea is simple but powerful: experience should not just sit in a log. It should mature into memory, pressure, and better future behavior.

### 0:20-0:45 Architecture

Show `media/devpost/02-architecture.png`.

Voiceover:

> This is the vertical slice we built for the hackathon. A user event enters the system, Qwen Cloud reasons over it, spiral memory stores the result, and outcome truth decides whether that experience becomes a pattern, an anti-pattern, or a candidate for system DNA.

### 0:45-1:05 Live Backend

Show the health check terminal output.

Voiceover:

> The backend is live locally and routed to Alibaba Cloud's Qwen API. If the key is unavailable, the project still runs with a deterministic fallback so judges can inspect the architecture.

Point out:

- `provider: qwen_cloud`
- `model: qwen3.5-flash`
- `realityGeneration: true`
- `moduleValidation: true`

### 1:05-1:35 Spiral Memory Event

Run the negative event command, then show the state output.

Voiceover:

> Now I trigger a bad experience. AI-Fi does not hide that. It creates a high-salience memory crystal. In a full agent, this is the moment where the system starts saying: do not repeat this pattern blindly.

### 1:35-2:00 Qwen Reflection

Run the `reality/generate` command.

Voiceover:

> Qwen Cloud turns the raw event into structured memory language: what happened, why it matters, what corrective pressure should exist, and what steps the agent should take next. Qwen is the reasoning layer, but outcome memory decides what survives.

### 2:00-2:30 Governed Self-Improvement

Run the module proposal and outcome label commands.

Voiceover:

> AI-Fi can propose new behavior, but generated modules do not get direct authority just because they sound smart. They pass through a validation boundary, canary stage, and outcome labels. Positive outcomes can expand authority. Negative outcomes become rollback pressure.

### 2:30-2:55 Proof And Close

Show:

- `README.md`
- `docs/ARCHITECTURE.md`
- `docs/alibaba-cloud-deployment-proof.md`
- `media/devpost/00-contact-sheet.png`

Voiceover:

> This is AI-Fi Spiral Memory OS: a memory operating system for agents that need to grow up over time. The long-term vision is bigger than a demo pet. The same pattern can support robotics, logistics, healthcare operations, manufacturing, and any autonomous system that needs to remember outcomes, not just facts.

Final line:

> AI-Fi remembers, reasons, repairs, and improves.

## Devpost Media Upload Order

Upload these images first:

1. `media/devpost/01-cover.png`
2. `media/devpost/02-architecture.png`
3. `media/devpost/03-spiral-memory-loop.png`
4. `media/devpost/04-qwen-cloud-integration.png`
5. `media/devpost/05-antipattern-repair.png`
6. `media/devpost/06-governed-self-improvement.png`

Optional supporting images:

1. `media/devpost/07-video-storyboard.png`
2. `media/devpost/00-contact-sheet.png`

## Recording Tips

- Use QuickTime Player -> New Screen Recording.
- Record the browser, terminal, and image previews only. Do not record the API key.
- Make the terminal large enough for judges to read.
- Keep the mouse still when speaking.
- Upload the finished video to YouTube as unlisted or public, then paste that link into Devpost.
- If Qwen rate-limits during recording, say: "The fallback path is active so judges can still test the project." Then continue.

