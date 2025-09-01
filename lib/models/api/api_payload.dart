import '../json_utils.dart';
import '../domain/site.dart';
import '../domain/batiment.dart';
import '../domain/etage.dart';
import '../domain/baes.dart';
import '../domain/bae_status.dart';
import '../map/carte.dart';
import '../dto/user.dart';
import '../dto/role.dart';
import '../dto/relation.dart';
import '../dto/config_entry.dart';

class ApiPayload {
  // Données hiérarchiques principales
  final List<Site> sites;

  // Données additionnelles/plates (compatibles avec les routes documentées)
  final List<Batiment> batiments;
  final List<Etage> etages;
  final List<Baes> baes;
  final List<BaeStatus> statuses;
  final List<Carte> cartes;

  // Administration / configuration
  final List<User> users;
  final List<Role> roles;
  final List<Relation> relations;
  final List<ConfigEntry> config;

  ApiPayload({
    required this.sites,
    List<Batiment>? batiments,
    List<Etage>? etages,
    List<Baes>? baes,
    List<BaeStatus>? statuses,
    List<Carte>? cartes,
    List<User>? users,
    List<Role>? roles,
    List<Relation>? relations,
    List<ConfigEntry>? config,
  })  : batiments = batiments ?? const <Batiment>[],
        etages = etages ?? const <Etage>[],
        baes = baes ?? const <Baes>[],
        statuses = statuses ?? const <BaeStatus>[],
        cartes = cartes ?? const <Carte>[],
        users = users ?? const <User>[],
        roles = roles ?? const <Role>[],
        relations = relations ?? const <Relation>[],
        config = config ?? const <ConfigEntry>[];

  factory ApiPayload.fromJson(Map<String, dynamic> json) => ApiPayload(
        sites: asList(json['sites']).map((e) => Site.fromJson(asMap(e))).toList(growable: false),
        batiments: asList(json['batiments']).map((e) => Batiment.fromJson(asMap(e))).toList(growable: false),
        etages: asList(json['etages']).map((e) => Etage.fromJson(asMap(e))).toList(growable: false),
        baes: asList(json['baes']).map((e) => Baes.fromJson(asMap(e))).toList(growable: false),
        statuses: asList(json['statuses']).map((e) => BaeStatus.fromJson(asMap(e))).toList(growable: false),
        cartes: asList(json['cartes']).map((e) => Carte.fromJson(asMap(e))).toList(growable: false),
        users: asList(json['users']).map((e) => User.fromJson(asMap(e))).toList(growable: false),
        roles: asList(json['roles']).map((e) => Role.fromJson(asMap(e))).toList(growable: false),
        relations: asList(json['relations']).map((e) => Relation.fromJson(asMap(e))).toList(growable: false),
        config: asList(json['config']).map((e) => ConfigEntry.fromJson(asMap(e))).toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
        'sites': sites.map((e) => e.toJson()).toList(growable: false),
        if (batiments.isNotEmpty) 'batiments': batiments.map((e) => e.toJson()).toList(growable: false),
        if (etages.isNotEmpty) 'etages': etages.map((e) => e.toJson()).toList(growable: false),
        if (baes.isNotEmpty) 'baes': baes.map((e) => e.toJson()).toList(growable: false),
        if (statuses.isNotEmpty) 'statuses': statuses.map((e) => e.toJson()).toList(growable: false),
        if (cartes.isNotEmpty) 'cartes': cartes.map((e) => e.toJson()).toList(growable: false),
        if (users.isNotEmpty) 'users': users.map((e) => e.toJson()).toList(growable: false),
        if (roles.isNotEmpty) 'roles': roles.map((e) => e.toJson()).toList(growable: false),
        if (relations.isNotEmpty) 'relations': relations.map((e) => e.toJson()).toList(growable: false),
        if (config.isNotEmpty) 'config': config.map((e) => e.toJson()).toList(growable: false),
      };
}
