import 'package:flutter/material.dart';
import 'package:bugsnag_flutter/bugsnag.dart';
import 'package:bugsnag_flutter/bugsnag_observer.dart';
import 'dart:async';

void main() async {
  await Bugsnag.instance.configure(
    iosApiKey: 'YOUR_API_KEY',
    androidApiKey: 'YOUR_API_KEY',
    releaseStage: 'production',
  );

  // Capture Flutter errors automatically:
  FlutterError.onError = Bugsnag.instance.recordFlutterError;

  runZonedGuarded(() {
    runApp(MyApp());
  }, (error, stackTrace) {
    Bugsnag.instance.recordError(error, stackTrace);
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: TextButton(
            child: Text('Running on'),
            onPressed: () {
              Bugsnag.instance.leaveBreadcrumb('Button Tapped',
                  type: BugsnagBreadcrumb.user);
            },
          ),
        ),
      ),
      navigatorObservers: [
        BugsnagObserver(),
      ],
    );
  }
}
