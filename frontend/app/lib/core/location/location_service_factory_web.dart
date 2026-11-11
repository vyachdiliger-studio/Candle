import "../platform/telegram_mini_app.dart";
import "geolocator_service.dart";
import "location_service.dart";
import "telegram_location_service.dart";

LocationService createLocationService() =>
    isTelegramMiniApp ? TelegramLocationService() : GeolocatorService();
