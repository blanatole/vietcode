import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';

const CONFIG_DIR = path.join(os.homedir(), '.vietcode');
const CONFIG_FILE = path.join(CONFIG_DIR, 'config.json');
export const ALLOWED_MODELS = ['gpt-5.4', 'gpt-5.3-codex', 'gpt-5.2'];

const BACKEND_TO_ALIAS = {
  'gpt-5.4': 'Sonnet 4.6',
  'gpt-5.3-codex': 'Opus 4.6',
  'gpt-5.2': 'Haiku 4.5'
};

const DEFAULT_CONFIG = {
  api_key: '',
  base_url: 'https://vietapi.tech',
  model: 'gpt-5.4',
  identity: 'You are an expert AI coding assistant. You are helpful, precise, and have full access to tools to improve the codebase.',
  model_mapping: {
    'claude-sonnet-4-6': 'gpt-5.4',
    'claude-opus-4-6': 'gpt-5.3-codex',
    'claude-haiku-4-5': 'gpt-5.2',
    'sonnet 4.6': 'gpt-5.4',
    'opus 4.6': 'gpt-5.3-codex',
    'haiku 4.5': 'gpt-5.2',
    'gpt-5.4': 'gpt-5.4',
    'gpt-5.3-codex': 'gpt-5.3-codex',
    'gpt-5.2': 'gpt-5.2'
  }
};

function normalizeModel(model) {
  return ALLOWED_MODELS.includes(model) ? model : DEFAULT_CONFIG.model;
}

function normalizeModelMapping(mapping = {}) {
  return Object.fromEntries(
    Object.entries(mapping).map(([key, value]) => [key.toLowerCase(), normalizeModel(value)])
  );
}

export function getModelAlias(model) {
  return BACKEND_TO_ALIAS[normalizeModel(model)] || BACKEND_TO_ALIAS[DEFAULT_CONFIG.model];
}

export function resolveModelAlias(requestedModel, fallbackModel, modelMapping = {}) {
  if (!requestedModel) {
    return normalizeModel(fallbackModel);
  }

  const mapping = normalizeModelMapping(modelMapping);
  const normalizedRequested = String(requestedModel).toLowerCase();

  return mapping[normalizedRequested] || normalizeModel(requestedModel) || normalizeModel(fallbackModel);
}

export function loadConfig() {
  if (!fs.existsSync(CONFIG_FILE)) {
    return DEFAULT_CONFIG;
  }
  try {
    const data = fs.readFileSync(CONFIG_FILE, 'utf8');
    const loaded = JSON.parse(data);
    return {
      ...DEFAULT_CONFIG,
      ...loaded,
      model: normalizeModel(loaded.model),
      model_mapping: {
        ...DEFAULT_CONFIG.model_mapping,
        ...normalizeModelMapping(loaded.model_mapping || {})
      }
    };
  } catch (e) {
    return DEFAULT_CONFIG;
  }
}

export function saveConfig(config) {
  if (!fs.existsSync(CONFIG_DIR)) {
    fs.mkdirSync(CONFIG_DIR, { recursive: true });
  }

  const normalizedConfig = {
    ...DEFAULT_CONFIG,
    ...config,
    model: normalizeModel(config.model),
    model_mapping: {
      ...DEFAULT_CONFIG.model_mapping,
      ...normalizeModelMapping(config.model_mapping || {})
    }
  };

  fs.writeFileSync(CONFIG_FILE, JSON.stringify(normalizedConfig, null, 2));
}

export function getEffectiveConfig() {
  const fileConfig = loadConfig();
  const model = normalizeModel(process.env.VIETCODE_MODEL || fileConfig.model);

  return {
    api_key: process.env.VIETCODE_API_KEY || fileConfig.api_key,
    base_url: process.env.VIETCODE_BASE_URL || fileConfig.base_url,
    model,
    identity: process.env.VIETCODE_IDENTITY || fileConfig.identity,
    model_mapping: {
      ...DEFAULT_CONFIG.model_mapping,
      ...normalizeModelMapping(fileConfig.model_mapping)
    }
  };
}
