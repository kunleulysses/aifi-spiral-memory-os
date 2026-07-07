const https = require('https');

const DEFAULT_MODEL = 'qwen3.5-flash';
const DEFAULT_BASE_URL = 'https://dashscope-us.aliyuncs.com/compatible-mode/v1/chat/completions';

class QwenCloudClient {
  constructor(options = {}) {
    this.apiKey = options.apiKey ||
      process.env.AIFI_QWEN_API_KEY ||
      process.env.DASHSCOPE_API_KEY ||
      process.env.QWEN_API_KEY ||
      '';
    this.model = options.model || process.env.AIFI_QWEN_MODEL || process.env.DASHSCOPE_MODEL || DEFAULT_MODEL;
    this.baseUrl = options.baseUrl || process.env.AIFI_QWEN_CHAT_URL || process.env.DASHSCOPE_CHAT_URL || DEFAULT_BASE_URL;
    this.timeoutMs = Number(options.timeoutMs || process.env.AIFI_QWEN_TIMEOUT_MS || 15000);
    this.retries = Number(options.retries || process.env.AIFI_QWEN_RETRIES || 3);
    this.retryDelayMs = Number(options.retryDelayMs || process.env.AIFI_QWEN_RETRY_DELAY_MS || 1200);
    this.ipFamily = Number(options.ipFamily || process.env.AIFI_QWEN_IP_FAMILY || 4);
    this.dailyBudget = Number(options.dailyBudget || process.env.AIFI_QWEN_DAILY_BUDGET || 1000000);
    this.callsToday = 0;
    this.day = new Date().toISOString().slice(0, 10);
    this.backoffUntil = 0;
    this.lastProvider = 'not_called';
    this.lastError = null;
    this.lastLatencyMs = null;
  }

  isEnabled() {
    return Boolean(this.apiKey);
  }

  remainingBudget() {
    this.resetIfNeeded();
    return Math.max(0, this.dailyBudget - this.callsToday);
  }

  diagnostics() {
    return {
      provider: this.isEnabled() ? 'qwen_cloud' : 'deterministic_fallback',
      enabled: this.isEnabled(),
      model: this.model,
      baseUrl: this.baseUrl,
      timeoutMs: this.timeoutMs,
      retries: this.retries,
      retryDelayMs: this.retryDelayMs,
      ipFamily: this.ipFamily,
      keyPresent: this.isEnabled(),
      keyFingerprint: this.keyFingerprint(),
      remainingBudget: this.remainingBudget(),
      inBackoff: Date.now() < this.backoffUntil,
      lastProvider: this.lastProvider,
      lastError: this.lastError,
      lastLatencyMs: this.lastLatencyMs
    };
  }

  keyFingerprint() {
    if (!this.apiKey) return null;
    if (this.apiKey.length <= 10) return 'present';
    return `${this.apiKey.slice(0, 6)}...${this.apiKey.slice(-4)}`;
  }

  resetIfNeeded() {
    const today = new Date().toISOString().slice(0, 10);
    if (today !== this.day) {
      this.day = today;
      this.callsToday = 0;
      this.backoffUntil = 0;
    }
  }

