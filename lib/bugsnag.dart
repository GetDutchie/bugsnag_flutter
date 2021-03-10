import 'package:bugsnag_flutter/src/bugsnag_crash_report.dart';
import 'package:flutter/material.dart' show FlutterErrorDetails;
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

enum BugsnagBreadcrumb {
  manual,
  error,
  log,
  navigation,
  process,
  request,
  state,
  user,
}

class Bugsnag {
  /// For use with Bugsnag's `inProject` feature, this should be the name of the package where
  /// bugsnag_flutter is directly imported. For example, `my_app`.
  @protected
  String? projectPackageName;

  static const MethodChannel _channel = MethodChannel('plugins.greenbits.com/bugsnag_flutter');

  static final Bugsnag instance = Bugsnag._();

  Bugsnag._();

  /// Provision the client. This method must be called before any subsequent methods.
  /// It's recommended that this method is `await`d in `void main()` before `runApp`.
  ///
  /// [projectPackageName] should reflect the name of the package where `bugsnag_flutter`
  /// is imported.
  Future<void> configure({
    String? androidApiKey,
    String? iosApiKey,
    bool persistUser = true,
    String? releaseStage,
    String? projectPackageName,
  }) {
    instance.projectPackageName = projectPackageName;
    return _channel.invokeMethod('configure', {
      'androidApiKey': androidApiKey,
      'iosApiKey': iosApiKey,
      'persistUser': persistUser.toString(),
      'releaseStage': releaseStage,
    });
  }

  /// Notify Bugsnag of a user behavior preceeding an error
  Future<void> leaveBreadcrumb(String? message, {BugsnagBreadcrumb? type}) =>
      _channel.invokeMethod('leaveBreadcrumb', {
        'message': message ?? '',
        'type': type?.index ?? 0,
      });

  /// Log an error
  Future<void> notify({
    String? context,
    required String description,
    String? name,
    required List<Map<String, dynamic>> stackTrace,
    // Sometimes a stack trace differs from what was reported by [FlutterErrorDetails]
    // and it should still be captured
    StackTrace? additionalStackTrace,
  }) {
    var shortVersion = description;
    final splitDescription = description.split('\n');
    if (splitDescription.length > 1) {
      shortVersion = splitDescription[1];
    }

    return _channel.invokeMethod('notify', {
      'context': context ?? '',
      'description': shortVersion,
      'fullOutput': description,
      'name': name ?? splitDescription.first,
      'stackTrace': stackTrace,
      if (additionalStackTrace != null) 'additionalStackTrace': additionalStackTrace.toString(),
    });
  }

  /// Convenience method for [notify]
  Future<void> recordError(Object error, StackTrace stackTrace) {
    if (error is FlutterErrorDetails) {
      return recordFlutterError(error);
    }

    final report = BugsnagCrashReport.fromEmbeddedStackTrace(error);
    return notify(
      description: error.toString(),
      stackTrace: report?.stackTraceAsJson ?? [{}],
      additionalStackTrace: stackTrace,
    );
  }

  /// Convenience method for [notify]
  Future<void> recordFlutterError(FlutterErrorDetails error) {
    final report = BugsnagCrashReport(error: error, rawStackTrace: error.stack.toString());

    return notify(
      context: error.context?.toDescription(),
      description: error.exceptionAsString(),
      stackTrace: report.stackTraceAsJson,
      additionalStackTrace: error.stack,
    );
  }

  /// Attach user information to subsequent reports to Bugsnag
  Future<void> setUser(String id, {String? email, String? name}) =>
      _channel.invokeMethod('setUser', {
        'id': id,
        'email': email ?? '',
        'name': name ?? '',
      });
}
