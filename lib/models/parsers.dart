import 'dart:convert';
import 'json_utils.dart';
import 'domain/baes.dart';
import 'domain/bae_status.dart';
import 'domain/batiment.dart';
import 'domain/site.dart';
import 'map/carte.dart';
import 'api/api_payload.dart';
import 'dto/config_entry.dart';
import 'dto/role.dart';
import 'dto/etage_lite.dart';
import 'dto/site_lite.dart';
import 'dto/relation.dart';
import 'dto/user.dart';

// Objet racine complet
ApiPayload apiPayloadFromJsonString(String source) =>
    ApiPayload.fromJson(jsonDecode(source) as Map<String, dynamic>);
String apiPayloadToJsonString(ApiPayload payload) =>
    jsonEncode(payload.toJson());

// Listes BAES
List<Baes> baesListFromJsonString(String source) =>
    asList(jsonDecode(source))
        .map((e) => Baes.fromJson(asMap(e)))
        .toList(growable: false);
String baesListToJsonString(List<Baes> items) =>
    jsonEncode(items.map((e) => e.toJson()).toList(growable: false));

// Statuts
List<BaeStatus> baesStatusListFromJsonString(String source) =>
    asList(jsonDecode(source))
        .map((e) => BaeStatus.fromJson(asMap(e)))
        .toList(growable: false);
BaeStatus latestStatusFromJsonString(String source) =>
    BaeStatus.fromJson(asMap(jsonDecode(source)));

// Batiments
List<Batiment> batimentsListFromJsonString(String source) =>
    asList(jsonDecode(source))
        .map((e) => Batiment.fromJson(asMap(e)))
        .toList(growable: false);

// Carte
Carte carteFromJsonString(String source) =>
    Carte.fromJson(asMap(jsonDecode(source)));

// Config / Rôles / Étages / Sites / Relations / Users
List<ConfigEntry> configListFromJsonString(String source) =>
    asList(jsonDecode(source))
        .map((e) => ConfigEntry.fromJson(asMap(e)))
        .toList(growable: false);
List<Role> rolesFromJsonString(String source) =>
    asList(jsonDecode(source))
        .map((e) => Role.fromJson(asMap(e)))
        .toList(growable: false);
List<EtageLite> etagesLiteFromJsonString(String source) =>
    asList(jsonDecode(source))
        .map((e) => EtageLite.fromJson(asMap(e)))
        .toList(growable: false);
List<SiteLite> sitesLiteFromJsonString(String source) =>
    asList(jsonDecode(source))
        .map((e) => SiteLite.fromJson(asMap(e)))
        .toList(growable: false);
List<Relation> relationsFromJsonString(String source) =>
    asList(jsonDecode(source))
        .map((e) => Relation.fromJson(asMap(e)))
        .toList(growable: false);
List<User> usersFromJsonString(String source) =>
    asList(jsonDecode(source))
        .map((e) => User.fromJson(asMap(e)))
        .toList(growable: false);
// alias
List<SiteLite> userSitesFromJsonString(String source) => sitesLiteFromJsonString(source);
