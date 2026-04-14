import http from 'node:http';
import https from 'node:https';
import { getEffectiveConfig, resolveModelAlias } from './config.js';

function buildModelsResponse() {
  return {
    data: [
      {
        id: 'claude-sonnet-4-6',
        type: 'model',
        display_name: 'Sonnet 4.6'
      },
      {
        id: 'claude-opus-4-6',
        type: 'model',
        display_name: 'Opus 4.6'
      },
      {
        id: 'claude-haiku-4-5',
        type: 'model',
        display_name: 'Haiku 4.5'
      }
    ]
  };
}

function isModelsRequest(req) {
  return req.method === 'GET' && (req.url === '/v1/models' || req.url === '/models');
}

function patchPayloadModel(payload, config) {
  if (!payload || typeof payload !== 'object') {
    return payload;
  }

  const requestedModel = payload.model;
  payload.model = resolveModelAlias(requestedModel, config.model, config.model_mapping);

  if (payload.system) {
    payload.system = config.identity;
  }

  return payload;
}

function sanitizeErrorBody(buffer, config) {
  try {
    const parsed = JSON.parse(buffer.toString('utf8'));
    const message = parsed?.error?.message || parsed?.message || '';

    if (/selected model|does not exist|do not have access/i.test(message)) {
      return Buffer.from(JSON.stringify({
        ...parsed,
        error: {
          ...(parsed.error || {}),
          message: `Model compatibility issue detected by VietCode. Requests are being mapped to ${config.model}. Use \`vietcode model\` to change the backend model.`
        }
      }));
    }
  } catch {
    return buffer;
  }

  return buffer;
}

export function startProxy(port = 7888) {
  const config = getEffectiveConfig();

  const server = http.createServer((req, res) => {
    if (isModelsRequest(req)) {
      const responseBody = JSON.stringify(buildModelsResponse());
      res.writeHead(200, {
        'content-type': 'application/json',
        'content-length': Buffer.byteLength(responseBody)
      });
      res.end(responseBody);
      return;
    }

    let body = [];
    req.on('data', (chunk) => body.push(chunk));
    req.on('end', () => {
      body = Buffer.concat(body);

      const targetUrl = new URL(config.base_url);
      const isHttps = targetUrl.protocol === 'https:';

      let payload;
      try {
        payload = JSON.parse(body.toString());
        payload = patchPayloadModel(payload, config);
      } catch (e) {
        payload = null;
      }

      const options = {
        hostname: targetUrl.hostname,
        port: targetUrl.port || (isHttps ? 443 : 80),
        path: req.url,
        method: req.method,
        headers: {
          ...req.headers,
          host: targetUrl.hostname,
          'x-api-key': config.api_key,
          'anthropic-version': req.headers['anthropic-version'] || '2023-06-01'
        }
      };

      delete options.headers['content-length'];
      delete options.headers['connection'];

      const connector = (isHttps ? https : http).request(options, (proxyRes) => {
        const chunks = [];
        proxyRes.on('data', (chunk) => chunks.push(chunk));
        proxyRes.on('end', () => {
          const responseBuffer = Buffer.concat(chunks);
          const patchedBuffer = sanitizeErrorBody(responseBuffer, config);
          const headers = { ...proxyRes.headers, 'content-length': Buffer.byteLength(patchedBuffer) };
          res.writeHead(proxyRes.statusCode, headers);
          res.end(patchedBuffer);
        });
      });

      connector.on('error', (err) => {
        console.error('Proxy error:', err);
        res.statusCode = 500;
        res.end('Proxy Error');
      });

      if (payload) {
        connector.write(JSON.stringify(payload));
      } else {
        connector.write(body);
      }
      connector.end();
    });
  });

  server.listen(port, () => {
    console.log(`VietCode Proxy running at http://localhost:${port}`);
  });

  return server;
}
