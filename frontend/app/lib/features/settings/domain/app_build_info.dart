/// Identifies the installed artifact, never the latest release on a server.
class AppBuildInfo {
  const AppBuildInfo({required this.version, required this.buildNumber, this.revision = ""});

  final String version;
  final String buildNumber;
  final String revision;

  String? get shortRevision {
    final value = revision.trim();
    if (value.isEmpty) return null;
    return value.length > 7 ? value.substring(0, 7) : value;
  }
}
