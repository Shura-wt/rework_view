part of '../main.dart';

class LeftDrawer extends StatefulWidget {
  const LeftDrawer({super.key});

  @override
  State<LeftDrawer> createState() => _LeftDrawerState();
}

class _LeftDrawerState extends State<LeftDrawer> {
  final _sitesApi = SitesApi(SessionManager.instance.client);
  final _statusApi = StatusApi(SessionManager.instance.client);
  final _usersApi = UsersApi(SessionManager.instance.client);

  // État
  List<SiteLite> _sites = const [];
  SiteLite? _selectedSite;
  Site? _siteFull;
  List<Baes> _unassigned = const [];

  Map<int, BaeStatus> _latestByBaes = const {}; // cache latest par baesId

  bool _loading = true;
  Object? _error;

  // Filtres (0=connexion, 4=batterie)
  bool _showConnection = true;
  bool _showBattery = true;

  bool _isAdminLike = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Rôles utilisateur
      try {
        final me = await _usersApi.me();
        _isAdminLike = RoleUtils.isAdminLike(me.roles);
        // Si backend filtre /sites/ par utilisateur, on peut utiliser me.sites
      } catch (e) {
        // Non bloquant si /me indisponible
        ApiErrorHandler.logDebug(e, context: 'users.me');
      }

      // Sites accessibles
      final sites = await _sitesApi.list();
      _sites = sites;
      _selectedSite ??= sites.isNotEmpty ? sites.first : null;

      // Site complet + baes non placés
      if (_selectedSite != null) {
        await _loadSiteFull(_selectedSite!.id);
        await _loadUnassigned(_selectedSite!.id);
      }

      // Derniers statuts (fallback si latest_status manquant)
      final latest = await _statusApi.latest();
      _latestByBaes = {
        for (final st in latest)
          if (st.baesId != null) st.baesId!: st,
      };

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadSiteFull(int siteId) async {
    final site = await _sitesApi.getFull(siteId, include: 'batiments,etages,baes,status_latest');
    setState(() => _siteFull = site);
  }

  Future<void> _loadUnassigned(int siteId) async {
    try {
      final list = await _sitesApi.unassignedBaes(siteId);
      setState(() => _unassigned = list);
    } catch (e) {
      // Optionnel, l'endpoint peut ne pas exister; ignorer silencieusement
      ApiErrorHandler.logDebug(e, context: 'sites.unassigned');
      setState(() => _unassigned = const []);
    }
  }

