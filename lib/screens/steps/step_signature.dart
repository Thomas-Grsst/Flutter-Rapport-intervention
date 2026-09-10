import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';

import '../../models/report.dart';
import '../../services/storage_service.dart';
import '../../theme.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/media_image.dart';
import '../../widgets/question_block.dart';

/// Étape 7 — évaluation du client et signatures.
///
/// Faire signer sur place évite la relance par e-mail : le rapport est
/// complet avant que l'intervenant ne quitte le chantier.
class SignatureStep extends StatefulWidget {
  const SignatureStep({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final Report draft;
  final VoidCallback onChanged;

  @override
  State<SignatureStep> createState() => _SignatureStepState();
}

class _SignatureStepState extends State<SignatureStep> {
  Report get _draft => widget.draft;

  Future<void> _sign({required bool isClient}) async {
    final storage = context.read<StorageService>();

    final bytes = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _SignaturePadPage(
          title: isClient ? 'Signature du client' : "Signature de l'intervenant",
          subtitle: isClient ? _draft.clientName : _draft.techniciansLine,
        ),
      ),
    );

    if (bytes == null || !mounted) return;

    final path = await storage.saveSignature(
      bytes,
      prefix: isClient ? 'signature_client' : 'signature_intervenant',
    );
    final previous =
        isClient ? _draft.clientSignaturePath : _draft.technicianSignaturePath;

    if (!mounted) return;
    setState(() {
      if (isClient) {
        _draft.clientSignaturePath = path;
      } else {
        _draft.technicianSignaturePath = path;
      }
    });
    widget.onChanged();
    await storage.deleteFileIfExists(previous);
  }

  Future<void> _clear({required bool isClient}) async {
    final storage = context.read<StorageService>();
    final previous =
        isClient ? _draft.clientSignaturePath : _draft.technicianSignaturePath;

    setState(() {
      if (isClient) {
        _draft.clientSignaturePath = null;
      } else {
        _draft.technicianSignaturePath = null;
      }
    });
    widget.onChanged();
    await storage.deleteFileIfExists(previous);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuestionBlock(
          question: 'Le client a-t-il un commentaire ?',
          hint: 'Son appréciation figurera dans la section « Évaluation du '
              'client ».',
          optional: true,
          child: AppTextField(
            initialValue: _draft.clientEvaluation,
            maxLines: 4,
            hint: 'Ex. : Client satisfait de la prestation.',
            onChanged: (value) {
              _draft.clientEvaluation = value;
              widget.onChanged();
            },
          ),
        ),
        QuestionBlock(
          question: 'Signatures',
          hint: 'Facultatives, mais elles rendent le rapport opposable.',
          optional: true,
          child: Column(
            children: [
              _signatureRow(
                label: "Signature de l'intervenant",
                path: _draft.technicianSignaturePath,
                isClient: false,
              ),
              const SizedBox(height: 16),
              _signatureRow(
                label: 'Signature du client',
                path: _draft.clientSignaturePath,
                isClient: true,
              ),
            ],
          ),
        ),
        _readyBanner(),
      ],
    );
  }

  Widget _signatureRow({
    required String label,
    required String? path,
    required bool isClient,
  }) {
    final hasSignature = path != null && path.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.brandDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 110,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD5DEE8)),
          ),
          child: hasSignature
              ? Padding(
                  padding: const EdgeInsets.all(8),
                  child: MediaImage(path: path, fit: BoxFit.contain),
                )
              : Center(
                  child: TextButton.icon(
                    onPressed: () => _sign(isClient: isClient),
                    icon: const Icon(Icons.draw_outlined),
                    label: const Text('Signer ici'),
                  ),
                ),
        ),
        if (hasSignature)
          Row(
            children: [
              TextButton(
                onPressed: () => _sign(isClient: isClient),
                child: const Text('Refaire'),
              ),
              TextButton(
                onPressed: () => _clear(isClient: isClient),
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                child: const Text('Effacer'),
              ),
            ],
          ),
      ],
    );
  }

  /// Rappel de ce qui manque avant de pouvoir générer un rapport propre.
  Widget _readyBanner() {
    final missing = _draft.missingSections;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: missing.isEmpty ? const Color(0xFFE4F3EC) : const Color(0xFFFDF1DC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                missing.isEmpty
                    ? Icons.check_circle_outline
                    : Icons.info_outline,
                size: 20,
                color: missing.isEmpty ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  missing.isEmpty
                      ? 'Le rapport est complet'
                      : 'Il reste ${missing.length} information(s) à compléter',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color:
                        missing.isEmpty ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            missing.isEmpty
                ? 'Appuyez sur « Terminer » pour l\'enregistrer, puis générez '
                    'le PDF depuis la fiche du rapport.'
                : '${missing.join(' • ')}.\nVous pouvez tout de même '
                    'enregistrer et compléter plus tard.',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}

/// Zone de signature plein écran.
class _SignaturePadPage extends StatefulWidget {
  const _SignaturePadPage({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  State<_SignaturePadPage> createState() => _SignaturePadPageState();
}

class _SignaturePadPageState extends State<_SignaturePadPage> {
  /// Fond transparent à l'export : la signature de l'intervenant se pose
  /// par-dessus le cachet de l'entreprise en fin de rapport, ce qu'un fond
  /// blanc opaque masquerait entièrement.
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _validate() async {
    if (_controller.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    final bytes = await _controller.toPngBytes();
    if (!mounted) return;
    Navigator.of(context).pop(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: () => _controller.clear(),
            child: const Text('Effacer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.subtitle.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.subtitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandDark,
                  ),
                ),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.brandLight, width: 1.4),
                ),
                clipBehavior: Clip.antiAlias,
                child: Signature(
                  controller: _controller,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ),
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _validate,
                child: const Text('Valider la signature'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
