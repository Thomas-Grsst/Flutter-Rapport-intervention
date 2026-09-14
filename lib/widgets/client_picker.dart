import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/client.dart';
import '../models/enums.dart';
import '../state/clients_provider.dart';
import '../theme.dart';

/// Ouvre le carnet d'adresses et renvoie le client choisi, ou null.
///
/// Les clients du contrat en cours viennent en tête : on ouvre le carnet
/// depuis un rapport d'entretien de poste de relevage pour y trouver un
/// client de poste de relevage, neuf fois sur dix.
Future<Client?> chooseClient(BuildContext context, ReportKind kind) {
  return showModalBottomSheet<Client>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _ClientPickerSheet(kind: kind),
  );
}

class _ClientPickerSheet extends StatefulWidget {
  const _ClientPickerSheet({required this.kind});

  final ReportKind kind;

  @override
  State<_ClientPickerSheet> createState() => _ClientPickerSheetState();
}

class _ClientPickerSheetState extends State<_ClientPickerSheet> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Retire un client du carnet, après confirmation.
  ///
  /// La confirmation nomme la fiche et son adresse : c'est le seul garde-fou,
  /// et il vaut mieux qu'il soit clair. Un bandeau « Annuler » se glisserait
  /// sous la feuille du carnet, restée ouverte, où personne ne le verrait.
  Future<void> _delete(Client client) async {
    final provider = context.read<ClientsProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Retirer du carnet ?'),
        content: Text(
          '${client.name}\n${client.oneLine}\n\n'
          'Les rapports déjà écrits pour ce client ne changent pas : ils '
          'gardent ses coordonnées telles quelles.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await provider.delete(client);
  }

  @override
  Widget build(BuildContext context) {
    final clients =
        context.watch<ClientsProvider>().forKind(widget.kind, query: _query);

    // La feuille occupe la majeure partie de l'écran : on cherche dans une
    // liste de plusieurs dizaines de clients, pas dans trois lignes.
    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Choisir un client',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandDark,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Fermer',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _search,
              autofocus: true,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Nom, commune, adresse…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.brandLight),
                ),
              ),
            ),
          ),
          Expanded(
            child: clients.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Aucun client ne correspond.\nVous pouvez le saisir '
                        'à la main et l\'ajouter au carnet.',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 14, color: Color(0xFF6B7785)),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: clients.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final client = clients[index];
                      return ListTile(
                        title: Text(
                          client.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          client.oneLine,
                          style: const TextStyle(fontSize: 13),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (client.contracts.contains(widget.kind))
                              const Icon(Icons.verified_outlined,
                                  size: 18, color: AppColors.brandLight),
                            IconButton(
                              tooltip: 'Retirer du carnet',
                              icon: const Icon(Icons.delete_outline, size: 20),
                              color: AppColors.danger,
                              onPressed: () => _delete(client),
                            ),
                          ],
                        ),
                        onTap: () => Navigator.of(context).pop(client),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
