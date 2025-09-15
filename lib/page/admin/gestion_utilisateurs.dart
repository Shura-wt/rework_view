part of '../../main.dart';

class GestionUtilisateursPage extends StatefulWidget {
  const GestionUtilisateursPage({super.key});

  @override
  State<GestionUtilisateursPage> createState() => _GestionUtilisateursPageState();
}

class _GestionUtilisateursPageState extends State<GestionUtilisateursPage> {
  bool _loading = true;
  List<User> _users = const [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final api = UsersApi(SessionManager.instance.client);
      final users = await api.list();
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } on Object catch (e) {
      ApiErrorHandler.logDebug(e, context: 'users.list');
      if (mounted) {
        ApiErrorHandler.showSnackBar(context, e, action: 'Chargement des utilisateurs');
        setState(() => _loading = false);
      }
    }
  }

  void _createUtilisateur() async {
    // Placeholder pour la création d'utilisateur (à brancher plus tard).
    // On rafraîchit la liste après la création si besoin.
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ajouter un utilisateur'),
        content: const Text('Formulaire de création non implémenté dans cette version.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }

  void _editUtilisateur(User user) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Modifier un utilisateur'),
        content: Text('Edition de ${user.login} non implémentée dans cette version.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }

  Future<void> _deleteUtilisateur(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text("Voulez-vous vraiment supprimer l'utilisateur '${user.login}' ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final api = UsersApi(SessionManager.instance.client);
      await api.deleteUser(user.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur supprimé')),
      );
      await _loadUsers();
    } on Object catch (e) {
      ApiErrorHandler.logDebug(e, context: 'users.delete');
      if (mounted) {
        ApiErrorHandler.showSnackBar(context, e, action: 'Suppression utilisateur');
      }
    }
  }

  Color _roleColor(String role, ThemeData theme) {
    final r = role.toLowerCase().trim();
    switch (r) {
      case 'super admin':
      case 'super_admin':
      case 'superadmin':
      case 'super-admin':
        return Colors.purple; // violet
      case 'admin':
        return Colors.red;
      case 'technicien':
      case 'technician':
        return Colors.lightBlue; // bleu clair
      case 'user':
      case 'utilisateur':
      case 'viewer':
      case 'lecteur':
        return Colors.green;
      default:
        // Fallback deterministic color from role hash
        final hash = r.hashCode;
        final hue = (hash % 360).toDouble();
        // HSV to Color with moderate saturation/value
        return HSVColor.fromAHSV(1.0, hue, 0.45, 0.85).toColor();
    }
  }

  DataTable _buildDataTable() {
    return DataTable(
      columns: const [
        DataColumn(label: Text("Nom d'utilisateur")),
        DataColumn(label: Text('Rôles')),
        DataColumn(label: Text('Sites')),
        DataColumn(label: Text('Actions')),
      ],
      rows: _users.map((u) {
        final theme = Theme.of(context);
        final rolesChips = Wrap(
          spacing: 8,
          runSpacing: 4,
          children: u.roles
              .map((r) {
                final c = _roleColor(r, theme);
                return Chip(
                  label: Text(r),
                  backgroundColor: c,
                  labelStyle: const TextStyle(color: Colors.white),
                );
              })
              .toList(growable: false),
        );
        final sitesText = u.sites.map((s) => s.name).join(', ');
        return DataRow(cells: [
          DataCell(Text(u.login)),
          DataCell(rolesChips),
          DataCell(Text(sitesText.isEmpty ? '-' : sitesText)),
          DataCell(Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Modifier',
                onPressed: () => _editUtilisateur(u),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Supprimer',
                onPressed: () => _deleteUtilisateur(u),
              ),
            ],
          )),
        ]);
      }).toList(growable: false),
    );
  }

  // Extension-like helper to get a darker shade if it's a MaterialColor

  @override
  Widget build(BuildContext context) {
    
    Widget content;
    if( _loading ) {
      content = const Center(child: CircularProgressIndicator());
    } else if( _users.isEmpty ) {
      content = const Center(child: Text('Aucun utilisateur'));
    } else {
      content = Card(
        margin: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
              child: _buildDataTable(),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      body: GradiantBackground.getSafeAreaGradiant(context, content),
      floatingActionButton: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: FloatingActionButton(
          onPressed: () => _createUtilisateur(),
          tooltip: 'Ajouter un utilisateur',
          child: const Icon(Icons.add),
        ),
      ),
    );
    
  }
}
