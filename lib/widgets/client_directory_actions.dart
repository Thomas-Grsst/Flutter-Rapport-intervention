import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/client.dart';
import '../models/report.dart';
import '../state/clients_provider.dart';
import '../theme.dart';
import 'client_picker.dart';

/// Les deux gestes du carnet d'adresses, posés au-dessus des champs client :
/// en choisir un, ou garder celui qu'on vient de saisir.
///
/// Les clients sous contrat reviennent tous les ans. Les retaper à chaque
/// visite fait perdre du temps sur le chantier et finit par produire deux
/// orthographes du même nom dans deux rapports.
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

    draft.clientName = client.name;
    draft.clientAddressLine = client.addressLine;
    draft.clientPostalCode = client.postalCode;
    draft.clientCity = client.city;
    draft.clientPhone = client.phone;
    draft.clientEmail = client.email;
    onChanged();
  }

  Future<void> _remember(BuildContext context) async {
    final clients = context.read<ClientsProvider>();
    final messenger = ScaffoldMessenger.of(context);

    if (draft.clientName.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Renseignez d\'abord le nom du client.')),
      );
      return;
    }

    // Un client déjà connu est mis à jour plutôt que dupliqué : c'est ainsi
    // qu'un code postal ou un courriel corrigé sur le chantier profite aux
    // visites suivantes.
    final existing = clients.matching(
      name: draft.clientName,
      addressLine: draft.clientAddressLine,
    );

    final Client client;
    if (existing == null) {
      client = clients.draft(
        name: draft.clientName,
        addressLine: draft.clientAddressLine,
        postalCode: draft.clientPostalCode,
        city: draft.clientCity,
        phone: draft.clientPhone,
        email: draft.clientEmail,
        kind: draft.kind,
      );
    } else {
      client = existing.copyWith(
        addressLine: draft.clientAddressLine.trim(),
        postalCode: draft.clientPostalCode.trim(),
        city: draft.clientCity.trim(),
        phone: draft.clientPhone.trim(),
        email: draft.clientEmail.trim(),
        contracts: {...existing.contracts, draft.kind},
      );
    }

    await clients.save(client);
    messenger.showSnackBar(
      SnackBar(
        content: Text(existing == null
            ? '${client.name} ajouté au carnet'
            : '${client.name} mis à jour dans le carnet'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _pick(context),
              icon: const Icon(Icons.contacts_outlined, size: 20),
              label: const Text('Choisir un client'),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            tooltip: 'Ajouter ce client au carnet',
            onPressed: () => _remember(context),
            icon: const Icon(Icons.bookmark_add_outlined),
            color: AppColors.brandDark,
          ),
        ],
      ),
    );
  }
}
