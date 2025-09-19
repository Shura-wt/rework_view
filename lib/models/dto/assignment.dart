class Assignment {
  int siteId;
  String siteName;
  Set<int> selectedRoleIds;
  Set<int> initialRoleIds;
  Map<int, int> relIdByRoleId;

  Assignment({
    required this.siteId,
    required this.siteName,
    Set<int>? selected,
    Set<int>? initial,
    Map<int, int>? rel,
  })  : selectedRoleIds = selected ?? <int>{},
        initialRoleIds = initial ?? <int>{},
        relIdByRoleId = rel ?? <int, int>{};

  Assignment clone() => Assignment(
        siteId: siteId,
        siteName: siteName,
        selected: {...selectedRoleIds},
        initial: {...initialRoleIds},
        rel: {...relIdByRoleId},
      );
}
