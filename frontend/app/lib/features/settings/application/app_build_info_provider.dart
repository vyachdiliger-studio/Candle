import "package:candle_frontend/core/config/app_config.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:package_info_plus/package_info_plus.dart";

import "../domain/app_build_info.dart";

/// Web metadata must travel with its JavaScript, not a separately cached file.
const bundledWebBuildInfo = AppBuildInfo(
  version: AppConfig.webBuildVersion,
  buildNumber: AppConfig.webBuildNumber,
  revision: AppConfig.buildCommit,
);

final appBuildInfoProvider = FutureProvider<AppBuildInfo>((ref) async {
  if (kIsWeb) return bundledWebBuildInfo;
  // main() already loads PackageInfo; the plugin reuses the cached result.
  final info = await PackageInfo.fromPlatform();
  return AppBuildInfo(
    version: info.version,
    buildNumber: info.buildNumber,
    revision: AppConfig.buildCommit,
  );
});
