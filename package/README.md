<p align="center">
<img src="https://raw.githubusercontent.com/slovnicki/beamer/master/resources/logo.png">
</p>

<p align="center">
<a href="https://pub.dev/packages/beamer"><img src="https://img.shields.io/pub/v/beamer.svg" alt="pub"></a>
<a href="https://codecov.io/gh/slovnicki/beamer">
<img src="https://codecov.io/gh/slovnicki/beamer/branch/master/graph/badge.svg?token=TO09CQU09C"/>
</a>
<a href="https://github.com/google/pedantic"><img src="https://dart-lang.github.io/linter/lints/style-pedantic.svg" alt="style"></a>
</p>

<p align="center">
<a href="https://github.com/slovnicki/beamer/commits/master"><img alt="GitHub commit activity" src="https://img.shields.io/github/commit-activity/m/slovnicki/beamer?label=commits"></a>
<a href="https://pub.dev/packages/beamer"><img alt="GitHub Repo stars" src="https://img.shields.io/github/stars/slovnicki/beamer"></a>
<a href="https://github.com/slovnicki/beamer/blob/master/.github/workflows/test.yml"><img alt="GitHub forks" src="https://img.shields.io/github/forks/slovnicki/beamer"></a>
</p>

<p align="center">
<a href="https://github.com/slovnicki/beamer/issues?q=is%3Aissue+is%3Aclosed"><img src="https://img.shields.io/github/issues-closed-raw/slovnicki/beamer" alt="GitHub closed issues"></a>
<a href="https://github.com/slovnicki/beamer/pulls"><img alt="GitHub closed pull requests" src="https://img.shields.io/github/issues-pr-closed-raw/slovnicki/beamer"></a>
</p>

<p align="center">
<a href="https://github.com/slovnicki/beamer/graphs/contributors"><img alt="GitHub contributors" src="https://img.shields.io/github/contributors/slovnicki/beamer"></a>
<a href="https://discord.gg/8hDJ7tP5Mz"><img src="https://img.shields.io/discord/815722893878099978" alt="Discord"></a>
</p>

<p align="center">
<a href="https://www.buymeacoffee.com/slovnicki" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="30px" width= "108px"></a>
</p>

Handle your application routing, synchronize it with browser URL and more. Beamer uses the power of Router and implements all the underlying logic for you.

---

