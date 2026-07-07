#!/usr/bin/env node

const http = require('http');
const crypto = require('crypto');
const { QwenCloudClient } = require('./qwen-cloud-client.cjs');

const PORT = Number(process.env.AIFI_CREATURE_PORT || 8787);
const llm = new QwenCloudClient();

const forbiddenFinanceTerms = [
  'alpaca',
  'metatrader',
  'broker',
  'portfolio',
  'trading',
  'api_secret'
];

const state = {
  pet: {
    id: crypto.randomUUID(),
    name: process.env.AIFI_CREATURE_NAME || 'Astra',
    lifeStage: 'baby',
    mood: 'curious',
    needs: {
      hunger: 0.35,
      energy: 0.7,
      hygiene: 0.85,
      wonder: 0.55,
      trust: 0.5,
      attachment: 0.45,
      stress: 0.15,
      boredom: 0.2
    },
    treatmentTrace: [],
    memoryCrystals: [],
    activeQuestlines: [],
    generatedModules: []
  },
  capabilityManifest: {
    generatedAt: new Date().toISOString(),
    capabilities: [
      { id: 'creature_api', status: 'live', notes: 'Isolated creature API process.' },
      { id: 'finance_boundary', status: 'live', notes: 'Finance terms are blocked from generated modules.' },
      { id: 'module_validator', status: 'live', notes: 'Declarative generated modules are validated before activation.' },
      { id: 'canary_rollout', status: 'live', notes: 'Game-truth labels gate expansion.' },
      { id: 'spiral_memory_bridge', status: 'degraded', notes: 'Local in-memory vertical slice; DB bridge planned.' }
    ]
  },
  gameTruthLabels: []
};

function send(res, status, payload) {
  res.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    'cache-control': 'no-store'
  });
  res.end(JSON.stringify(payload, null, 2));
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let raw = '';
    req.on('data', chunk => {
      raw += chunk;
      if (raw.length > 1_000_000) {
        reject(new Error('body_too_large'));
        req.destroy();
      }
    });
    req.on('end', () => {
      if (!raw) return resolve({});
      try {
        resolve(JSON.parse(raw));
      } catch (error) {
        reject(error);
      }
    });
  });
}

function validateModule(module) {
  const reasons = [];
  if (!module || typeof module !== 'object') reasons.push('module_required');
  if (!module.id) reasons.push('module_id_required');
  if (!module.type) reasons.push('module_type_required');
  if (!Array.isArray(module.permissions) || module.permissions.length === 0) {
    reasons.push('module_permissions_required');
  }
  const serialized = JSON.stringify(module || {}).toLowerCase();
  if (forbiddenFinanceTerms.some(term => serialized.includes(term))) {
    reasons.push('finance_boundary_violation');
  }
  return { allowed: reasons.length === 0, reasonCodes: reasons };
}

function applyTreatment(action, intensity = 0.85) {
  const normalized = String(action || 'affection').trim().toLowerCase();
  const amount = Math.max(0, Math.min(1, Number(intensity) || 0.85));
  const event = {
    id: crypto.randomUUID(),
    action: normalized,
    intensity: amount,
    timestamp: new Date().toISOString()
  };

  state.pet.treatmentTrace.push(event);
  const needs = state.pet.needs;
  if (['affection', 'comfort', 'repair'].includes(normalized)) {
    needs.trust = Math.min(1, needs.trust + 0.12 * amount);
    needs.attachment = Math.min(1, needs.attachment + 0.12 * amount);
    needs.stress = Math.max(0, needs.stress - 0.16 * amount);
    state.pet.mood = needs.stress > 0.45 ? 'repairing' : 'radiant';
  } else if (['ignore', 'rush', 'startle'].includes(normalized)) {
    needs.stress = Math.min(1, needs.stress + 0.20 * amount);
    needs.boredom = Math.min(1, needs.boredom + 0.12 * amount);
    needs.attachment = Math.max(0, needs.attachment - 0.08 * amount);
    state.pet.mood = needs.stress > 0.65 ? 'overwhelmed' : 'guarded';
  } else if (normalized === 'play') {
    needs.boredom = Math.max(0, needs.boredom - 0.28 * amount);
    needs.attachment = Math.min(1, needs.attachment + 0.08 * amount);
    state.pet.mood = 'curious';
  } else if (normalized === 'explore') {
    needs.wonder = Math.min(1, needs.wonder + 0.22 * amount);
    state.pet.mood = 'curious';
  }

  if (amount >= 0.9 || ['ignore', 'rush', 'startle', 'repair'].includes(normalized)) {
    state.pet.memoryCrystals.push({
      id: crypto.randomUUID(),
      title: ['ignore', 'rush', 'startle'].includes(normalized)
        ? `Antipattern: ${normalized}`
        : `Crystal of ${normalized}`,
      trigger: normalized,
      resonance: amount,
      valence: ['ignore', 'rush', 'startle'].includes(normalized) ? -0.75 : 0.85,
      createdAt: new Date().toISOString()
    });
  }

  if (needs.attachment < 0.35 || needs.stress > 0.65) {
    state.pet.activeQuestlines = [{
      id: crypto.randomUUID(),
      title: 'Thread Back Home',
      kind: 'trust_repair',
      reason: 'The pet is trying to repair the relationship.',
      steps: ['Sit quietly together', 'Offer a familiar snack', 'Touch the dim memory crystal']
    }];
  }

  return event;
}

