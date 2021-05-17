import 'package:beamer/beamer.dart';

abstract class Utils {
  /// Traverses [beamLocations] and returns the one whose one of
  /// `pathBlueprints` contains the [uri], ignoring concrete path parameters.
  ///
  /// Upon finding such [BeamLocation], configures it with
  /// `pathParameters` and `queryParameters` from [uri].
  ///
  /// If [beamLocations] don't contain a match, [NotFound] will be returned
  /// configured with [uri].
  static BeamLocation chooseBeamLocation(
    Uri uri,
    List<BeamLocation> beamLocations, {
    Map<String, dynamic> data = const <String, dynamic>{},
  }) {
    for (var beamLocation in beamLocations) {
      if (canBeamLocationHandleUri(beamLocation, uri)) {
        return beamLocation
          ..state = beamLocation.createState(
            BeamState(
              pathBlueprintSegments: uri.pathSegments,
              queryParameters: uri.queryParameters,
              data: data,
            ),
          );
      }
    }
    return NotFound(path: uri.path);
  }

  /// Can a [beamLocation], depending on its `pathBlueprints`, handle the [uri].
  ///
  /// Used in [BeamLocation.canHandle] and [chooseBeamLocation].
  static bool canBeamLocationHandleUri(BeamLocation beamLocation, Uri uri) {
    for (var pathBlueprint in beamLocation.pathBlueprints) {
      if (pathBlueprint == uri.path || pathBlueprint == '/*') {
        return true;
      }
      final uriPathSegments = List.from(uri.pathSegments);
      if (uriPathSegments.length > 1 && uriPathSegments.last == '') {
        uriPathSegments.removeLast();
      }
      final beamLocationPathBlueprintSegments =
          Uri.parse(pathBlueprint).pathSegments;
      if (uriPathSegments.length > beamLocationPathBlueprintSegments.length &&
          !beamLocationPathBlueprintSegments.contains('*')) {
        continue;
      }
      var checksPassed = true;
      for (int i = 0; i < uriPathSegments.length; i++) {
        if (beamLocationPathBlueprintSegments[i] == '*') {
          checksPassed = true;
          break;
        }
        if (uriPathSegments[i] != beamLocationPathBlueprintSegments[i] &&
            beamLocationPathBlueprintSegments[i][0] != ':') {
          checksPassed = false;
          break;
        }
      }
      if (checksPassed) {
        return true;
      }
    }
    return false;
  }

  /// Creates a state for [BeamLocation] based on incoming [uri].
  ///
  /// Used in [BeamState.copyForLocation].
  static BeamState createBeamState(
    Uri uri, {
    BeamLocation? beamLocation,
    Map<String, dynamic> data = const <String, dynamic>{},
  }) {
    if (beamLocation != null) {
      for (var pathBlueprint in beamLocation.pathBlueprints) {
        if (pathBlueprint == uri.path || pathBlueprint == '/*') {
          BeamState(
            pathBlueprintSegments: uri.pathSegments,
            queryParameters: uri.queryParameters,
            data: data,
          );
        }
        final uriPathSegments = List.from(uri.pathSegments);
        if (uriPathSegments.length > 1 && uriPathSegments.last == '') {
          uriPathSegments.removeLast();
        }
        final beamLocationPathBlueprintSegments =
            Uri.parse(pathBlueprint).pathSegments;
        var pathSegments = <String>[];
        var pathParameters = <String, String>{};
        if (uriPathSegments.length > beamLocationPathBlueprintSegments.length &&
            !beamLocationPathBlueprintSegments.contains('*')) {
          continue;
        }
        var checksPassed = true;
        for (int i = 0; i < uriPathSegments.length; i++) {
          if (beamLocationPathBlueprintSegments[i] == '*') {
            pathSegments = List<String>.from(uriPathSegments);
            checksPassed = true;
            break;
          }
          if (uriPathSegments[i] != beamLocationPathBlueprintSegments[i] &&
              beamLocationPathBlueprintSegments[i][0] != ':') {
            checksPassed = false;
            break;
          } else if (beamLocationPathBlueprintSegments[i][0] == ':') {
            pathParameters[beamLocationPathBlueprintSegments[i].substring(1)] =
                uriPathSegments[i];
            pathSegments.add(beamLocationPathBlueprintSegments[i]);
          } else {
            pathSegments.add(uriPathSegments[i]);
          }
        }
        if (checksPassed) {
          return BeamState(
            pathBlueprintSegments: pathSegments,
            pathParameters: pathParameters,
            queryParameters: uri.queryParameters,
            data: data,
          );
        }
      }
    }
    return BeamState(
      pathBlueprintSegments: uri.pathSegments,
      queryParameters: uri.queryParameters,
      data: data,
    );
  }

  static bool urisMatch(Uri blueprint, Uri exact) {
    final blueprintSegments = blueprint.pathSegments;
    final exactSegment = exact.pathSegments;
    if (blueprintSegments.length != exactSegment.length) {
      return false;
    }
    for (int i = 0; i < blueprintSegments.length; i++) {
      if (blueprintSegments[i].startsWith(':')) {
        continue;
      }
      if (blueprintSegments[i] != exactSegment[i]) {
        return false;
      }
    }
    return true;
  }
}
