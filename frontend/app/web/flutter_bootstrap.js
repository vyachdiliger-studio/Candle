{{flutter_js}}
{{flutter_build_config}}

// Only an explicit manual reload bypasses the cached application entrypoint.
(() => {
const reloadUrl = new URL(location.href);
const reloadId = reloadUrl.searchParams.get('_reload');
if (reloadId) {
  for (const build of _flutter.buildConfig.builds) {
    for (const field of ['mainJsPath', 'mainWasmPath', 'jsSupportRuntimePath']) {
      if (build[field]) {
        const url = new URL(build[field], document.baseURI);
        url.searchParams.set('_reload', reloadId);
        build[field] = url.href;
      }
    }
  }
  reloadUrl.searchParams.delete('_reload');
  history.replaceState(history.state, '', reloadUrl.href);
}
_flutter.loader.load();
})();
