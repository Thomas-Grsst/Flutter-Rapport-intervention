import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/app_settings.dart';
import '../models/enums.dart';
import '../models/photo_group.dart';
import '../models/photo_item.dart';
import '../models/report.dart';
import '../services/storage_service.dart';

/// Filtres proposés en haut de la liste des rapports.
enum ReportFilter {
  tous('Tous'),
  enCours('En cours'),
  aSuivre('À suivre'),
  termines('Terminés');

  const ReportFilter(this.label);

  final String label;

  bool matches(Report report) {
    switch (this) {
      case ReportFilter.tous:
        return true;
      case ReportFilter.enCours:
        return report.status == ReportStatus.brouillon ||
            report.status == ReportStatus.enCours;
      case ReportFilter.aSuivre:
        return report.status == ReportStatus.aSuivre;
      case ReportFilter.termines:
        return report.status == ReportStatus.termine;
    }
  }
}

/// Détient la liste des rapports et la persiste dans reports.json.
class ReportsProvider extends ChangeNotifier {
  ReportsProvider(this._storage);

  static const String _fileName = 'reports.json';
  static const Uuid _uuid = Uuid();
  static final DateFormat _numberDateFormat = DateFormat('ddMMyy');

  final StorageService _storage;

  final List<Report> _reports = <Report>[];
  bool _loaded = false;
  String _query = '';
  ReportFilter _filter = ReportFilter.tous;

  bool get isLoaded => _loaded;
  String get query => _query;
  ReportFilter get filter => _filter;

  /// Tous les rapports, du plus récemment modifié au plus ancien.
  List<Report> get all => List.unmodifiable(_reports);

  /// Les rapports correspondant à la recherche et au filtre en cours.
  List<Report> get visible {
    final normalized = _normalize(_query);
    return _reports.where((report) {
      if (!_filter.matches(report)) return false;
      if (normalized.isEmpty) return true;
      final haystack = _normalize([
        report.clientName,
        report.interventionType,
        report.siteOneLine,
        report.siteLocation,
        report.reportNumber,
        report.techniciansLine,
      ].join(' '));
      return haystack.contains(normalized);
    }).toList();
  }

  int countFor(ReportFilter filter) =>
      _reports.where(filter.matches).length;

  Future<void> load() async {
    final json = await _storage.readJson(_fileName);
    _reports.clear();
    if (json != null) {
      final items = json['reports'] as List<dynamic>? ?? const <dynamic>[];
      _reports.addAll(
        items.map((item) => Report.fromJson(item as Map<String, dynamic>)),
      );
      _sort();
    }
    _loaded = true;
    notifyListeners();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setFilter(ReportFilter value) {
    _filter = value;
    notifyListeners();
  }

  Report? byId(String id) {
    for (final report in _reports) {
      if (report.id == id) return report;
    }
    return null;
  }

  /// Crée un brouillon pré-rempli avec les informations de l'entreprise et
  /// l'intervenant enregistré, pour que l'utilisateur démarre avec le moins
  /// de champs vides possible.
  Report createDraft(AppSettings settings) {
    final now = DateTime.now();
    final technician =
        settings.technicians.isNotEmpty ? settings.technicians.first : null;

    return Report(
      id: _uuid.v4(),
      createdAt: now,
      updatedAt: now,
      interventionDate: now,
      technicians: [if (technician != null) technician],
      documentsToTransmit: "Rapport d'intervention",
      status: ReportStatus.brouillon,
    );
  }

  /// Enregistre un rapport (création ou mise à jour).
  Future<void> save(Report report) async {
    report.updatedAt = DateTime.now();
    final index = _reports.indexWhere((item) => item.id == report.id);
    if (index >= 0) {
      _reports[index] = report;
    } else {
      _reports.add(report);
    }
    _sort();
    notifyListeners();
    await _persist();
  }

  /// Supprime un rapport ainsi que les photos et signatures qui lui sont
  /// propres, pour ne pas saturer le téléphone.
  Future<void> delete(Report report) async {
    _reports.removeWhere((item) => item.id == report.id);
    notifyListeners();
    await _persist();

    for (final photo in report.photos) {
      await _storage.deleteFileIfExists(photo.filePath);
    }
    await _storage.deleteFileIfExists(report.clientSignaturePath);
    await _storage.deleteFileIfExists(report.technicianSignaturePath);
  }

  /// Duplique un rapport : pratique pour un chantier récurrent chez le même
  /// client. Les photos et signatures ne sont pas reprises.
  Report duplicate(Report source) {
    final now = DateTime.now();
    final copy = source.clone();
    final duplicated = Report.fromJson({
      ...copy.toJson(),
      'id': _uuid.v4(),
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'interventionDate': now.toIso8601String(),
      'photoGroups': <dynamic>[],
      'status': ReportStatus.brouillon.name,
      'reportNumber': '',
      'clientSignaturePath': null,
      'technicianSignaturePath': null,
      'lastPdfPath': null,
    });
    return duplicated;
  }

  /// Ajoute une photo déjà importée dans le dossier de l'application.
  PhotoItem buildPhoto(String filePath, PhotoStage stage) =>
      PhotoItem(id: _uuid.v4(), filePath: filePath, stage: stage);

  /// Un nouveau lot de photos, vide, pour un point de l'intervention.
  PhotoGroup buildPhotoGroup() => PhotoGroup(id: _uuid.v4());

  /// Numéro de rapport type "ASE-120326-MB" : préfixe entreprise, date
  /// d'intervention, initiales du client. Un suffixe est ajouté si ce numéro
  /// est déjà utilisé par un autre rapport.
  String generateReportNumber(Report report, AppSettings settings) {
    final prefix = settings.reportNumberPrefix.trim().isEmpty
        ? 'RAP'
        : settings.reportNumberPrefix.trim().toUpperCase();
    final date = _numberDateFormat.format(report.interventionDate);
    final initials = _initials(report.clientName);

    final base = [prefix, date, if (initials.isNotEmpty) initials].join('-');
    var candidate = base;
    var suffix = 1;
    while (_reports.any(
      (item) => item.id != report.id && item.reportNumber == candidate,
    )) {
      suffix++;
      candidate = '$base-$suffix';
    }
    return candidate;
  }

  /// Civilités et formes juridiques ignorées dans les initiales : « M. Manuel
  /// BLANC » doit donner MB, pas MM.
  static const Set<String> _ignoredWords = {
    'm', 'm.', 'mme', 'mlle', 'monsieur', 'madame',
    'sarl', 'sas', 'sasu', 'sci', 'eurl', 'sa',
  };

  static String _initials(String name) {
    final words = name
        .split(RegExp(r'[\s\-]+'))
        .map((word) => word.trim())
        .where((word) =>
            word.isNotEmpty && !_ignoredWords.contains(word.toLowerCase()))
        .toList();
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }

  void _sort() {
    _reports.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> _persist() async {
    await _storage.writeJson(_fileName, {
      'version': 1,
      'reports': _reports.map((report) => report.toJson()).toList(),
    });
  }

  /// Recherche insensible à la casse et aux accents : « MONTANAY » doit
  /// répondre à « montanay », et « Trévoux » à « trevoux ».
  static String _normalize(String value) {
    const accents = 'àâäáãçéèêëíìîïñóòôöõúùûüýÿœæ';
    const plain = 'aaaaaceeeeiiiinooooouuuuyyoa';
    final lower = value.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      final index = accents.indexOf(char);
      buffer.write(index >= 0 ? plain[index] : char);
    }
    return buffer.toString().trim();
  }
}
