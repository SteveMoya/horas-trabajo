import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Obtiene la ubicación del dispositivo para registrar el lugar de entrada.
class GeoService {
  /// Devuelve [lat, lng] o null si el usuario deniega / no hay señal / falla.
  Future<List<double>?> ubicacionActual() async {
    try {
      final permiso = await ph.Permission.location.request();
      if (!permiso.isGranted) return null;

      if (!await Geolocator.isLocationServiceEnabled()) return null;
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 8),
      );
      return [pos.latitude, pos.longitude];
    } catch (_) {
      return null;
    }
  }
}