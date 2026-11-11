class MediaResource {
  const MediaResource({
    required this.id,
    required this.url,
    required this.thumbnailUrl,
    required this.width,
    required this.height,
  });

  final String id;
  final String url;
  final String thumbnailUrl;
  final int width;
  final int height;
}
