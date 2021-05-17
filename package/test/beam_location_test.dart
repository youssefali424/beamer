import 'package:beamer/beamer.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter_test/flutter_test.dart';

import 'test_locations.dart';

void main() {
  final location2 = Location2(BeamState(pathBlueprintSegments: ['l2', ':id']));
  group('prepare', () {
    test('BeamLocation can create valid URI', () {
      location2.state = location2.state.copyWith(
        pathParameters: {'id': '42'},
        queryParameters: {'q': 'xxx'},
      );
      expect(location2.state.uri.toString(), '/l2/42?q=xxx');
    });
  });

  group('NotFound', () {
    testWidgets('has "empty" function overrides, but has a state',
        (tester) async {
      BuildContext? testContext;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            testContext = context;
            return Container();
          },
        ),
      );

      final notFound = NotFound(path: '/test');
      expect(notFound.pathBlueprints, []);
      expect(notFound.buildPages(testContext!, BeamState()), []);
      expect(notFound.state.uri.toString(), '/test');
    });
  });

  group('EmptyBeamLocation', () {
    testWidgets('has "empty" function overrides', (tester) async {
      BuildContext? testContext;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            testContext = context;
            return Container();
          },
        ),
      );

      final notFound = EmptyBeamLocation();
      expect(notFound.pathBlueprints, []);
      expect(notFound.buildPages(testContext!, BeamState()), []);
    });
  });
}