  void _onSiteChanged(SiteLite? site) async {
    if (site == null) return;
    setState(() {
      _selectedSite = site;
      _siteFull = null;
      _unassigned = const [];
      _loading = true;
      _error = null;
    });
    try {
      await _loadSiteFull(site.id);
      await _loadUnassigned(site.id);
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  // Helpers statut
  BaeStatus? _activeStatusFor(Baes b) {
    return b.latestStatus ?? _latestByBaes[b.id] ?? _mostRecent(b.statuses);
  }

  BaeStatus? _mostRecent(List<BaeStatus> statuses) {
    if (statuses.isEmpty) return null;
    final copy = List<BaeStatus>.of(statuses);
    copy.sort((a, b) {
      final at = a.updatedAt ?? a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.updatedAt ?? b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });
    return copy.first;
  }

  bool _isOkOrUnknown(int? code) {
    if (code == 6) return true;
    final info = StatusErrorVisuals.infoFor(code);
    return identical(info, StatusErrorVisuals.unknown);
  }

  // Règles filtres au niveau BAES (statut actif)
  // - Aucun coché: OK(6) + inconnus
  // - Un seul coché: seulement ce type
  // - Deux cochés: tout (0,4,6, inconnus)
  bool _baesPassesFilters(Baes b) {
    final st = _activeStatusFor(b);
    final code = st?.erreur;
    final isConn = code == 0;
    final isBatt = code == 4;
    if (!_showConnection && !_showBattery) return _isOkOrUnknown(code);
    if (_showConnection && _showBattery) return true;
    if (_showConnection) return isConn;
    if (_showBattery) return isBatt;
    return false;
  }

  // Pour la tuile "Erreurs": BAES qui ont des erreurs du type activé
  // Lignes: max 3 (connexion 0, batterie 4, OK 6)
  List<BaeStatus> _collectErrorLines(Baes b) {
    final active = _activeStatusFor(b);
    bool hasType(int code) => b.statuses.any((s) => s.erreur == code) || active?.erreur == code;

    bool appear;
    if (!_showConnection && !_showBattery) {
      appear = false; // pas d'erreur à lister
    } else if (_showConnection && _showBattery) {
      appear = hasType(0) || hasType(4);
    } else if (_showConnection) {
      appear = hasType(0);
    } else {
      appear = hasType(4);
    }
    if (!appear) return const [];

    BaeStatus? pickFirst(int code) {
      final inList = b.statuses.firstWhere(
            (s) => s.erreur == code,
        orElse: () => _activeStatusFor(b)?.erreur == code ? _activeStatusFor(b)! : (null as BaeStatus),
      );
      return inList;
    }

    final conn = pickFirst(0);
    final batt = pickFirst(4);
    final ok = pickFirst(6);

    final lines = <BaeStatus>[];
    if (_showConnection && conn != null) lines.add(conn);
    if (_showBattery && batt != null) lines.add(batt);
    if ((_showConnection || _showBattery) && ok != null) lines.add(ok); // ajoute OK pour contexte

    return lines.take(3).toList(growable: false);
  }

  Future<void> _ignore(Baes b, int erreur) async {
    final updated = await ApiErrorHandler.run<BaeStatus>(
      context,
          () => _statusApi.updateBaesType(b.id, erreur, isIgnored: true),
      action: 'ignorer',
    );
    if (updated != null) {
      setState(() {
        _latestByBaes = Map<int, BaeStatus>.from(_latestByBaes)..[b.id] = updated;
      });
    }
  }

  Future<void> _ack(Baes b, int erreur) async {
    final updated = await ApiErrorHandler.run<BaeStatus>(
      context,
          () => _statusApi.updateBaesType(b.id, erreur, isSolved: true),
      action: 'acquitter',
    );
    if (updated != null) {
      setState(() {
        _latestByBaes = Map<int, BaeStatus>.from(_latestByBaes)..[b.id] = updated;
      });
    }
  }

  void _gotoGestionCarte() {
    Navigator.pop(context);
    Navigator.pushNamed(context, '/admin/carte');
  }

  // UI: Header
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Card(
              color:  const Color(0xFF045f78),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButton<SiteLite>(
                  isExpanded: true,
                  value: _selectedSite,
                  dropdownColor:  const Color(0xFF045f78),

                  hint: const Text('Choisir un site'),
                  items: _sites
                      .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.name, style: TextStyle(color: Colors.white) ),

                  ))
                      .toList(),
                  onChanged: _onSiteChanged,
                ),
              ),
            ),
          ),
          if (_isAdminLike)
            IconButton(
              tooltip: 'Gérer les sites' ,
              color: Colors.white,

              icon: const Icon(Icons.settings),
              onPressed: _openManageSitesDialog,
            ),
        ],
      ),
    );
  }

  // UI: Filtres
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          CheckboxListTile(
            value: _showConnection,
            onChanged: (v) => setState(() => _showConnection = v ?? false),
            title: const Text('Afficher status de connexion (erreur 0) ' , style: TextStyle(color: Colors.white)),
          ),
          CheckboxListTile(
            value: _showBattery,
            onChanged: (v) => setState(() => _showBattery = v ?? false),
            title: const Text('Afficher status de batterie (erreur 4)' , style: TextStyle(color: Colors.white)),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 6),
              child: Text(
                (!_showConnection && !_showBattery)
                    ? 'Filtre: seulement OK (6) et inconnus '
                    : (_showConnection && _showBattery)
                    ? 'Filtre: tous les statuts (0, 4, 6, inconnus)'
                    : _showConnection
                    ? 'Filtre: erreurs connexion (0)'
                    : 'Filtre: erreurs batterie (4)',
                style: const TextStyle(color: Colors.white54),
              ),
            ),
          )
        ],
      ),
    );
  }

  // UI: Liste tab — Layout demandé: ListView -> Card(Batiment) -> Card(Etage) -> ListTile(BAES)
  Widget _buildListeListView() {
    final site = _siteFull;
    if (site == null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [Text('Aucun site sélectionné ou données indisponibles.')],
      );
    }

    final batimentCards = <Widget>[];
    for (final bat in site.batiments) {
      final etageTuples = <(Etage, List<Baes>)>[];
      for (final etg in bat.etages) {
        final baesFiltered = etg.baes.where(_baesPassesFilters).toList();
        if (baesFiltered.isNotEmpty) {
          etageTuples.add((etg, baesFiltered));
        }
      }
      if (etageTuples.isEmpty) continue;

      batimentCards.add(
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ExpansionTile(
            title: Text(bat.name),
            children: [
              for (final tuple in etageTuples)
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ExpansionTile(
                    title: Text(tuple.$1.name),
                    children: [
                      for (final b in tuple.$2) _buildBaesListTile(b),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (batimentCards.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [Text('Aucun élément à afficher avec les filtres actuels.')],
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      children: batimentCards,
    );
  }

  Widget _buildBaesListTile(Baes b) {
    final st = _activeStatusFor(b);
    final info = StatusErrorVisuals.infoFor(st?.erreur);
    return ListTile(
      leading: Icon(info.icon, color: _colorForCode(st?.erreur)),
      title: Text(b.name),
      subtitle: Text(info.name),
    );
  }

  // UI: Tuile "Erreurs"
  Widget _buildErreursTile() {
    final site = _siteFull;
    if (site == null) return const SizedBox.shrink();

    if (!_showConnection && !_showBattery) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: const ListTile(
          title: Text('Erreurs'),
          subtitle: Text("Aucun type d'erreur sélectionné."),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: const Text('Erreurs'),
        children: site.batiments.map((bat) {
          final etagesWithErr = bat.etages.where((e) => e.baes.any((b) => _collectErrorLines(b).isNotEmpty));
          if (etagesWithErr.isEmpty) return const SizedBox.shrink();
          return ExpansionTile(
            title: Text(bat.name),
            children: etagesWithErr.map((etg) {
              final baesWithErr = etg.baes.where((b) => _collectErrorLines(b).isNotEmpty).toList();
              if (baesWithErr.isEmpty) return const SizedBox.shrink();
              return ExpansionTile(
                title: Text(etg.name),
                children: baesWithErr.map((b) {
                  final lines = _collectErrorLines(b);
                  return ListTile(
                    title: Text(b.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final st in lines)
                          _StatusRow(
                            status: st,
                            onIgnore: st.erreur == 6 ? null : () => _ignore(b, st.erreur),
                            onAck: st.erreur == 6 ? null : () => _ack(b, st.erreur),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  // UI: Tuile "Non placé"
  Widget _buildNonPlaceTile() {
    final site = _siteFull;
    if (site == null) return const SizedBox.shrink();

    // Prend d'abord la liste fournie par l'endpoint optionnel, sinon essaie de dériver depuis le site
    final list = _unassigned.isNotEmpty
        ? _unassigned
        : [
      for (final bat in site.batiments)
        for (final etg in bat.etages)
          for (final b in etg.baes)
            if (b.etageId == null) b,
    ];

    final filtered = list.where(_baesPassesFilters).toList();

    if (filtered.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: const Text('Non placé'),
        children: filtered.map((b) {
          final st = _activeStatusFor(b);
          final info = StatusErrorVisuals.infoFor(st?.erreur);
          return ListTile(
            leading: Icon(info.icon, color: _colorForCode(st?.erreur)),
            title: Text(b.name),
            trailing: _isAdminLike
                ? IconButton(
                    icon: const Icon(Icons.map),
                    tooltip: 'Aller à la gestion carte',
                    onPressed: _gotoGestionCarte,
                  )
                : null,
          );
        }).toList(),
      ),
    );
  }

  Color _colorForCode(int? code) {
    switch (code) {
      case 0:
        return Colors.orange; // connexion
      case 4:
        return Colors.red; // batterie
      case 6:
        return Colors.green; // OK
      default:
        return Colors.grey; // inconnu
    }
  }

  Future<void> _openManageSitesDialog() async {
    if (!_isAdminLike) return;
    showDialog(
      context: context,
      builder: (ctx) => _ManageSitesDialog(
        sites: _sites,
        onCreate: (name) async {
          await ApiErrorHandler.run<SiteLite>(
            context,
                () async {
              final created = await _sitesApi.create(name);
              setState(() {
                _sites = [..._sites, created];
                _selectedSite ??= created;
              });
              return created;
            },
            action: 'create site',
          );
          if (mounted) Navigator.pop(ctx);
        },
        onRename: (siteId, newName) async {
          await ApiErrorHandler.run<SiteLite>(
            context,
                () async {
              final updated = await _sitesApi.update(siteId, name: newName);
              setState(() {
                _sites = _sites.map((s) => s.id == siteId ? updated : s).toList(growable: false);
                if (_selectedSite?.id == siteId) _selectedSite = updated;
              });
              return updated;
            },
            action: 'rename site',
          );
        },
        onDelete: (siteId) async {
          await ApiErrorHandler.run<Map<String, dynamic>>(
            context,
                () async {
              final res = await _sitesApi.deleteSite(siteId);
              setState(() {
                _sites = _sites.where((s) => s.id != siteId).toList();
                if (_selectedSite?.id == siteId) {
                  _selectedSite = _sites.isNotEmpty ? _sites.first : null;
                  _siteFull = null;
                }
              });
              return res;
            },
            action: 'delete site',
          );
          if (mounted) Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Drawer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF98a069),
                Color(0xFF045f78),
                Color(0xFF1c2d41),
              ],
            ),
          ),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 8),
                  const Text('Erreur: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('$_error'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _initData,
                    child: const Text('Réessayer'),
                  )
                ],
              ),
            ),
          )
              : DefaultTabController(
            length: 3,
            child: Column(
              children: [
                _buildHeader(),
                _buildFilters(),
                const TabBar(
                  tabs: [
                    Tab(text: 'Liste' , icon: Icon(Icons.list) ),
                    Tab(text: 'Erreurs', icon: Icon(Icons.error_outline)),
                    Tab(text: 'Non placé', icon: Icon(Icons.location_off)),
                  ],
                  labelColor: Colors.black,
                  indicatorColor: Colors.blue,
                  unselectedLabelColor: Colors.white,
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Tab 1: Liste
                      _siteFull != null
                          ? _buildListeListView()
                          : ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: const [
                          Text('Aucun site sélectionné ou données indisponibles.', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                      // Tab 2: Erreurs
                      SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            if (_siteFull != null)
                              _buildErreursTile()
                            else
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('Aucun site sélectionné ou données indisponibles.', style: TextStyle(color: Colors.white)),
                              ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                      // Tab 3: Non placé
                      SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            if (_siteFull != null)
                              _buildNonPlaceTile()
                            else
                              const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('Aucun site sélectionné ou données indisponibles.', style: TextStyle(color: Colors.white)),
                              ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final BaeStatus status;
  final VoidCallback? onIgnore;
  final VoidCallback? onAck;
  const _StatusRow({required this.status, this.onIgnore, this.onAck});

  @override
  Widget build(BuildContext context) {
    final info = StatusErrorVisuals.infoFor(status.erreur);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(info.icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(info.name)),
          if (onIgnore != null)
            TextButton(onPressed: onIgnore, child: const Text('Ignorer')),
          if (onAck != null)
            TextButton(onPressed: onAck, child: const Text('Acquitter')),
        ],
      ),
    );
  }
}

class _ManageSitesDialog extends StatefulWidget {
  final List<SiteLite> sites;
  final Future<void> Function(String name) onCreate;
  final Future<void> Function(int siteId, String newName) onRename;
  final Future<void> Function(int siteId) onDelete;
  const _ManageSitesDialog({
    required this.sites,
    required this.onCreate,
    required this.onRename,
    required this.onDelete,
  });

  @override
  State<_ManageSitesDialog> createState() => _ManageSitesDialogState();
}

class _ManageSitesDialogState extends State<_ManageSitesDialog> {
  final _createCtrl = TextEditingController();
  final Map<int, TextEditingController> _renameCtrls = {};

  @override
  void dispose() {
    _createCtrl.dispose();
    for (final c in _renameCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _ctrlFor(int siteId, String initial) {
    return _renameCtrls.putIfAbsent(siteId, () => TextEditingController(text: initial));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Gestion des sites'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Créer
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _createCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom du site à créer',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final name = _createCtrl.text.trim();
                  if (name.isEmpty) return;
                  widget.onCreate(name);
                },
                child: const Text('Créer'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Liste des sites
          SizedBox(
            width: 380,
            height: 260,
            child: widget.sites.isEmpty
                ? const Center(child: Text('Aucun site'))
                : ListView.builder(
              itemCount: widget.sites.length,
              itemBuilder: (ctx, i) {
                final s = widget.sites[i];
                final ctrl = _ctrlFor(s.id, s.name);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: ctrl,
                          decoration: const InputDecoration(
                            labelText: 'Nom du site',
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Renommer',
                        icon: const Icon(Icons.save),
                        onPressed: () {
                          final newName = ctrl.text.trim();
                          if (newName.isEmpty || newName == s.name) return;
                          widget.onRename(s.id, newName);
                        },
                      ),
                      IconButton(
                        tooltip: 'Supprimer',
                        icon: const Icon(Icons.delete),
                        onPressed: () => widget.onDelete(s.id),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}