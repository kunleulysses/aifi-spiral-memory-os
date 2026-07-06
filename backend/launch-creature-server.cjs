#!/usr/bin/env node

const http = require('http');
const { handler } = require('./creature-server.cjs');

const PORT = Number(process.env.AIFI_CREATURE_PORT || 8787);
const HOST = process.env.AIFI_CREATURE_HOST || '127.0.0.1';

const server = http.createServer(handler);

server.on('error', error => {
  console.error(JSON.stringify({
    event: 'aifi_creature_backend_error',
    message: error.message,
    code: error.code,
    port: PORT,
    host: HOST,
    at: new Date().toISOString()
  }));
  process.exitCode = 1;
});

server.listen(PORT, HOST, () => {
  console.log(JSON.stringify({
    event: 'aifi_creature_backend_listening',
    url: `http://${HOST}:${PORT}`,
    pid: process.pid,
    at: new Date().toISOString()
  }));
});
