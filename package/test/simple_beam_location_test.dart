import 'package:flutter/material.dart';
import 'package:beamer/beamer.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final delegate = BeamerRouterDelegate(
    locationBuilder: SimpleLocationBuilder(
      routes: {
        '/': (context) => Container(),
        '/test': (context) => Container(),
      },
    ),
  );
  delegate.setNewRoutePath(Uri.parse('/'));

  group('Keys', () {
    testWidgets('each BeamPage has a differenet ValueKey', (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routeInformationParser: BeamerRouteInformationParser(),
        routerDelegate: delegate,
      ));
      delegate.beamToNamed('/test');
      await tester.pump();
      expect(delegate.currentPages.length, 2);
      final keysSet = <String>{};
      for (var page in delegate.currentPages) {
        keysSet.add((page.key as ValueKey).value);
      }
      expect(keysSet.length, equals(2));
    });
  });

  group('Query', () {
    test('location takes query', () {
      expect(delegate.currentLocation.state.queryParameters, equals({}));
      delegate.beamToNamed('/?q=t');
      expect(
          delegate.currentLocation.state.queryParameters, equals({'q': 't'}));
    });

    testWidgets('location includes query in page key', (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routeInformationParser: BeamerRouteInformationParser(),
        routerDelegate: delegate,
      ));
      expect(delegate.currentPages.last.key, isA<ValueKey>());
      expect((delegate.currentPages.last.key as ValueKey).value,
          equals(ValueKey('/?q=t').value));
    });
  });

  group('NotFound', () {
    test('can be recognized', () {
      delegate.beamToNamed('/unknown');
      expect(delegate.currentLocation, isA<NotFound>());

      delegate.beamToNamed('/test/unknown');
      expect(delegate.currentLocation, isA<NotFound>());
    });

    testWidgets('delegate builds notFoundPage', (tester) async {
      await tester.pumpWidget(MaterialApp.router(
        routeInformationParser: BeamerRouteInformationParser(),
        routerDelegate: delegate,
      ));
      expect(find.text('Not found'), findsOneWidget);
    });

    test('* in path segment will override NotFound', () {
      final delegate = BeamerRouterDelegate(
        locationBuilder: SimpleLocationBuilder(
          routes: {
            '/': (context) => Container(),
            '/test/*': (context) => Container(),
          },
        ),
      );

      delegate.beamToNamed('/test/anything');
      expect(delegate.currentLocation, isA<SimpleBeamLocation>());
    });

    test('only * will override NotFound', () {
      final delegate1 = BeamerRouterDelegate(
        locationBuilder: SimpleLocationBuilder(
          routes: {
            '/*': (context) => Container(),
          },
        ),
      );
      delegate1.setNewRoutePath(Uri.parse('/anything'));
      expect(delegate1.currentLocation, isA<SimpleBeamLocation>());

      final delegate2 = BeamerRouterDelegate(
        locationBuilder: SimpleLocationBuilder(
          routes: {
            '*': (context) => Container(),
          },
        ),
      );
      delegate2.setNewRoutePath(Uri.parse('/anything'));
      expect(delegate2.currentLocation, isA<SimpleBeamLocation>());
    });

    test('path parameters are not considered NotFound', () {
      final delegate1 = BeamerRouterDelegate(
        locationBuilder: SimpleLocationBuilder(
          routes: {
            '/test/:testId': (context) => Container(),
          },
        ),
      );
      delegate1.setNewRoutePath(Uri.parse('/test/1'));
      expect(delegate1.currentLocation, isA<SimpleBeamLocation>());
    });
  });
}
