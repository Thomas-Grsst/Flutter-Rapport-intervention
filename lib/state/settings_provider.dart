import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../models/company.dart';
import '../services/storage_service.dart';

/// Détient les réglages de l'application (fiche entreprise, intervenants,
/// listes de choix rapides) et les persiste dans settings.json.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._storage);

  static const String _fileName = 'settings.json';

  final StorageService _storage;

  AppSettings _settings = AppSettings.defaults;
  bool _loaded = false;

  AppSettings get settings => _settings;
  Company get company => _settings.company;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final json = await _storage.readJson(_fileName);
    if (json != null) {
      _settings = AppSettings.fromJson(json);
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> update(AppSettings settings) async {
    _settings = settings;
    notifyListeners();
    await _storage.writeJson(_fileName, settings.toJson());
  }

  Future<void> updateCompany(Company company) =>
      update(_settings.copyWith(company: company));

  /// Remplace le logo de l'entreprise par le fichier choisi, en supprimant
  /// l'ancien pour ne pas laisser de fichiers orphelins.
  Future<void> setLogo(String sourcePath) async {
    final imported = await _storage.importMedia(sourcePath, prefix: 'logo');
    final previous = _settings.company.logoPath;
    await updateCompany(_settings.company.copyWith(logoPath: imported));
    if (previous != imported) {
      await _storage.deleteFileIfExists(previous);
    }
  }

  Future<void> removeLogo() async {
    final previous = _settings.company.logoPath;
    await updateCompany(_settings.company.copyWith(clearLogo: true));
    await _storage.deleteFileIfExists(previous);
  }

  /// Ajoute une valeur à une liste de choix rapides si elle n'y est pas déjà.
  /// Utilisé quand l'intervenant saisit un matériel ou une action « Autre » :
  /// la valeur devient disponible pour les rapports suivants.
  Future<void> rememberPreset(PresetList list, String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    final current = _presetsOf(list);
    if (current.any((item) => item.toLowerCase() == trimmed.toLowerCase())) {
      return;
    }
    await update(_withPresets(list, [...current, trimmed]));
  }

  Future<void> replacePresets(PresetList list, List<String> values) =>
      update(_withPresets(list, values));

  List<String> presetsOf(PresetList list) => _presetsOf(list);

  List<String> _presetsOf(PresetList list) {
    switch (list) {
      case PresetList.interventionTypes:
        return _settings.interventionTypes;
      case PresetList.materials:
        return _settings.materialPresets;
      case PresetList.findings:
        return _settings.findingPresets;
      case PresetList.actions:
        return _settings.actionPresets;
    }
  }

  AppSettings _withPresets(PresetList list, List<String> values) {
    switch (list) {
      case PresetList.interventionTypes:
        return _settings.copyWith(interventionTypes: values);
      case PresetList.materials:
        return _settings.copyWith(materialPresets: values);
      case PresetList.findings:
        return _settings.copyWith(findingPresets: values);
      case PresetList.actions:
        return _settings.copyWith(actionPresets: values);
    }
  }
}

/// Les quatre listes de choix rapides configurables dans les réglages.
enum PresetList {
  interventionTypes("Types d'intervention"),
  materials('Matériel'),
  findings('Constats'),
  actions('Actions');

  const PresetList(this.label);

  final String label;
}
