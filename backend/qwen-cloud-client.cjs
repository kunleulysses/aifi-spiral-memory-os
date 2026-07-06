const https = require('https');

const DEFAULT_MODEL = 'qwen3.5-flash';
const DEFAULT_BASE_URL = 'https://dashscope-intl.aliyuncs.com/compatible-mode/v1/chat/completions';

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
    this.dailyBudget = Number(options.dailyBudget || process.env.AIFI_QWEN_DAILY_BUDGET || 1000000);
    this.callsToday = 0;
    this.day = new Date().toISOString().slice(0, 10);
    this.backoffUntil = 0;
  }

  isEnabled() {
    return Boolean(this.apiKey);
  }

  remainingBudget() {
    this.resetIfNeeded();
    return Math.max(0, this.dailyBudget - this.callsToday);
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

    try {
      const data = await postJson(url, payload, {
        authorization: `Bearer ${this.apiKey}`,
        timeoutMs: this.timeoutMs
      });
      const text = data?.choices?.[0]?.message?.content;
      if (!text) return this.localFallback(prompt, 'empty_qwen_response');
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

function postJson(url, payload, { authorization, timeoutMs }) {
  return new Promise((resolve, reject) => {
    const req = https.request({
      method: 'POST',
      hostname: url.hostname,
      path: `${url.pathname}${url.search}`,
      headers: {
        authorization,
        'content-type': 'application/json',
        'content-length': Buffer.byteLength(payload)
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
