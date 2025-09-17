part of '../../main.dart';

class GestionUtilisateursPage extends StatefulWidget {
  const GestionUtilisateursPage({super.key});

  @override
  State<GestionUtilisateursPage> createState() => _GestionUtilisateursPageState();
}

class _GestionUtilisateursPageState extends State<GestionUtilisateursPage> {
  bool _loading = true;
  List<User> _users = const [];
  // Contexte courant pour filtrage par site
  bool _isSuperAdmin = false;
  int? _currentSiteId; // site effectif utilisé pour filtrer/afficher
  Map<int, String> _siteRoleByUser = const {}; // userId -> roleName pour le site courant

  // Suivi de la sélection de site brute pour éviter les rechargements en boucle
  int? _lastSelectedSiteId;
  bool _reloadScheduled = false;

  @override
  void initState() {
    super.initState();
    _lastSelectedSiteId = SessionManager.instance.selectedSiteId;
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    // reset le flag de planification pour autoriser un re-scheduling après ce chargement
    _reloadScheduled = false;
    setState(() => _loading = true);
    try {
      final usersApi = UsersApi(SessionManager.instance.client);
      final usrSiteRoleApi = UserSiteRoleApi(SessionManager.instance.client);

      // Contexte: user courant + site courant
      User? me;
      try {
        me = await usersApi.me();
      } catch (e) {
        ApiErrorHandler.logDebug(e, context: 'users.me');
      }
      final roles = me?.roles ?? const [];
      final isSuper = RoleUtils.normalizeAll(roles).contains(AppRole.superAdmin);
      final rawSelected = SessionManager.instance.selectedSiteId;
      int? siteId = rawSelected;
      siteId ??= (me != null && me.sites.isNotEmpty ? me.sites.first.id : null);

      // Récupère tous les utilisateurs
      List<User> users = await usersApi.list();

      // Si pas super admin: restreindre aux utilisateurs du site courant et préparer leur rôle pour ce site
      Map<int, String> siteRoleByUser = {};
      if (!isSuper && siteId != null) {
        try {
          final list = await usrSiteRoleApi.siteUsers(siteId);
          final ids = <int>{};
          for (final raw in list) {
            if (raw is Map) {
              final m = raw.cast<String, dynamic>();
              final uidDyn = m['user_id'] ?? m['userId'];
              final uid = uidDyn is int ? uidDyn : int.tryParse(uidDyn?.toString() ?? '');
              final roleNameDyn = m['role_name'] ?? m['roleName'] ?? m['role'];
              final roleName = roleNameDyn?.toString();
              if (uid != null) {
                ids.add(uid);
                if (roleName != null && roleName.isNotEmpty) {
                  siteRoleByUser[uid] = roleName;
                }
              }
            }
          }
          users = users.where((u) => ids.contains(u.id)).toList(growable: false);
        } catch (e) {
          // Fallback: filtrer via la présence du site dans u.sites
          ApiErrorHandler.logDebug(e, context: 'user_site_role.siteUsers');
          users = users.where((u) => u.sites.any((s) => s.id == siteId)).toList(growable: false);
        }
      }

      if (!mounted) return;
      setState(() {
        _users = users;
        _isSuperAdmin = isSuper;
        _currentSiteId = siteId;
        _siteRoleByUser = siteRoleByUser;
        _lastSelectedSiteId = rawSelected; // mémorise la sélection brute
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
    // Détermine le contexte
    final isSuper = _isSuperAdmin;
    final siteId = _currentSiteId ?? SessionManager.instance.selectedSiteId;

    // Si super admin: proposer le choix. Sinon: suppression des relations du site courant uniquement.
    String? choice; // 'site' ou 'all'
    if (isSuper) {
      choice = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Supprimer l\'utilisateur'),
          content: Text(
              siteId != null
                  ? "Que souhaitez-vous faire pour '${user.login}' ?"
                  : "Aucun site sélectionné. Voulez-vous supprimer définitivement l\'utilisateur '${user.login}' ?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Annuler')),
            if (siteId != null)
              TextButton(
                onPressed: () => Navigator.pop(context, 'site'),
                child: const Text('Retirer du site'),
              ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'all'),
              child: const Text('Supprimer définitivement'),
            ),
          ],
        ),
      );
      if (choice == null) return; // annulé
    } else {
      // Admin (non super): uniquement retrait du site courant
      if (siteId == null) {
        ApiErrorHandler.showSnackBar(context, 'Aucun site sélectionné. Impossible de retirer l\'utilisateur du site.');
        return;
      }
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Retirer du site'),
          content: Text("Retirer l\'utilisateur '${user.login}' du site courant ?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Retirer')),
          ],
        ),
      );
      if (confirm != true) return;
      choice = 'site';
    }

    try {
      if (choice == 'site' && siteId != null) {
        // Supprime toutes les relations user<->site (rôles compris)
        final usrSiteRoleApi = UserSiteRoleApi(SessionManager.instance.client);
        await usrSiteRoleApi.deleteUserSite(user.id, siteId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur retiré du site')),
        );
      } else if (choice == 'all') {
        // Suppression complète en base
        final api = UsersApi(SessionManager.instance.client);
        await api.deleteUser(user.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur supprimé définitivement')),
        );
      }
      await _loadUsers();
    } on Object catch (e) {
      ApiErrorHandler.logDebug(e, context: choice == 'site' ? 'user_site_role.deleteUserSite' : 'users.delete');
      if (mounted) {
        ApiErrorHandler.showSnackBar(
          context,
          e,
          action: choice == 'site' ? 'Retrait du site' : 'Suppression utilisateur',
        );
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
        DataColumn(label: Text("Nom d'utilisateur" , style: TextStyle(fontWeight: FontWeight.bold),) ),
        DataColumn(label: Text('Rôles', style: TextStyle(fontWeight: FontWeight.bold),) ),
        DataColumn(label: Text('Sites', style: TextStyle(fontWeight: FontWeight.bold),) ),
        DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold),) )
      ],
      rows: _users.map((u) {
        final theme = Theme.of(context);

        // Détermine les rôles à afficher (site courant uniquement si non super admin)
        List<String> finalRoles;
        if (_isSuperAdmin || _currentSiteId == null) {
          finalRoles = u.roles;
        } else {
          finalRoles = [];
          final r = _siteRoleByUser[u.id];
          if (r != null && r.isNotEmpty) finalRoles = [r];
        }

        final rolesChips = Wrap(
          spacing: 8,
          runSpacing: 4,
          children: finalRoles
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

        // Détermine le texte des sites (site courant uniquement si non super admin)
        String sitesText;
        if (_isSuperAdmin || _currentSiteId == null) {
          sitesText = u.sites.map((s) => s.name).join(', ');
        } else {
          final match = u.sites.where((s) => s.id == _currentSiteId).toList();
          sitesText = match.isNotEmpty ? match.first.name : '-';
        }
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
    // Si la sélection de site a changé via le Drawer, recharger (sauf si déjà en cours)
    final sid = SessionManager.instance.selectedSiteId;
    if (!_loading && !_reloadScheduled && sid != _lastSelectedSiteId) {
      _reloadScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadUsers();
      });
    }
    
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
