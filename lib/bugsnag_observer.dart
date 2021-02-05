import 'package:bugsnag_flutter/bugsnag.dart';
import 'package:flutter/widgets.dart';

class BugsnagObserver extends RouteObserver<PageRoute<dynamic>> {
  /// Creates a [NavigatorObserver] that sends breadcrumbs to [Bugsnag].
  /// Heavily inspired and borrowed from [FirebaseAnalyticsObserver].
  ///
  /// When a route is pushed or popped, [nameExtractor] is used to extract a
  /// name from [RouteSettings] of the now active route and that name is sent to
  /// Firebase. Defaults to `defaultNameExtractor`.
  ///
  /// If a [PlatformException] is thrown while the observer attempts to send the
  /// active route to [analytics], `onError` will be called with the
  /// exception. If `onError` is omitted, the exception will be printed using
  /// `debugPrint()`.
  BugsnagObserver();

  void _sendScreenView(PageRoute<dynamic> route, {String action = 'On'}) {
    final screenName = route?.settings?.name;
    if (screenName != null) {
      Bugsnag.instance.leaveBreadcrumb('$action $screenName', type: BugsnagBreadcrumb.navigation);
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) {
      _sendScreenView(route, action: 'Pushed from ${previousRoute?.settings?.name} to');
    }
  }

  @override
  void didReplace({Route<dynamic> newRoute, Route<dynamic> oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute is PageRoute) {
      _sendScreenView(newRoute, action: 'Replaced ${oldRoute?.settings?.name} with');
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic> previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute is PageRoute && route is PageRoute) {
      _sendScreenView(previousRoute, action: 'Popped from ${previousRoute?.settings?.name} to');
    }
  }
}
