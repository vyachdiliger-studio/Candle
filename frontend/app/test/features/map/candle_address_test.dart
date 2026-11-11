import "package:candle_frontend/l10n/generated/app_localizations.dart";
import "dart:convert";
import "dart:typed_data";

import "package:candle_frontend/core/models/location.dart";
import "package:candle_frontend/features/candle/data/dio_candle_repository.dart";
import "package:candle_frontend/features/candle/data/models/candle_dto.dart";
import "package:candle_frontend/features/geocoding/data/photon_geocoding_repository.dart";
import "package:candle_frontend/features/geocoding/domain/models/address_suggestion.dart";
import "package:candle_frontend/features/geocoding/domain/remote_geocoding_repository.dart";
import "package:candle_frontend/features/map/application/address_field_controller.dart";
import "package:candle_frontend/features/map/presentation/widgets/candle_location_row.dart";
import "package:dartz/dartz.dart";
import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";

class Geocoder implements RemoteGeocodingRepository {
  @override
  Future<Either<Unit, String?>> reverse(Location location) async => right("Street 1, Town");

  @override
  Future<Either<Unit, List<AddressSuggestion>>> search({required String query, Location? near}) =>
      throw UnimplementedError();
}

class Capture implements HttpClientAdapter {
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode({
        "id": 1,
        "createdAt": "2026-09-01T00:00:00Z",
        "ignitedAt": "2026-09-01T00:00:00Z",
        "extinguishedAt": "2026-09-01T00:10:00Z",
        "location": {"latitude": 50.08, "longitude": 14.42},
        "address": "Street 1, Town",
      }),
      200,
      headers: {
        "content-type": ["application/json"],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const place = Location(latitude: 50.08804, longitude: 14.42076);

void main() {
  group("address field", () {
    late ProviderContainer container;
    late AddressFieldController field;
    AddressFieldController read() => container.read(addressFieldControllerProvider.notifier);
    String? label() => container.read(addressFieldControllerProvider).label;

    setUp(() {
      container = ProviderContainer(
        overrides: [geocodingRepositoryProvider.overrideWithValue(Geocoder())],
      );
      container.listen(addressFieldControllerProvider, (_, _) {});
      field = read();
    });
    tearDown(() => container.dispose());

    test("an address the candle already has counts as matching its pin", () {
      field.startWith("Known 5");
      expect(label(), "Known 5");
      expect(container.read(addressFieldControllerProvider).isSynced, isTrue);
    });

    test("starting without an address leaves the field empty", () {
      field.startWith(null);
      expect(label(), isNull);
      expect(container.read(addressFieldControllerProvider).isSynced, isFalse);
    });

    test("a picked suggestion or a restored address becomes the label", () async {
      field.suggestionPicked("Picked 1");
      expect(label(), "Picked 1");
      field.markStale();
      expect(await field.restoreFromCoordinates(place), "Street 1, Town");
      expect(label(), "Street 1, Town");
    });

    test("moving the pin, typing or clearing drops the label", () {
      field.suggestionPicked("Picked 1");
      field.markStale();
      expect(label(), isNull);

      field.suggestionPicked("Picked 1");
      field.textChanged("Pick", near: place);
      expect(label(), isNull);

      field.suggestionPicked("Picked 1");
      field.clear();
      expect(label(), isNull);
    });
  });

  group("candle location row", () {
    Future<void> pump(WidgetTester tester, {Location? location = place, String? address}) =>
        tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,

              home: Scaffold(
                body: CandleLocationRow(location: location, address: address),
              ),
            ),
          ),
        );

    testWidgets("shows the address in place of the coordinates", (tester) async {
      await pump(tester, address: "Old Town Square 1, Prague");
      expect(find.text("Old Town Square 1, Prague"), findsOneWidget);
      expect(find.text("50.08804, 14.42076"), findsNothing);
    });

    testWidgets("falls back to coordinates without an address", (tester) async {
      await pump(tester);
      expect(find.text("50.08804, 14.42076"), findsOneWidget);
    });

    testWidgets("says so when the candle is not on the map", (tester) async {
      await pump(tester, location: null);
      expect(find.text("Not placed on the map"), findsOneWidget);
    });
  });

  group("candle address over the wire", () {
    test("is read from the response", () {
      final dto = CandleDto.fromJson({
        "id": 1,
        "createdAt": "2026-09-01T00:00:00Z",
        "ignitedAt": "2026-09-01T00:00:00Z",
        "extinguishedAt": "2026-09-01T00:10:00Z",
        "location": {"latitude": 1.0, "longitude": 2.0},
        "address": "Street 1, Town",
      });
      expect(dto.toDomain().address, "Street 1, Town");
    });

    test("is optional, so candles without one still load", () {
      final dto = CandleDto.fromJson({
        "id": 1,
        "createdAt": "2026-09-01T00:00:00Z",
        "ignitedAt": "2026-09-01T00:00:00Z",
        "extinguishedAt": "2026-09-01T00:10:00Z",
        "location": null,
      });
      expect(dto.toDomain().address, isNull);
    });

    test("placing a candle sends the address, or an explicit null", () async {
      final adapter = Capture();
      final repository = DioCandleRepository(Dio()..httpClientAdapter = adapter);

      final saved = await repository.updateLocation(id: 1, location: place, address: "Street 1");
      expect(adapter.request!.data["address"], "Street 1");
      expect(saved.fold((_) => null, (c) => c.address), "Street 1, Town");

      await repository.updateLocation(id: 1, location: place);
      expect(adapter.request!.data.containsKey("address"), isTrue);
      expect(adapter.request!.data["address"], isNull);
    });
  });
}