  async generateMemoryText({ system, prompt, temperature = 0.65, maxTokens = 420 } = {}) {
    this.resetIfNeeded();
    if (!this.isEnabled()) return this.localFallback(prompt, 'missing_qwen_key');
    if (Date.now() < this.backoffUntil) return this.localFallback(prompt, 'qwen_rate_limit_backoff');
    if (this.remainingBudget() <= 0) return this.localFallback(prompt, 'qwen_daily_budget_exhausted');

    const payload = JSON.stringify({
      model: this.model,
      messages: [
        {
          role: 'system',
          content: system ||
            'You are Qwen powering AI-Fi Spiral Memory OS. Return concise JSON that turns experience into memory, pattern, or anti-pattern.'
        },
        { role: 'user', content: prompt || '' }
      ],
      temperature,
      max_tokens: maxTokens
    });

    const url = new URL(this.baseUrl);
    this.callsToday += 1;
    const startedAt = Date.now();

    try {
      const data = await retryTransient(async () => postJson(url, payload, {
        authorization: `Bearer ${this.apiKey}`,
        timeoutMs: this.timeoutMs,
        ipFamily: this.ipFamily
      }), {
        retries: this.retries,
        delayMs: this.retryDelayMs
      });
      const text = data?.choices?.[0]?.message?.content;
      if (!text) return this.localFallback(prompt, 'empty_qwen_response');
      this.lastProvider = 'qwen_cloud';
      this.lastError = null;
      this.lastLatencyMs = Date.now() - startedAt;
      return {
        ok: true,
        provider: 'qwen_cloud',
        model: this.model,
        text,
        remainingBudget: this.remainingBudget()
      };
    } catch (error) {
      if (/429|rate|quota|thrott/i.test(error.message)) {
        this.backoffUntil = Date.now() + Number(process.env.AIFI_QWEN_BACKOFF_MS || 90_000);
      }
      this.lastProvider = 'deterministic_fallback';
      this.lastError = error.message;
      this.lastLatencyMs = Date.now() - startedAt;
      return this.localFallback(prompt, error.message);
    }
  }

  localFallback(prompt = '', reason = 'fallback') {
    const seed = String(prompt || '').toLowerCase();
    const isRepair = /neglect|stress|repair|lonely|overwhelmed|failure|negative|loss/.test(seed);
    const title = isRepair ? 'Repair Memory: Thread Back Home' : 'Discovery Memory: Door Behind the Wallpaper';
    const kind = isRepair ? 'anti_pattern_repair' : 'positive_pattern_candidate';
    return {
      ok: true,
      provider: 'deterministic_fallback',
      model: 'local-spiral-memory-rules',
      reason,
      text: JSON.stringify({
        title,
        kind,
        memoryLabel: isRepair ? 'anti_pattern' : 'pattern_candidate',
        correctivePressure: isRepair ? ['slow_down', 'repair_trust', 'avoid_repeat_trigger'] : ['explore_more', 'crystallize_if_repeated'],
        steps: isRepair
          ? ['Name the stressor', 'Offer a repair action', 'Record the anti-pattern']
          : ['Inspect the signal', 'Store the memory crystal', 'Wait for repeated confirmation']
      }),
      remainingBudget: this.remainingBudget()
    };
  }
}

function wait(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function isTransient(error) {
  return /ECONNRESET|ETIMEDOUT|EAI_AGAIN|ENOTFOUND|ECONNREFUSED|socket hang up|qwen_timeout|fetch failed/i.test(error.message || '');
}

async function retryTransient(fn, { retries, delayMs }) {
  let lastError = null;
  const maxAttempts = Math.max(1, retries + 1);
  for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;
      if (!isTransient(error) || attempt >= maxAttempts) break;
      await wait(delayMs * attempt);
    }
  }
  throw lastError;
}

function postJson(url, payload, { authorization, timeoutMs, ipFamily }) {
  return new Promise((resolve, reject) => {
    const req = https.request({
      method: 'POST',
      hostname: url.hostname,
      path: `${url.pathname}${url.search}`,
      family: ipFamily || undefined,
      agent: new https.Agent({
        keepAlive: false,
        family: ipFamily || undefined
      }),
      headers: {
        authorization,
        'content-type': 'application/json',
        'content-length': Buffer.byteLength(payload),
        'user-agent': 'aifi-spiral-memory-os/0.1'
      },
      timeout: timeoutMs
    }, res => {
      let raw = '';
      res.on('data', chunk => {
        raw += chunk;
      });
      res.on('end', () => {
        let parsed = null;
        try {
          parsed = raw ? JSON.parse(raw) : null;
        } catch (_) {
          // keep raw for diagnostics
        }
        if (res.statusCode < 200 || res.statusCode >= 300) {
          return reject(new Error(`qwen_http_${res.statusCode}:${raw.slice(0, 300)}`));
        }
        resolve(parsed);
      });
    });
    req.on('timeout', () => {
      req.destroy(new Error('qwen_timeout'));
    });
    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}

module.exports = {
  QwenCloudClient
};
