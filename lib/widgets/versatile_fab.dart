import 'package:flutter/material.dart';

/// Un widget polyvalent qui retourne un FloatingActionButton.
///
/// Objectif: n'avoir qu'un seul FAB à déclarer, tout en pouvant choisir
/// facilement le contenu (texte ou icône) et l'action au clic, avec une
/// condition d'affichage optionnelle via [showIf].
///
/// Priorité du contenu (dans l'ordre):
/// 1) [child] si fourni
/// 2) [icon] si fourni
/// 3) [label] si fourni (affiché comme texte)
///
/// Exemple d'utilisation:
///
/// VersatileFab(
///   onPressed: () { /* action */ },
///   tooltip: 'Ajouter',
///   icon: Icons.add,
///   showIf: () => true, // ou false pour masquer
/// );
///
/// VersatileFab(
///   onPressed: () { /* action */ },
///   tooltip: 'Rechercher',
///   label: 'Go',
/// );
///
/// VersatileFab(
///   onPressed: () {},
///   tooltip: 'Custom',
///   child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.star)]),
/// );
class VersatileFab extends StatelessWidget {
  const VersatileFab({
    super.key,
    required this.onPressed,
    this.tooltip,
    this.child,
    this.icon,
    this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.heroTag,
    this.mini = false,
    this.elevation,
    this.shape,
    this.showIf,
  });

  /// Fonction appelée lors du clic.
  final VoidCallback onPressed;

  /// Texte du tooltip (peut être null si non souhaité).
  final String? tooltip;

  /// Contenu personnalisé (prioritaire si fourni).
  final Widget? child;

  /// Icône à afficher si [child] n'est pas fourni.
  final IconData? icon;

  /// Texte à afficher si ni [child] ni [icon] ne sont fournis.
  final String? label;

  /// Couleur de fond du FAB.
  final Color? backgroundColor;

  /// Couleur du contenu (icône/texte).
  final Color? foregroundColor;

  /// Tag du héros pour les animations.
  final Object? heroTag;

  /// Détermine si le FAB est mini.
  final bool mini;

  /// Élévation personnalisée.
  final double? elevation;

  /// Forme personnalisée.
  final ShapeBorder? shape;

  /// Condition d'affichage: si fournie et renvoie false, le FAB n'est pas rendu.
  final bool Function()? showIf;

  @override
  Widget build(BuildContext context) {
    final bool visible = showIf?.call() ?? true;
    if (!visible) {
      return const SizedBox.shrink();
    }

    final Widget resolvedChild = child ??
        (icon != null
            ? Icon(icon)
            : (label != null
                ? Text(label!)
                : const SizedBox.shrink()));

    assert(
      child != null || icon != null || (label != null && label!.isNotEmpty),
      'VersatileFab requiert au moins un contenu: child, icon ou label non vide.',
    );

    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      heroTag: heroTag,
      mini: mini,
      elevation: elevation,
      shape: shape,
      child: resolvedChild,
    );
  }

  /// Constructeur pratique: FAB avec icône.
  factory VersatileFab.icon({
    Key? key,
    required VoidCallback onPressed,
    required IconData icon,
    String? tooltip,
    Color? backgroundColor,
    Color? foregroundColor,
    Object? heroTag,
    bool mini = false,
    double? elevation,
    ShapeBorder? shape,
    bool Function()? showIf,
  }) {
    return VersatileFab(
      key: key,
      onPressed: onPressed,
      tooltip: tooltip,
      icon: icon,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      heroTag: heroTag,
      mini: mini,
      elevation: elevation,
      shape: shape,
      showIf: showIf,
    );
  }

  /// Constructeur pratique: FAB avec texte.
  factory VersatileFab.text({
    Key? key,
    required VoidCallback onPressed,
    required String label,
    String? tooltip,
    Color? backgroundColor,
    Color? foregroundColor,
    Object? heroTag,
    bool mini = false,
    double? elevation,
    ShapeBorder? shape,
    TextStyle? style,
    bool Function()? showIf,
  }) {
    return VersatileFab(
      key: key,
      onPressed: onPressed,
      tooltip: tooltip,
      label: label,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      heroTag: heroTag,
      mini: mini,
      elevation: elevation,
      shape: shape,
      showIf: showIf,
      child: Text(label, style: style),
    );
  }
}

/// Un conteneur qui permet d'afficher une colonne de FABs (empilés verticalement).
///
/// A utiliser dans `Scaffold.floatingActionButton` pour afficher plusieurs actions.
/// Exemple:
/// floatingActionButton: VersatileFabColumn(
///   fabs: [
///     VersatileFab.icon(onPressed: () {}, icon: Icons.add, tooltip: 'Ajouter'),
///     VersatileFab.text(onPressed: () {}, label: 'Go', tooltip: 'Lancer'),
///   ],
/// )
class VersatileFabColumn extends StatelessWidget {
  const VersatileFabColumn({
    super.key,
    required this.fabs,
    this.spacing = 12,
    this.alignment = Alignment.bottomRight,
    this.padding = const EdgeInsets.only(bottom: 16, right: 16),
  });

  /// La liste des FABs à afficher (souvent des `VersatileFab`).
  final List<Widget> fabs;

  /// Espacement vertical entre chaque FAB.
  final double spacing;

  /// Alignement global dans la zone du FAB (par défaut en bas à droite).
  final Alignment alignment;

  /// Padding pour éviter les collisions avec les bords/gestures.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    if (fabs.isEmpty) return const SizedBox.shrink();

    // Filtre les FABs cachés (showIf == false) pour éviter des espaces superflus.
    final visibleFabs = <Widget>[];
    for (final w in fabs) {
      if (w is VersatileFab) {
        final bool isVisible = w.showIf?.call() ?? true;
        if (isVisible) {
          visibleFabs.add(w);
        }
      } else {
        visibleFabs.add(w);
      }
    }
    if (visibleFabs.isEmpty) return const SizedBox.shrink();

    // Construit la pile verticale avec espacement entre les boutons.
    final children = <Widget>[];
    for (var i = 0; i < visibleFabs.length; i++) {
      if (i > 0) children.add(SizedBox(height: spacing));
      children.add(visibleFabs[i]);
    }

    // SafeArea + Align pour un rendu cohérent dans le slot FAB.
    return SafeArea(
      child: Padding(
        padding: padding,
        child: Align(
          alignment: alignment,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: children,
          ),
        ),
      ),
    );
  }
}
