import "../domain/media_resource.dart";

class MediaResourceDto {
  const MediaResourceDto(this.json);

  final Map<String, dynamic> json;

  MediaResource toDomain() => MediaResource(
    id: json["id"] as String,
    url: json["url"] as String,
    thumbnailUrl: json["thumbnailUrl"] as String,
    width: (json["width"] as num).toInt(),
    height: (json["height"] as num).toInt(),
  );

  static Map<String, dynamic> fromDomain(MediaResource resource) => {
    "id": resource.id,
    "url": resource.url,
    "thumbnailUrl": resource.thumbnailUrl,
    "width": resource.width,
    "height": resource.height,
  };
}
