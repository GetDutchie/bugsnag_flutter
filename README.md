# Bugsnag Flutter

Native bindings to the Bugsnag SDK. **Android is still experimental**.

## Setup

```dart
void main() async {
  await Bugsnag.instance.configure(iosApiKey: 'YOUR_API_KEY', androidApiKey: 'YOUR_API_KEY', releaseStage: 'production');

  // Capture Flutter errors automatically:
  FlutterError.onError = Bugsnag.instance.recordFlutterError;

  runZonedGuarded(() {
    runApp(MyApp());
  }, (error, stackTrace) {
    Bugsnag.instance.recordError(error, stackTrace);
  });
}
```

:warning: Because error reporting occurs in Flutter and not in the native code where Bugsnag expects to report the error from, the stack trace is recreated using Flutter's reports. The parsing can occaisionally drop full file paths, so a complete output of the errors thrown are reported to a custom "Flutter" tab on the Bugsnag report.

## Breadcrumbs

To better debug a crash, [breadcrumbs can be transmitted to Bugsnag](https://docs.bugsnag.com/platforms/ios/customizing-breadcrumbs/). Some are captured by default, but Flutter interactions are not. To track screens, use the built-in observer:

```dart
import 'package:bugsnag_flutter/bugsnag_observer.dart';

MaterialApp(
  // ...your material config...
  home: HomeScreen(),
  navigatorObservers: [
    BugsnagObserver(),
  ],
);
```

Or log specific events:

```dart
FlatButton(
  onTap: () {
    Bugsnag.instance.leaveBreadcrumb('Button Tapped', type: BugsnagBreadcrumb.user);
  }
);
```
