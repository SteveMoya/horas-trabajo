import 'package:flutter_test/flutter_test.dart';
import 'package:horas_trabajo/services/update_service.dart';

void main() {
  group('compararVersiones', () {
    test('reconoce una versión más nueva', () {
      expect(compararVersiones('0.7.0', '0.6.2'), greaterThan(0));
      expect(compararVersiones('0.6.3', '0.6.2'), greaterThan(0));
      expect(compararVersiones('1.0.0', '0.9.9'), greaterThan(0));
    });

    test('reconoce una versión más vieja', () {
      expect(compararVersiones('0.6.1', '0.6.2'), lessThan(0));
      expect(compararVersiones('0.5.0', '0.6.0'), lessThan(0));
    });

    test('reconoce versiones iguales', () {
      expect(compararVersiones('0.6.2', '0.6.2'), 0);
      expect(compararVersiones('v0.6.2', '0.6.2'), 0);
    });

    test('ignora prefijo v y build de la instalada', () {
      // El build "+18" de la app instalada no debe superar a la versión de tag.
      expect(compararVersiones('v0.6.2', '0.6.2+18'), 0);
      expect(compararVersiones('v0.7.0', '0.6.2+999'), greaterThan(0));
    });
  });
}