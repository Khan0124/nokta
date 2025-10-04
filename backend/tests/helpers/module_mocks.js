const Module = require('module');
const path = require('node:path');

const BASE_RESOLVE = Module._resolveFilename;

function createModuleMocks(testDir) {
  const trackedModules = new Set();
  const externalOverrides = new Map();

  const resolveFromTests = (modulePath) =>
    require.resolve(modulePath, { paths: [testDir] });

  const mockModule = (modulePath, exports) => {
    const resolved = resolveFromTests(modulePath);
    require.cache[resolved] = {
      id: resolved,
      filename: resolved,
      loaded: true,
      exports,
    };
    trackedModules.add(resolved);
    return resolved;
  };

  const ensureExternalHook = () => {
    if (Module._resolveFilename === BASE_RESOLVE) {
      Module._resolveFilename = function patchedResolve(request, parent, isMain, options) {
        if (externalOverrides.has(request)) {
          return externalOverrides.get(request);
        }
        return BASE_RESOLVE.call(this, request, parent, isMain, options);
      };
    }
  };

  const mockExternalModule = (moduleName, exports) => {
    const virtualPath = path.join(testDir, '__virtual__', `${moduleName}.js`);
    require.cache[virtualPath] = {
      id: virtualPath,
      filename: virtualPath,
      loaded: true,
      exports,
    };
    externalOverrides.set(moduleName, virtualPath);
    ensureExternalHook();
    return virtualPath;
  };

  const requireFresh = (modulePath) => {
    const resolved = resolveFromTests(modulePath);
    delete require.cache[resolved];
    trackedModules.add(resolved);
    return require(resolved);
  };

  const clearAll = () => {
    for (const resolved of trackedModules) {
      delete require.cache[resolved];
    }
    trackedModules.clear();

    if (Module._resolveFilename !== BASE_RESOLVE) {
      Module._resolveFilename = BASE_RESOLVE;
    }

    for (const virtualPath of externalOverrides.values()) {
      delete require.cache[virtualPath];
    }
    externalOverrides.clear();
  };

  return {
    mockModule,
    mockExternalModule,
    requireFresh,
    clearAll,
  };
}

module.exports = { createModuleMocks };
