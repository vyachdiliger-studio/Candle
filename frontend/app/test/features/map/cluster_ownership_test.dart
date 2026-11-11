import "package:candle_frontend/features/candle/data/models/cluster_dto.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  final json = <String, dynamic>{
    "count": 3,
    "location": {"latitude": 50.0, "longitude": 14.0},
    "candleId": 17,
  };

  test("cluster ownership survives JSON decoding and domain mapping", () {
    for (final own in [false, true]) {
      final dto = ClusterDto.fromJson({...json, "hasOwnCandle": own});
      expect(dto.toDomain().hasOwnCandle, own);
      expect(dto.toJson()["hasOwnCandle"], own);
      expect(dto.toDomain().count, 3);
    }
  });

  test("responses without ownership remain compatible", () {
    expect(ClusterDto.fromJson(json).toDomain().hasOwnCandle, isFalse);
    expect(ClusterDto.fromJson({...json, "hasOwnCandle": null}).toDomain().hasOwnCandle, isFalse);
  });
}