async function handler(req, res) {
  try {
    const url = new URL(req.url, `http://${req.headers.host}`);

    if (req.method === 'GET' && url.pathname === '/creature/health') {
      return send(res, 200, {
        ok: true,
        message: 'spiral_memory_backend_live',
        pid: process.pid,
        llm: {
          ...llm.diagnostics()
        },
        features: {
          careEvents: true,
          realityGeneration: true,
          moduleValidation: true,
          financeBoundary: true,
          canaryLabels: true
        }
      });
    }

    if (req.method === 'GET' && url.pathname === '/creature/bootstrap') {
      return send(res, 200, state);
    }

    if (req.method === 'GET' && url.pathname === '/creature/llm') {
      return send(res, 200, llm.diagnostics());
    }

    if (req.method === 'POST' && url.pathname === '/creature/llm/smoke') {
      const result = await llm.generateMemoryText({
        system: 'Return exactly this JSON shape: {"ok":true,"message":"qwen_cloud_smoke_ok"}.',
        prompt: 'Smoke test AI-Fi Spiral Memory OS Qwen Cloud integration.',
        temperature: 0.1,
        maxTokens: 80
      });
      return send(res, 200, {
        diagnostics: llm.diagnostics(),
        result
      });
    }

    if (req.method === 'GET' && url.pathname === '/creature/state') {
      return send(res, 200, state.pet);
    }

    if (req.method === 'POST' && url.pathname === '/creature/event') {
      const body = await readBody(req);
      const event = applyTreatment(body.action, body.intensity);
      return send(res, 200, { accepted: true, event, pet: state.pet });
    }

    if (req.method === 'GET' && url.pathname === '/creature/modules/active') {
      return send(res, 200, { modules: state.pet.generatedModules });
    }

    if (req.method === 'POST' && url.pathname === '/creature/mutation/propose') {
      const module = await readBody(req);
      const validation = validateModule(module);
      if (!validation.allowed) {
        return send(res, 422, { accepted: false, validation });
      }
      state.pet.generatedModules.push({
        ...module,
        createdAt: new Date().toISOString(),
        rolloutStage: 'test_pets_only'
      });
      return send(res, 200, { accepted: true, validation, module });
    }

    if (req.method === 'POST' && url.pathname === '/creature/reality/generate') {
      const body = await readBody(req);
      const result = await llm.generateMemoryText({
        system: 'Generate a safe AI-Fi Spiral Memory event. Return JSON with title, kind, memoryLabel, correctivePressure, reason, and steps.',
        prompt: JSON.stringify({
          pet: state.pet,
          request: body
        }),
        temperature: 0.9,
        maxTokens: 500
      });
      return send(res, 200, result);
    }

    if (req.method === 'POST' && url.pathname === '/creature/modules/outcome') {
      const label = await readBody(req);
      state.gameTruthLabels.push({ ...label, recordedAt: new Date().toISOString() });
      return send(res, 200, { accepted: true, labelCount: state.gameTruthLabels.length });
    }

    if (req.method === 'POST' && url.pathname === '/creature/mutation/rollback') {
      const body = await readBody(req);
      const before = state.pet.generatedModules.length;
      state.pet.generatedModules = state.pet.generatedModules.filter(module => module.id !== body.moduleId);
      return send(res, 200, { accepted: true, removed: before - state.pet.generatedModules.length });
    }

    return send(res, 404, { error: 'not_found' });
  } catch (error) {
    return send(res, 500, { error: 'creature_server_error', message: error.message });
  }
}

if (require.main === module) {
  http.createServer(handler).listen(PORT, '127.0.0.1', () => {
    console.log(`aifi-creature server listening on http://127.0.0.1:${PORT}`);
  });
}

module.exports = { handler, validateModule, applyTreatment, state };