- [Quick Start](#quick-start)
- [Key Concepts](#key-concepts)
  - [BeamLocation](#beamlocation)
  - [BeamState](#beamstate)
  - [Beaming](#beaming)
  - [Updating](#updating)
  - [Beaming Back](#beaming-back)
- [Usage](#usage)
  - [With a List of BeamLocations](#with-a-list-of-beamlocations)
  - [With a Map of Routes](#with-a-map-of-routes)
  - [Nested Navigation](#nested-navigation)
  - [General Notes](#general-notes)
  - [Web Tips](#web-tips)
- [Examples](#examples)
  - [Location Builders](#location-builders)
  - [Advanced Books](#advanced-books)
  - [Deep Location](#deep-location)
  - [Provider](#provider)
  - [Guards](#guards)
  - [Authentication Bloc](#authentication-bloc)
  - [Bottom Navigation](#bottom-navigation)
  - [Bottom Navigation Multiple Beamers](#bottom-navigation-multiple-beamers)
  - [Nested Navigation](#nested-navigation-1)
  - [Integration with Navigation UI Packages](#integration-with-navigation-ui-packages)
- [Migrating](#migrating)
  - [From 0.12 to 0.13](#from-012-to-013)
  - [From 0.11 to 0.12](#from-011-to-012)
  - [From 0.10 to 0.11](#from-010-to-011)
  - [From 0.9 to 0.10](#from-09-to-010)
  - [From 0.7 to 0.8](#from-07-to-08)
  - [From 0.4 to 0.5](#from-04-to-05)
- [Help and Chat](#help-and-chat)
- [Contributing](#contributing)

# Quick Start

The simplest setup is achieved by using the `SimpleLocationBuilder` which yields the least amount of code for a functioning application:

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routeInformationParser: BeamerParser(),
      routerDelegate: BeamerDelegate(
        locationBuilder: SimpleLocationBuilder(
          routes: {
            '/': (context) => HomeScreen(),
            '/books': (context) => BooksScreen(),
            '/books/:bookId': (context) {
              final beamState = context.currentBeamLocation.state;
              final bookId = beamState.pathParameters['bookId']!;
              // Widgets and BeamPages can be mixed!
              return BeamPage(
                key: ValueKey('book-$bookId'),
                title: 'A Book #$bookId',
                popToNamed: '/',
                type: BeamPageType.scaleTransition,
                child: BookDetailsScreen(bookId),
              );
            }
          },
        ),
      ),
    );
  }
}
```

Navigating through those routes can be done with
```dart
Beamer.of(context).beamToNamed('/books/2');
```

Accessing route attributes (for example, `bookId` for building `BookDetailsScreen`) can be done with
```dart
Beamer.of(context).currentBeamLocation.state.pathParameters['bookId'];
```

Passing additional arbitrary attributes that don't contribute to URI can be done via `data`;
```dart
Beamer.of(context).beamToNamed(
  '/book/2',
  data: {
    'note': 'this is my favorite book',
    'color': Colors.blue,
  },
);
```

For those who wish to have a full control over building a page stack, we now introduce some key concepts; `BeamLocation` and `BeamState`.

# Key Concepts

At the highest level, `Beamer` is a wrapper for `Router` and uses its own implementations for `RouterDelegate` and `RouteInformationParser`. The goal of beamer is to separate the responsibility of building a page stack for `Navigator.pages` into multiple classes with custom "states", instead of one global state.

For example, we would like to handle all the profile related page stacks such as

- `[ ProfilePage ]`,
- `[ ProfilePage, FriendsPage]`,
- `[ ProfilePage, FriendsPage, FriendPage ]`,
- `[ ProfilePage, SettingsPage ]`,
- ...

with some "ProfileHandler" that knows which "state" corresponds to which page stack and updates this state as the page stack changes. Then similarly, we would like to have a "ShopHandler" for all the possible stacks of shop related pages such as

- `[ ShopPage ]`,
- `[ ShopPage, CategoriesPage ]`,
- `[ ShopPage, CategoriesPage, ItemsPage ]`,
- `[ ShopPage, CategoriesPage, ItemsPage, ItemPage ]`,
- `[ ShopPage, ItemsPage, ItemPage ]`,
- `[ ShopPage, CartPage ]`,
- ...

These "Handlers" are called `BeamLocation`s.

`BeamLocation`s cannot work by themselves. When the `URI` comes into the app through deep-link, or as initial, there must be a decision which `BeamLocation` will further handle this `URI` and build pages for the `Navigator`. This is the job of `BeamerDelegate.locationBuilder` that will take the "global state" and give it to appropriate `BeamLocation` which will create and save its own "local state" from it to use it to build pages.

## BeamLocation

The most important construct in Beamer is a `BeamLocation` which represents a stack of one or more pages.  
`BeamLocation` has **3 important roles**:

- know which URIs it can handle: `pathBlueprints`
- know how to build a stack of pages: `buildPages`
- keep a `state` that provides a link between the first 2

`BeamLocation` is an abstract class which needs to be extended. The purpose of having multiple `BeamLocation`s is to architecturally separate unrelated "places" in an application.

For example, `BooksLocation` can handle all the pages related to books and `ArticlesLocation` everything related to articles. In the light of this scoping, `BeamLocation` also has a `builder` for wrapping an entire stack of its pages with some `Provider` so the similar data can be shared between similar pages.

This is an example of `BeamLocation`:

```dart
class BooksLocation extends BeamLocation {
  BooksLocation(BeamState state) : super(state);

  @override
  List<String> get pathBlueprints => ['/books/:bookId'];

  @override
  List<BeamPage> buildPages(BuildContext context, BeamState state) => [
        BeamPage(
          key: ValueKey('home'),
          child: HomeScreen(),
        ),
        if (state.uri.pathSegments.contains('books'))
          BeamPage(
            key: ValueKey('books'),
            child: BooksScreen(),
          ),
        if (state.pathParameters.containsKey('bookId'))
          BeamPage(
            key: ValueKey('book-${state.pathParameters['bookId']}'),
            child: BookDetailsScreen(
              bookId: state.pathParameters['bookId'],
            ),
          ),
      ];
}
```

## BeamState

This is the above-mentioned `state` of `BeamLocation`. Its role is to keep various URI attributes such as `pathBlueprintSegments` (the segments of chosen pathBlueprint, as each `BeamLocation` supports many of those), `pathParameters`, `queryParameters` and arbitrary key-value `data`. Those attributes are important while building pages and for `BeamState` to create an `uri` that will be consumed by the browser.

Besides purely imperative navigation via e.g. `beamToNamed('/books/3')`, this also provides a method to have declarative navigation by changing the `state` of `BeamLocation`. For example:

```dart
Beamer.of(context).currentBeamLocation.update(
  (state) => state.copyWith(
    pathBlueprintSegments: ['books', ':bookId'],
    pathParameters: {'bookId': '3'},
  ),
),
```

`BeamState` can be extended with a completely custom state which can be used for `BeamLocation`, for example:

```dart
class BooksLocation extends BeamLocation<MyState> {...}
```

It is important in this case that `MyState` has an `uri` getter which is needed for browser's URL bar.

## Beaming

Navigating between or within `BeamLocation`s is achieved by "beaming". You can think of it as teleporting (_beaming_) to another place in your app. Similar to `Navigator.of(context).pushReplacementNamed('/my-route')`, but Beamer is not limited to a single page, nor to a push per se. `BeamLocation`s hold an arbitrary stack of pages that get built when you beam there. Using Beamer can feel like using many of `Navigator`'s `push/pop` methods at once.

Examples of beaming:

```dart
Beamer.of(context).beamTo(MyLocation());

// or with an extension on BuildContext
context.beamTo(MyLocation());
```

```dart
context.beamToNamed('/books/2');

// this is equivalent to
context.beamTo(
  BooksLocation(
    BeamState(
      pathBlueprintSegments: ['books', ':bookId'],
      pathParameters: {'bookId': '2'},
    ),
  ),
),
```

```dart
context.beamToNamed(
  '/book/2',
  data: {'note': 'this is my favorite book'},
);
```

## Updating

Once at a `BeamLocation`, it is preferable to update the current location's state. For example, for going from `/books` to `/books/3` (which are both handled by `BooksLocation`):
```dart
context.currentBeamLocation.update(
  (state) => state.copyWith(
    pathBlueprintSegments: ['books', ':bookId'],
    pathParameters: {'bookId': '3'},
  ),
),
```

To get from one `BeamLocation`'s stack to another `BeamLocation`'s stack, an `update` can be invoked on `BeamerDelegate` itself:
```dart
Beamer.of(context).update(
  state: BeamState(
    pathBlueprintSegments: ['articles', ':articleId'],
    pathParameters: {'articleId': '1'},
  ),
);
```

**NOTE** that every beaming function (`beamTo`, `beamToNamed`,...) will have the same effect as `update` either on `BeamLocation` or on `BeamerDelegate`.

## Beaming Back

**NOTE:** Navigating to previous page in a page stack is done via `Navigator.of(context).pop()`. This is also what the default `AppBar`'s `BackButton` will call. If you beamed to the current page stack from some _different_ page stack, then consider `beamBack` to return to your previous configuration.

All `BeamState`s that were visited are kept in `beamStateHistory`. Therefore, there is an ability to beam back to whichever `BeamLocation` is responsible for previous `BeamState`. For example, after spending some time on `/books` and `/books/3`, say you beam to `/articles`. From there, you can get back to your previous location as it were when you left, i.e. `/books/3`.

```dart
context.beamBack();
```

**NOTE** that Beamer can integrate Android's back button to do `beamBack` if possible when all the pages from current `BeamLocation` have been popped. This is achieved by setting a back button dispatcher in `MaterialApp.router`.

```dart
backButtonDispatcher: BeamerBackButtonDispatcher(delegate: routerDelegate)
```

# Usage

To use the full-featured Beamer in your app, you must (as per [official documentation](https://api.flutter.dev/flutter/widgets/Router-class.html)) construct your `*App` widget with `.router` constructor to which (along with all your regular `*App` attributes) you provide

- `routeInformationParser` that parses an incoming URI.
- `routerDelegate` that controls (re)building of `Navigator`

Here you use the Beamer implementation of those - `BeamerParser` and `BeamerDelegate`, to which you pass your `LocationBuilder`.  

In the simplest form, `LocationBuilder` is just a function which takes the current `BeamState` and returns a custom `BeamLocation` based on the URI or other state properties.

```dart
class MyApp extends StatelessWidget {
  final routerDelegate = BeamerDelegate(
    locationBuilder: (state) {
      if (state.uri.pathSegments.contains('books')) {
        return BooksLocation(state);
      }
      return HomeLocation(state);
    },
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerDelegate: routerDelegate,
      routeInformationParser: BeamerParser(),
      backButtonDispatcher:
          BeamerBackButtonDispatcher(delegate: routerDelegate),
    );
  }
}
```

There are also two other options available, if you don't want to define a custom `LocationBuilder` function.

## With a List of BeamLocations

You can use the `BeamerLocationBuilder` with a list of `BeamLocation`s. This builder will automatically select the correct location, based on the `pathBlueprints` of each `BeamLocation`. In this case, define your `BeamerDelegate` like this:

```dart
final routerDelegate = BeamerDelegate(
  locationBuilder: BeamerLocationBuilder(
    beamLocations: [
      HomeLocation(),
      BooksLocation(),
    ],
  ),
);
```

## With a Map of Routes

You can use the `SimpleLocationBuilder` with a map of routes and `WidgetBuilder`s, as mentioned in [Quick Start](#quick-start). This completely removes the need for custom `BeamLocation`s, but also gives you the least amount of customizability. Still, wildcards and path parameters in your paths are supported as with all the other options.

```dart
final routerDelegate = BeamerDelegate(
  locationBuilder: SimpleLocationBuilder(
    routes: {
      '/': (context) => HomeScreen(),
      '/books': (context) => BooksScreen(),
      '/books/:bookId': (context) => BookDetailsScreen(
        bookId: context.currentBeamLocation.state.pathParameters['bookId'],
      ),
    },
  ),
);
```

## Nested Navigation

When nested navigation is needed, you can just put `Beamer` anywhere in the Widget tree where this navigation will take place. There is no limit on how many `Beamer`s an app can have. Common use case is a bottom navigation bar ([see example](#bottom-navigation)), something like this:

```dart
class MyApp extends StatelessWidget {
  final routerDelegate = BeamerDelegate(
    initialPath: '/books',
    locationBuilder: SimpleLocationBuilder(
      routes: {
        '/*': (context) {
          final beamerKey = GlobalKey<BeamerState>();

          return Scaffold(
            body: Beamer(
              key: beamerKey,
              routerDelegate: BeamerDelegate(
                locationBuilder: BeamerLocationBuilder(
                  beamLocations: [
                    BooksLocation(),
                    ArticlesLocation(),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: BottomNavigationBarWidget(
              beamerKey: beamerKey,
            ),
          );
        }
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerDelegate: routerDelegate,
      routeInformationParser: BeamerParser(),
    );
  }
}
```

## General Notes

- When extending `BeamLocation`, two methods need to be implemented: `pathBlueprints` and `buildPages`.
  - `buildPages` returns a stack of pages that will be built by `Navigator` when you beam there, and `pathBlueprints` is there for Beamer to decide which `BeamLocation` corresponds to which URI.
  - `BeamLocation` keeps query and path parameters from URI in its `BeamState`. The `:` is necessary in `pathBlueprints` if you _might_ get path parameter from browser.

- `BeamPage`'s child is an arbitrary `Widget` that represents your app screen / page.
  - `key` is important for `Navigator` to optimize rebuilds. This should be a unique value for "page state".
  - `BeamPage` creates `MaterialPageRoute` by default, but other transitions can be chosen by setting `BeamPage.type` to one of available `BeamPageType`.

**NOTE** that "Navigator 1.0" can be used alongside Beamer. You can easily `push` or `pop` pages with `Navigator.of(context)`, but those will not be contributing to the URI. This is often needed when some info/helper page needs to be shown that doesn't influence the browser's URL. And of course, when using Beamer on mobile, this is a non-issue as there is no URL.

## Web Tips

- removing the `#` from URL can be done by calling `Beamer.setPathUrlStrategy()` before `runApp()`.
- `BeamPage.title` is used for setting the browser tab title by default and can be opt-out by setting `BeamerDelegate.setBrowserTabTitle` to `false`.

# Examples

Check out all examples [here](https://github.com/slovnicki/beamer/tree/master/examples).

## Location Builders

Here is a recreation of the example app from [this article](https://medium.com/flutter/learning-flutters-new-navigation-and-routing-system-7c9068155ade) where you can learn a lot about Navigator 2.0. 
It contains three different options of building the locations. The full code is available [here](https://github.com/slovnicki/beamer/tree/master/examples/location_builders).

<p align="center">
<img src="https://raw.githubusercontent.com/slovnicki/beamer/master/examples/location_builders/example-location-builders.gif" alt="example-location-builders">

## Advanced Books

For a step further, we add more flows to demonstrate the power of Beamer. The full code is available [here](https://github.com/slovnicki/beamer/tree/master/examples/advanced_books).

<p align="center">
<img src="https://raw.githubusercontent.com/slovnicki/beamer/master/examples/advanced_books/example-advanced-books.gif" alt="example-advanced-books">

## Deep Location

You can instantly beam to a location in your app that has many pages stacked (deep linking) and then pop them one by one or simply `beamBack` to where you came from. The full code is available [here](https://github.com/slovnicki/beamer/tree/master/examples/deep_location). Note that `beamBackOnPop` parameter of `beamToNamed` might be useful here to override `AppBar`'s `pop` with `beamBack`.

<p align="center">
<img src="https://raw.githubusercontent.com/slovnicki/beamer/master/examples/deep_location/example-deep-location.gif" alt="example-deep-location">

```dart
ElevatedButton(
    onPressed: () => context.beamToNamed('/a/b/c/d'),
    //onPressed: () => context.beamToNamed('/a/b/c/d', beamBackOnPop: true),
    child: Text('Beam deep'),
),
```

## Provider

You can override `BeamLocation.builder` to provide some data to the entire location, i.e. to all the `pages`. The full code is available [here](https://github.com/slovnicki/beamer/tree/master/examples/provider).

<p align="center">
<img src="https://raw.githubusercontent.com/slovnicki/beamer/master/examples/provider/example-provider.gif" alt="example-provider">

```dart
// In your location implementation
@override
Widget builder(BuildContext context, Navigator navigator) {
  return MyProvider<MyObject>(
    create: (context) => MyObject(),
    child: navigator,
  );
}
```

## Guards

You can define global guards (for example, authentication guard) or location guards that keep a specific location safe. The full code is available [here](https://github.com/slovnicki/beamer/tree/master/examples/guards).

<p align="center">
<img src="https://raw.githubusercontent.com/slovnicki/beamer/master/examples/guards/example-guards.gif" alt="example-guards">

- Global Guards

```dart
BeamerDelegate(
  guards: [
    // Redirect to /login if the user is not authenticated:
    BeamGuard(
      pathBlueprints: ['/books*'],
      check: (context, location) => context.isAuthenticated,
      beamToNamed: '/login',
    ),
  ],
  ...
),
```

- Location (local) Guards

```dart
// in your location implementation
@override
List<BeamGuard> get guards => [
  // Show forbiddenPage if the user tries to enter books/2:
  BeamGuard(
    pathBlueprints: ['/books/*'],
    check: (context, location) => location.pathParameters['bookId'] != '2',
    showPage: forbiddenPage,
  ),
];
```

## Authentication Bloc

Here is an example on how to use `BeamGuard`s for an authentication flow. It uses [flutter_bloc](https://pub.dev/packages/flutter_bloc) for state management. The code is available [here](https://github.com/slovnicki/beamer/tree/master/examples/authentication_bloc).

<p align="center">
<img src="https://raw.githubusercontent.com/slovnicki/beamer/master/examples/authentication_bloc/example-authentication-bloc.gif" alt="example-authentication-bloc">

## Bottom Navigation

An examples of putting `Beamer` into the Widget tree is when using a bottom navigation bar. The code is available [here](https://github.com/slovnicki/beamer/tree/master/examples/bottom_navigation).

<p align="center">
<img src="https://raw.githubusercontent.com/slovnicki/beamer/master/examples/bottom_navigation/example-bottom-navigation.gif" alt="example-bottom-navigation">

## Bottom Navigation Multiple Beamers

The code for the bottom navigation example app with multiple beamers is available [here](https://github.com/slovnicki/beamer/tree/master/examples/bottom_navigation_multiple_beamers)

<p align="center">
<img src="https://raw.githubusercontent.com/slovnicki/beamer/master/examples/bottom_navigation_multiple_beamers/example-bottom-navigation-multiple-beamers.gif" alt="example-bottom-navigation-multiple-beamers">

## Nested Navigation

The code for the nested navigation example app is available [here](https://github.com/slovnicki/beamer/tree/master/examples/nested_navigation)

<p align="center">
<img src="https://raw.githubusercontent.com/slovnicki/beamer/master/examples/nested_navigation/example-nested-navigation.gif" alt="example-nested-navigation" width="520">

## Integration with Navigation UI Packages

- [Animated Rail Example](https://github.com/slovnicki/beamer/tree/master/examples/animated_rail), with [animated_rail](https://pub.dev/packages/animated_rail) package.
- ... (Contributions are very welcome! Add your suggestion [here](https://github.com/slovnicki/beamer/issues/79) or make a PR.)

<img src="https://raw.githubusercontent.com/slovnicki/beamer/master/examples/animated_rail/example-animated-rail.gif" alt="example-animated-rail" width="240">

# Migrating

## From 0.12 to 0.13

- rename `BeamerRouterDelegate` to `BeamerDelegate`
- rename `BeamerRouteInformationParser` to `BeamerParser`
- rename `pagesBuilder` to `buildPages`
- rename `Beamer.of(context).currentLocation` to `Beamer.of(context).currentBeamLocation`

## From 0.11 to 0.12

- There's no `RootRouterDelegate` anymore. Just rename it to `BeamerDelegate`. If you were using its `homeBuilder`, use `SimpleLocationBuilder` and  then `routes: {'/': (context) => HomeScreen()}`.
- Behavior of `beamBack` was changed to go to previous `BeamState`, not `BeamLocation`. If this is not what you want, use `popBeamLocation()` that has the same behavior as old `beamback`.

## From 0.10 to 0.11

- `BeamerDelegate.beamLocations` is now `locationBuilder`. See `BeamerLocationBuilder` for easiest migration.
- `Beamer` now takes `BeamerDelegate`, not `BeamLocations` directly
- `buildPages` now also brings `state`

## From 0.9 to 0.10

- `BeamLocation` constructor now takes only `BeamState state`. (there's no need to define special constructors and call `super` if you use `beamToNamed`)
- most of the attributes that were in `BeamLocation` are now in `BeamLocation.state`. When accessing them through `BeamLocation`:
  - `pathParameters` is now `state.pathParameters`
  - `queryParameters` is now `state.queryParameters`
  - `data` is now `state.data`
  - `pathSegments` is now `state.pathBlueprintSegments`
  - `uri` is now `state.uri`

## From 0.7 to 0.8

- rename `pages` to `buildPages` in `BeamLocation`s
- pass `beamLocations` to `BeamerDelegate` instead of `BeamerParser`. See [Usage](#usage)
## From 0.4 to 0.5

- instead of wrapping `MaterialApp` with `Beamer`, use `*App.router()`
- `String BeamLocation.pathBlueprint` is now `List<String> BeamLocation.pathBlueprints`
- `BeamLocation.withParameters` constructor is removed and all parameters are handled with 1 constructor. See example if you need `super`.
- `BeamPage.page` is now called `BeamPage.child`

# Help and Chat

For any problems, questions, suggestions, fun,... join us at Discord <a href="https://discord.gg/8hDJ7tP5Mz"><img src="https://img.shields.io/discord/815722893878099978" alt="Discord"></a>

# Contributing

This package is still in early stages. To see the upcoming features, check the [Issue board](https://github.com/slovnicki/beamer/issues).

If you notice any bugs not present in issues, please file a new issue. If you are willing to fix or enhance things yourself, you are very welcome to make a pull request. Before making a pull request:

- if you wish to solve an existing issue, please let us know in issue comments first.
- if you have another enhancement in mind, create an issue for it first, so we can discuss your idea.

Also, you can <a href="https://www.buymeacoffee.com/slovnicki" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="20px" width= "72px"></a> to speed up the development.
