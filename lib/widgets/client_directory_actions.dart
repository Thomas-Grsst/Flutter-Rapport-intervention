import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/client.dart';
import '../models/report.dart';
import '../state/clients_provider.dart';
import '../theme.dart';
import 'client_picker.dart';

/// Les gestes du carnet d'adresses, posés au-dessus des champs client : en
/// choisir un, puis garder les corrections apportées sur le chantier.
///
/// Les clients sous contrat reviennent tous les ans. Les retaper à chaque
/// visite fait perdre du temps et finit par produire deux orthographes du même
/// nom dans deux rapports.
class ClientDirectoryActions extends StatelessWidget {
  const ClientDirectoryActions({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  final Report draft;

  /// Appelé après avoir rempli les champs depuis le carnet, pour que l'étape
  /// se reconstruise et que le brouillon soit marqué à enregistrer.
  final VoidCallback onChanged;

  Future<void> _pick(BuildContext context) async {
    final client = await chooseClient(context, draft.kind);
    if (client == null) return;

    draft.clientId = client.id;
    draft.clientName = client.name;
    draft.clientAddressLine = client.addressLine;
    draft.clientPostalCode = client.postalCode;
    draft.clientCity = client.city;
    draft.clientPhone = client.phone;
    draft.clientEmail = client.email;
    onChanged();
  }

  /// La fiche du carnet que ce rapport corrige, s'il y en a une.
  ///
  /// Le lien est posé en choisissant un client, et retrouvé à défaut sur le
  /// nom et l'adresse — un rapport d'avant le carnet n'en a pas.
  Client? _linked(ClientsProvider clients) {
    return clients.byId(draft.clientId) ??
        clients.matching(
          name: draft.clientName,
          addressLine: draft.clientAddressLine,
        );
  }

  /// Le client tel qu'il ressort de ce qui est saisi dans le rapport.
  Client _edited(ClientsProvider clients, Client? existing) {
    if (existing == null) {
      return clients.draft(
        name: draft.clientName,
        addressLine: draft.clientAddressLine,
        postalCode: draft.clientPostalCode,
        city: draft.clientCity,
        phone: draft.clientPhone,
        email: draft.clientEmail,
        kind: draft.kind,
      );
    }
    return existing.copyWith(
      name: draft.clientName.trim(),
      addressLine: draft.clientAddressLine.trim(),
      postalCode: draft.clientPostalCode.trim(),
      city: draft.clientCity.trim(),
      phone: draft.clientPhone.trim(),
      email: draft.clientEmail.trim(),
      contracts: {...existing.contracts, draft.kind},
    );
  }

  Future<void> _remember(BuildContext context, Client? existing) async {
    final clients = context.read<ClientsProvider>();
    final messenger = ScaffoldMessenger.of(context);

    if (draft.clientName.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Renseignez d\'abord le nom du client.')),
      );
      return;
    }

    // Mettre à jour une fiche en change le nom partout : on montre d'abord
    // laquelle, parce qu'après avoir repris un client puis tout retapé, ce
    // n'est pas forcément celle qu'on croit.
    if (existing != null) {
      final choix = await _confirmUpdate(context, existing);
      if (choix == null) return;
      if (choix == _Choice.nouveau) {
        final ajoute = await clients.save(_edited(clients, null));
        draft.clientId = ajoute.id;
        onChanged();
        messenger.showSnackBar(
          SnackBar(content: Text('${ajoute.name} ajouté au carnet')),
        );
        return;
      }
    }

    final client = _edited(clients, existing);
    await clients.save(client);
    draft.clientId = client.id;
    onChanged();

    messenger.showSnackBar(
      SnackBar(
        content: Text(existing == null
            ? '${client.name} ajouté au carnet'
            : 'Fiche de ${client.name} mise à jour'),
      ),
    );
  }

  Future<_Choice?> _confirmUpdate(BuildContext context, Client existing) {
    return showDialog<_Choice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mettre à jour le carnet ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fiche actuelle', style: _labelStyle),
            Text('${existing.name}\n${existing.oneLine}'),
            const SizedBox(height: 12),
            const Text('Après correction', style: _labelStyle),
            Text('${draft.clientName.trim()}\n'
                '${[
              draft.clientAddressLine.trim(),
              [draft.clientPostalCode.trim(), draft.clientCity.trim()]
                  .where((part) => part.isNotEmpty)
                  .join(' '),
            ].where((part) => part.isNotEmpty).join(', ')}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(_Choice.nouveau),
            child: const Text('Nouveau client'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(_Choice.mettreAJour),
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clients = context.watch<ClientsProvider>();
    final existing = _linked(clients);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _pick(context),
              icon: const Icon(Icons.contacts_outlined, size: 20),
              label: const Text('Choisir un client'),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _remember(context, existing),
              icon: Icon(
                existing == null
                    ? Icons.bookmark_add_outlined
                    : Icons.edit_note_outlined,
                size: 20,
              ),
              label: Text(
                existing == null
                    ? 'Ajouter au carnet'
                    : 'Mettre à jour la fiche client',
                style: const TextStyle(fontSize: 13.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ce que l'utilisateur décide face à une fiche déjà connue.
enum _Choice { mettreAJour, nouveau }

const TextStyle _labelStyle = TextStyle(
  fontSize: 12.5,
  fontWeight: FontWeight.w700,
  color: AppColors.brandLight,
);
