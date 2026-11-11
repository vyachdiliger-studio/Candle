const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

async function check(online) {
  const fetched = [], removed = [];
  let destination, unregistered = false;
  const context = {
    URL, Date, Set, Promise, AbortSignal,
    document: {baseURI: 'https://app.test/'},
    location: {href: 'https://app.test/candles/42?from=map#tgWebAppData=test',
      replace: url => destination = url},
    navigator: {serviceWorker: {getRegistrations: async () => [
      {scope: 'https://app.test/', active: {scriptURL: 'https://app.test/flutter_service_worker.js?v=old'},
        unregister: async () => unregistered = true},
      {scope: 'https://app.test/other/', active: {scriptURL: 'https://app.test/other/sw.js'},
        unregister: async () => { throw Error('unrelated worker'); }},
    ]}},
    caches: {delete: async name => removed.push(name)},
    performance: {getEntriesByType: () => [
      {name: 'https://app.test/assets/candle.riv'},
      {name: 'https://app.test/api/users/me'},
      {name: 'https://backend.test/users/me'},
    ]},
    fetch: async (url, options) => {
      fetched.push({url, options});
      return {ok: online, arrayBuffer: async () => new ArrayBuffer(0)};
    },
  };
  context.window = context;
  vm.runInNewContext(fs.readFileSync('web/manual_reload.js', 'utf8'), context);
  if (!online) {
    await assert.rejects(context.candleReloadApp());
    assert.equal(destination, undefined);
    assert.equal(unregistered, false);
    assert.deepEqual(removed, []);
  } else {
    await context.candleReloadApp();
    const url = new URL(destination);
    assert.equal(url.pathname, '/candles/42');
    assert.equal(url.searchParams.get('from'), 'map');
    assert.equal(url.hash, '#tgWebAppData=test');
    assert.ok(url.searchParams.get('_reload'));
    assert.equal(unregistered, true);
    assert.equal(removed.length, 3);
    assert.equal(fetched.some(r => r.url.includes('/users/me')), false);
    assert.ok(fetched.some(r => r.url.endsWith('/assets/candle.riv') && r.options.cache === 'reload'));
  }
}
(async () => {
  await check(true);
  await check(false);
  const code = fs.readFileSync('web/flutter_bootstrap.js', 'utf8')
    .replace('{{flutter_js}}', '').replace('{{flutter_build_config}}', '');
  const config = {builds: [{mainJsPath: 'main.dart.js'}]};
  let cleaned, loaded = false;
  vm.runInNewContext(code, {
    URL, location: {href: 'https://app.test/?_reload=123#tgWebAppData=test'},
    document: {baseURI: 'https://app.test/'},
    history: {state: null, replaceState: (_, __, url) => cleaned = url},
    _flutter: {buildConfig: config, loader: {load: () => loaded = true}},
  });
  assert.equal(config.builds[0].mainJsPath, 'https://app.test/main.dart.js?_reload=123');
  assert.equal(cleaned, 'https://app.test/#tgWebAppData=test');
  assert.equal(loaded, true);
  // Classic scripts share a global lexical scope in the browser. Running each
  // in an isolated VM misses duplicate top-level const declarations.
  const html = fs.readFileSync('web/index.html', 'utf8');
  const inline = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)].map(match => match[1]);
  for (const suffix of ['', '?_reload=123']) {
    let bootstrapped = false;
    const page = vm.createContext({
      URL, location: {href: 'https://app.test/' + suffix},
      document: {baseURI: 'https://app.test/', createElement: () => ({}), body: {appendChild: () => {}}},
      history: {state: null, replaceState: () => {}},
      _flutter: {buildConfig: {builds: [{mainJsPath: 'main.dart.js'}]},
        loader: {load: () => bootstrapped = true}},
    });
    inline.forEach(script => vm.runInContext(script, page));
    vm.runInContext(code, page);
    assert.equal(bootstrapped, true);
  }
  console.log('PASS: manual reload preserves URL, skips APIs, scopes cleanup, handles offline, refreshes entrypoint');
})().catch(error => { console.error(error); process.exitCode = 1; });
