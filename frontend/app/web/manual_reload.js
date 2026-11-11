// Developer convenience, not an automatic updater. Do not touch login storage.
window.candleReloadApp = async function () {
  const base = new URL(document.baseURI);
  const target = new URL(location.href);
  target.searchParams.set('_reload', Date.now().toString());
  // Check connectivity before changing anything. The unique URL also bypasses
  // old Flutter workers which may still control this document until navigation.
  const check = await fetch(target.href, {cache: 'no-store', signal: AbortSignal.timeout(15000)});
  if (!check.ok) throw new Error('App unavailable');

  if ('serviceWorker' in navigator) {
    const registrations = await navigator.serviceWorker.getRegistrations();
    for (const registration of registrations) {
      const worker = registration.active || registration.waiting || registration.installing;
      if (registration.scope === base.href && worker &&
          new URL(worker.scriptURL).pathname === new URL('flutter_service_worker.js', base).pathname) {
        await registration.unregister();
      }
    }
  }
  if ('caches' in window) {
    for (const name of ['flutter-app-cache', 'flutter-temp-cache', 'flutter-app-manifest']) {
      await caches.delete(name);
    }
  }
  // Refresh already used local static resources in the HTTP cache. Never replay
  // API calls, even if the API is later hosted on the same origin.
  const urls = new Set(['flutter_bootstrap.js', 'main.dart.js', 'manual_reload.js']
    .map(path => new URL(path, base).href));
  for (const entry of performance.getEntriesByType('resource')) {
    const url = new URL(entry.name);
    if (url.origin === base.origin &&
        (url.pathname.startsWith(base.pathname + 'assets/') ||
         url.pathname.startsWith(base.pathname + 'canvaskit/'))) urls.add(url.href);
  }
  await Promise.all([...urls].map(async url => {
    const response = await fetch(url, {cache: 'reload', signal: AbortSignal.timeout(20000)});
    if (!response.ok) throw new Error('Resource unavailable');
    await response.arrayBuffer();
  }));
  location.replace(target.href);
};
