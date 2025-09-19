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
    final ok = await _openUserEditor(context, user: null);
    if (ok == true) {
      await _loadUsers();
    }
  }

  void _editUtilisateur(User user) async {
    final ok = await _openUserEditor(context, user: user);
    if (ok == true) {
      await _loadUsers();
    }
  }

  Future<bool?> _openUserEditor(BuildContext context, {User? user}) async {
    final isEdit = user != null;
    final client = SessionManager.instance.client;
    final usersApi = UsersApi(client);
    final rolesApi = RolesApi(client);
    final sitesApi = SitesApi(client);
    final usrSiteRoleApi = UserSiteRoleApi(client);

    // Charger les rôles et les sites
    List<Role> roles = [];
    List<SiteLite> sites = [];
    try { roles = await rolesApi.list(); } catch (_) {}
    try { sites = await sitesApi.list(); } catch (_) {}

    Map<int, String> roleNameById = { for (final r in roles) r.id: r.name };
    String _normRoleName(String s) => s.toLowerCase().replaceAll('-', '').replaceAll('_', '').trim();
    Map<String, int> roleIdByNorm = { for (final r in roles) _normRoleName(r.name): r.id };

    final roleUserId = roleIdByNorm['user'];
    final roleTechId = roleIdByNorm['technicien'] ?? roleIdByNorm['technician'];
    final roleAdminId = roleIdByNorm['admin'];
    final roleSuperId = roleIdByNorm['superadmin'];

    final orderedRoleIds = [roleUserId, roleTechId, roleAdminId, roleSuperId].whereType<int>().toList();

    // Sites autorisés
    final selectedSiteId = _currentSiteId ?? SessionManager.instance.selectedSiteId;
    List<SiteLite> allowedSites;
    if (_isSuperAdmin) {
      allowedSites = sites;
    } else {
      allowedSites = sites.where((s) => s.id == selectedSiteId).toList();
      if (allowedSites.isEmpty && selectedSiteId != null) {
        final found = sites.firstWhere((s) => s.id == selectedSiteId, orElse: () => SiteLite(id: selectedSiteId, name: 'Site $selectedSiteId'));
        allowedSites = [found];
      }
    }



    List<Assignment> assignments = [];
    if (isEdit) {
      try {
        final data = await usrSiteRoleApi.userPermissions(user.id);
        final perms = (data['permissions'] as List?) ?? const [];
        final bySite = <int, Assignment>{};
        for (final p in perms) {
          if (p is Map) {
            final m = p.cast<String, dynamic>();
            final sid = (m['site_id'] as int?) ?? 0;
            if (sid == 0) continue; // ignore global
            final sname = (m['site_name']?.toString() ?? '');
            final rid = (m['role_id'] as int?) ?? 0;
            final relId = (m['id'] as int?) ?? 0;
            final asg = bySite.putIfAbsent(sid, () => Assignment(siteId: sid, siteName: sname, selected: <int>{}, initial: <int>{}, rel: <int, int>{}));
            asg.selectedRoleIds.add(rid);
            asg.initialRoleIds.add(rid);
            if (relId != 0) asg.relIdByRoleId[rid] = relId;
          }
        }
        assignments = bySite.values.toList();
      } catch (e) {
        ApiErrorHandler.logDebug(e, context: 'permissions.load');
      }
    } else {
      final sid = selectedSiteId ?? (allowedSites.isNotEmpty ? allowedSites.first.id : null);
      if (sid != null) {
        final sname = allowedSites.firstWhere((s) => s.id == sid, orElse: () => SiteLite(id: sid, name: 'Site $sid')).name;
        final defaultRoles = <int>{if (roleUserId != null) roleUserId};
        assignments = [
          Assignment(siteId: sid, siteName: sname, selected: defaultRoles, initial: <int>{}),
        ];
      }
    }

    String login = user?.login ?? '';
    String password = '';
    bool dirty = false;

    final initialAssignments = assignments.map((a) => a.clone()).toList();
    final theme = Theme.of(context);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setState) {
          void markDirty() {
            dirty = true;
            setState(() {});
          }

          Future<void> addSite() async {
            final choice = await showDialog<SiteLite>(
              context: ctx,
              builder: (_) => SimpleDialog(
                title: const Text('+ Ajouter un site'),
                children: allowedSites
                    .map((s) => SimpleDialogOption(
                          onPressed: () => Navigator.pop(ctx, s),
                          child: Text(s.name),
                        ))
                    .toList(),
              ),
            );
            if (choice == null) return;
            final existing = assignments.where((a) => a.siteId == choice.id).toList();
            if (existing.isNotEmpty) {
              if (roleUserId != null) existing.first.selectedRoleIds.add(roleUserId);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Site déjà présent — rôles fusionnés.')));
            } else {
              assignments.add(Assignment(siteId: choice.id, siteName: choice.name, selected: <int>{if (roleUserId != null) roleUserId}, initial: <int>{}));
            }
            markDirty();
          }

          Widget buildRoleChips(Assignment a) {
            return Wrap(
              spacing: 8,
              children: orderedRoleIds.map((rid) {
                final rname = roleNameById[rid] ?? rid.toString();
                final isSuper = _normRoleName(rname) == 'superadmin';
                final enabled = _isSuperAdmin || !isSuper; // admin cannot toggle super-admin
                final selected = a.selectedRoleIds.contains(rid);
                final color = _roleColor(rname, theme);
                return FilterChip(
                  label: Text(rname),
                  selected: selected,
                  onSelected: enabled
                      ? (v) {
                          if (v) {
                            a.selectedRoleIds.add(rid);
                          } else {
                            a.selectedRoleIds.remove(rid);
                          }
                          markDirty();
                        }
                      : null,
                  selectedColor: color.withOpacity(0.8),
                  disabledColor: Colors.grey.shade300,
                );
              }).toList(),
            );
          }

          Future<bool> confirmDeleteSite() async {
            final conf = await showDialog<bool>(
              context: ctx,
              builder: (_) => AlertDialog(
                title: const Text('Confirmer'),
                content: const Text('Supprimer l’attribution de ce site pour cet utilisateur ?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer')),
                ],
              ),
            );
            return conf == true;
          }

          return AlertDialog(
            title: Text(isEdit ? 'Modifier l’utilisateur' : 'Créer un utilisateur'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      initialValue: login,
                      decoration: const InputDecoration(labelText: 'Nom d’utilisateur'),
                      onChanged: (v) {
                        login = v;
                        markDirty();
                      },
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: isEdit ? 'Mot de passe (laisser vide pour ne pas changer)' : 'Mot de passe'),
                      obscureText: true,
                      onChanged: (v) {
                        password = v;
                        markDirty();
                      },
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('+ Ajouter un site'),
                        onPressed: allowedSites.isEmpty ? null : addSite,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...assignments.map((a) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(a.siteName, style: const TextStyle(fontWeight: FontWeight.bold))),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    tooltip: 'Retirer le site',
                                    onPressed: () async {
                                      if (await confirmDeleteSite()) {
                                        assignments.remove(a);
                                        markDirty();
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              buildRoleChips(a),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                children: a.selectedRoleIds.map((rid) {
                                  final rn = roleNameById[rid] ?? rid.toString();
                                  final c = _roleColor(rn, theme);
                                  return Chip(label: Text(rn), backgroundColor: c, labelStyle: const TextStyle(color: Colors.white));
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
              if (dirty)
                FilledButton(
                  onPressed: () async {
                    if (login.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Le nom d’utilisateur est requis.')));
                      return;
                    }
                    if (!isEdit && password.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Le mot de passe est requis.')));
                      return;
                    }
                    final confirm = await showDialog<bool>(
                      context: ctx,
                      builder: (_) => AlertDialog(
                        title: const Text('Confirmer'),
                        content: Text(isEdit ? 'Enregistrer les modifications ?' : 'Créer cet utilisateur ?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('OK')),
                        ],
                      ),
                    );
                    if (confirm != true) return;
                    final snapshot = assignments.map((e) => e.clone()).toList();
                    try {
                      final rels = <Map<String, dynamic>>[];
                      for (final a in assignments) {
                        for (final rid in a.selectedRoleIds) {
                          rels.add({'site_id': a.siteId, 'role_id': rid});
                        }
                      }
                      debugPrint('[DEBUG] UI: ${isEdit ? 'Update' : 'Create'} user request login=$login, assignments=${assignments.map((a)=>'${a.siteId}:'+a.selectedRoleIds.join(',')).toList()}');
                      if (!isEdit) {
                        debugPrint('[DEBUG] UI: calling createWithRelations with ${rels.length} relations');
                        await usersApi.createWithRelations(user: {'login': login, 'password': password}, relations: rels);
                        debugPrint('[DEBUG] UI: createWithRelations OK');
                      } else {
                        // EDIT mode: perform diff-based updates to ensure deletions are applied
                        final userPatch = <String, dynamic>{'login': login};
                        if (password.trim().isNotEmpty) userPatch['password'] = password;

                        // 1) Update user fields first
                        debugPrint('[DEBUG] UI: updating user fields (id=${user.id}) -> ${userPatch.keys.toList()}');
                        await usersApi.update(user.id, userPatch);

                        // 2) Build maps for initial vs current state
                        final initialBySite = {for (final a in initialAssignments) a.siteId: a};
                        final currentBySite = {for (final a in assignments) a.siteId: a};

                        Map<String, int>? existingBySiteRole; // lazy-filled if needed
                        Future<int?> _ensureRelId(int siteId, int roleId) async {
                          // Try from initial snapshot first
                          final init = initialBySite[siteId];
                          final rid = init?.relIdByRoleId[roleId];
                          if (rid != null && rid != 0) return rid;
                          // Fallback: fetch once
                          if (existingBySiteRole == null) {
                            debugPrint('[DEBUG] UI: fetching user permissions to resolve relation ids (userId=${user.id})');
                            final existing = await usrSiteRoleApi.userPermissions(user.id);
                            final perms = (existing['permissions'] as List?) ?? const [];
                            existingBySiteRole = <String, int>{};
                            for (final p in perms) {
                              if (p is Map) {
                                final m = p.cast<String, dynamic>();
                                final sid = (m['site_id'] as int?) ?? 0;
                                final rlid = (m['role_id'] as int?) ?? 0;
                                final relId = (m['id'] as int?) ?? 0;
                                if (sid != 0 && rlid != 0 && relId != 0) existingBySiteRole!['$sid:$rlid'] = relId;
                              }
                            }
                          }
                          return existingBySiteRole!['$siteId:$roleId'];
                        }

                        // 3) Sites removed entirely
                        for (final sid in initialBySite.keys) {
                          if (!currentBySite.containsKey(sid)) {
                            debugPrint('[DEBUG] UI: removing all relations for userId=${user.id} on siteId=$sid');
                            await usrSiteRoleApi.deleteUserSite(user.id, sid);
                          }
                        }

                        // 4) Sites added or modified
                        for (final entry in currentBySite.entries) {
                          final sid = entry.key;
                          final cur = entry.value;
                          final init = initialBySite[sid];
                          if (init == null) {
                            // New site assignment: create all selected roles
                            for (final rid in cur.selectedRoleIds) {
                              debugPrint('[DEBUG] UI: creating relation userId=${user.id}, siteId=$sid, roleId=$rid');
                              await usrSiteRoleApi.create(userId: user.id, siteId: sid, roleId: rid);
                            }
                          } else {
                            final toAdd = cur.selectedRoleIds.difference(init.initialRoleIds);
                            final toRemove = init.initialRoleIds.difference(cur.selectedRoleIds);

                            for (final rid in toAdd) {
                              debugPrint('[DEBUG] UI: creating missing relation userId=${user.id}, siteId=$sid, roleId=$rid');
                              await usrSiteRoleApi.create(userId: user.id, siteId: sid, roleId: rid);
                            }
                            for (final rid in toRemove) {
                              final relId = await _ensureRelId(sid, rid);
                              if (relId != null) {
                                debugPrint('[DEBUG] UI: deleting relation id=$relId (userId=${user.id}, siteId=$sid, roleId=$rid)');
                                await usrSiteRoleApi.deleteRelation(relId);
                              } else {
                                // If we cannot resolve a specific relation id and all roles are now removed, delete all for site
                                if (cur.selectedRoleIds.isEmpty) {
                                  debugPrint('[DEBUG] UI: deleting all relations for userId=${user.id} on siteId=$sid (fallback)');
                                  await usrSiteRoleApi.deleteUserSite(user.id, sid);
                                } else {
                                  debugPrint('[DEBUG] UI: WARNING could not resolve relation id for deletion (siteId=$sid roleId=$rid)');
                                }
                              }
                            }
                          }
                        }

                        debugPrint('[DEBUG] UI: diff-based update completed for userId=${user.id}');
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(isEdit ? 'Modifications enregistrées' : 'Utilisateur créé')));
                      }
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    } on Object catch (e) {
                      ApiErrorHandler.logDebug(e, context: 'users.(create|update)-with-relations');
                      try {
                        int userId = user?.id ?? 0;
                        if (!isEdit) {
                          debugPrint('[DEBUG] UI: fallback create user(login=$login)');
                          final createdUser = await usersApi.create(login: login, password: password);
                          userId = createdUser.id;
                          debugPrint('[DEBUG] UI: fallback create user OK -> id=$userId');
                        } else {
                          final patch = <String, dynamic>{'login': login};
                          if (password.trim().isNotEmpty) patch['password'] = password;
                          debugPrint('[DEBUG] UI: fallback update user(id=${user.id})');
                          await usersApi.update(user.id, patch);
                          userId = user.id;
                          debugPrint('[DEBUG] UI: fallback update user OK');
                        }
                        final existing = await usrSiteRoleApi.userPermissions(userId);
                        final perms = (existing['permissions'] as List?) ?? const [];
                        final existingBySiteRole = <String, int>{};
                        for (final p in perms) {
                          if (p is Map) {
                            final m = p.cast<String, dynamic>();
                            final sid = (m['site_id'] as int?) ?? 0;
                            final rid = (m['role_id'] as int?) ?? 0;
                            final relId = (m['id'] as int?) ?? 0;
                            if (sid != 0 && rid != 0 && relId != 0) existingBySiteRole['$sid:$rid'] = relId;
                          }
                        }
                        final desiredKeys = <String>{};
                        for (final a in assignments) {
                          for (final rid in a.selectedRoleIds) {
                            final key = '${a.siteId}:$rid';
                            desiredKeys.add(key);
                            if (!existingBySiteRole.containsKey(key)) {
                              debugPrint('[DEBUG] UI: creating missing relation userId=$userId, siteId=${a.siteId}, roleId=$rid');
                              await usrSiteRoleApi.create(userId: userId, siteId: a.siteId, roleId: rid);
                            }
                          }
                        }
                        for (final entry in existingBySiteRole.entries) {
                          if (!desiredKeys.contains(entry.key)) {
                            debugPrint('[DEBUG] UI: deleting extra relation id=${entry.value}');
                            await usrSiteRoleApi.deleteRelation(entry.value);
                          }
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(isEdit ? 'Modifications enregistrées' : 'Utilisateur créé')));
                        }
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } on Object catch (e2) {
                        assignments = snapshot;
                        (ctx as Element).markNeedsBuild();
                        ApiErrorHandler.showSnackBar(context, e2, action: isEdit ? 'Modification utilisateur' : 'Création utilisateur');
                      }
                    }
                  },
                  child: const Text('Valider'),
                ),
            ],
          );
        });
      },
    );

    return result ?? false;
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
      debugPrint('[DEBUG] UI: delete action choice=$choice userId=${user.id} siteId=$siteId');
      if (choice == 'site' && siteId != null) {
        // Supprime toutes les relations user<->site (rôles compris)
        final usrSiteRoleApi = UserSiteRoleApi(SessionManager.instance.client);
        await usrSiteRoleApi.deleteUserSite(user.id, siteId);
        debugPrint('[DEBUG] UI: deleteUserSite OK for userId=${user.id}, siteId=$siteId');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur retiré du site')),
        );
      } else if (choice == 'all') {
        // Suppression complète en base
        final api = UsersApi(SessionManager.instance.client);
        await api.deleteUser(user.id);
        debugPrint('[DEBUG] UI: deleteUser OK for userId=${user.id}');
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

// Modèle d'affectation

