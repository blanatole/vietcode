import http from 'node:http';
import https from 'node:https';
import { getEffectiveConfig } from './config.js';

export function startProxy(port = 7888) {
  const config = getEffectiveConfig();
  
  const server = http.createServer((req, res) => {
    let body = [];
    req.on('data', (chunk) => body.push(chunk));
    req.on('end', () => {
      body = Buffer.concat(body);
      
      const targetUrl = new URL(config.base_url);
      const isHttps = targetUrl.protocol === 'https:';
      
      let payload;
      try {
        payload = JSON.parse(body.toString());
        // Patch system prompt
        if (payload.system) {
          // Remove hardcoded Claude references
          payload.system = config.identity;
        }
        // Force model if configured
        if (config.model) {
          payload.model = config.model;
        }
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

      // Remove headers that might conflict
      delete options.headers['content-length'];
      delete options.headers['connection'];

      const connector = (isHttps ? https : http).request(options, (proxyRes) => {
        res.writeHead(proxyRes.statusCode, proxyRes.headers);
        proxyRes.pipe(res);
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
