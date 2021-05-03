import 'package:flutter/widgets.dart';

import './beam_location.dart';
import './beam_page.dart';

/// A guard for [BeamLocation]s.
///
/// Responsible for checking whether current location is allowed to be drawn
/// on screen and providing steps to be executed following a failed check.
class BeamGuard {
  BeamGuard({
    required this.pathBlueprints,
    required this.check,
    this.onCheckFailed,
    this.beamTo,
    this.beamToNamed,
    this.showPage,
    this.guardNonMatching = false,
    this.replaceCurrentStack = true,
  }) : assert(beamTo != null || beamToNamed != null || showPage != null);

  /// A list of path strings that are to be guarded.
  ///
  /// Asterisk wildcard is supported to denote "anything".
  ///
  /// For example, '/books/*' will match '/books/1', '/books/2/genres', etc.
  /// but will not match '/books'. To match '/books' and everything after it,
  /// use '/books*'.
  ///
  /// See [_hasMatch] for more details.
  List<String> pathBlueprints;

  /// What check should guard perform on a given [location], the one that is
  /// being tried beaming to.
  ///
  /// [context] is also injected to fetch data up the tree if necessary.
  bool Function(BuildContext context, BeamLocation location) check;

  /// Arbitrary close to execute when [check] fails.
  ///
  /// This will run before and regardless of [beamTo] or [showPage].
  void Function(BuildContext context, BeamLocation location)? onCheckFailed;

  /// If guard [check] returns false, build a location to be beamed to.
  ///
  /// [showPage] has precedence over this attribute.
  BeamLocation Function(BuildContext context)? beamTo;

  /// If guard [check] returns false, beam to this uri.
  ///
  /// [showPage] has precedence over this attribute.
  String? beamToNamed;

  /// If guard [check] returns false, put this page onto navigation stack.
  ///
  /// When using [showPage], you probably want [replaceCurrentStack] set to `false`.
  ///
  /// This has precedence over [beamTo] and [beamToNamed].
  BeamPage? showPage;

  /// Whether or not [location]s matching the [pathBlueprint]s will be blocked,
  /// or all other [location]s that don't match the [pathBlueprint]s will be.
  bool guardNonMatching;

  /// Whether or not to replace the current location's stack of pages;
  /// the one that is yielding a `false` [check] upon being beamed to.
  final bool replaceCurrentStack;

  /// Matches [location]'s pathBlueprint to [pathBlueprints].
  ///
  /// If asterisk is present, it is enough that the pre-asterisk substring is
  /// contained within location's pathBlueprint.
  /// Else, they must be equal.
  bool _hasMatch(BeamLocation location) {
    for (var pathBlueprint in pathBlueprints) {
      final asteriskIndex = pathBlueprint.indexOf('*');
      if (asteriskIndex != -1) {
        if (location.state.uri
            .toString()
            .contains(pathBlueprint.substring(0, asteriskIndex))) {
          return true;
        }
      } else {
        if (pathBlueprint == location.state.uri.toString()) {
          return true;
        }
      }
    }
    return false;
  }

  /// Whether or not the guard should check access to the [location].
  bool shouldGuard(BeamLocation location) {
    return guardNonMatching ? !_hasMatch(location) : _hasMatch(location);
  }
}
