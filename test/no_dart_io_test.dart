import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Seul le stockage sur fichiers a le droit de toucher à `dart:io`.
///
/// Partout ailleurs, `dart:io` compile sans broncher mais explose à
/// l'exécution dans un navigateur — `Unsupported operation: _Namespace` —,
/// et seule l'ouverture de l'écran fautif le révèle. Ce test remplace cette
/// découverte tardive.
const Set<String> _autorises = {'lib/services/storage_service_io.dart'};

void main() {
  test('seul le stockage mobile importe dart:io', () {
    final fautifs = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      final chemin = p.split(entity.path).join('/');
      if (_autorises.contains(chemin)) continue;

      if (entity.readAsStringSync().contains("import 'dart:io'")) {
        fautifs.add(chemin);
      }
    }

    expect(
      fautifs,
      isEmpty,
      reason: "Ces fichiers planteront dans un navigateur. Passez par "
          'StorageService, ou par le widget MediaImage pour afficher une '
          'photo, un logo ou une signature.',
    );
  });
}
