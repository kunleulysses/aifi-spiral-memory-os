#!/usr/bin/env node

const { QwenCloudClient } = require('../backend/qwen-cloud-client.cjs');

async function main() {
  const client = new QwenCloudClient({
    timeoutMs: Number(process.env.AIFI_QWEN_TIMEOUT_MS || 90000),
    retries: Number(process.env.AIFI_QWEN_RETRIES || 4),
    retryDelayMs: Number(process.env.AIFI_QWEN_RETRY_DELAY_MS || 1500),
    ipFamily: Number(process.env.AIFI_QWEN_IP_FAMILY || 4)
  });

  const result = await client.generateMemoryText({
    system: 'Return concise JSON for an AI-Fi Spiral Memory OS smoke test.',
    prompt: 'Create a tiny proof that Qwen Cloud is reachable.',
    temperature: 0.1,
    maxTokens: 120
  });

  console.log(JSON.stringify({
    diagnostics: client.diagnostics(),
    result
  }, null, 2));
}

main().catch(error => {
  console.error(JSON.stringify({
    ok: false,
    error: error.message
  }, null, 2));
  process.exit(1);
});

