import 'dart:io';
import 'package:meta/meta.dart';
import 'package:bugsnag_flutter/src/bugsnag_stackframe.dart';

/// A report for an instance of an [error] with a [rawStackTrace]. This class
/// is used to build a JSON representation of the exception for reporting to
/// Bugsnag.
class BugsnagCrashReport {
  /// The [Error] or [Exception] that was caught.
  final Object error;

  /// The [String] type of the [error].
  String get errorClass => error.runtimeType.toString();

  /// The [String] representation of the [error].
  String get message => error.toString();

  /// The raw stack trace for where the exception occurred.
  final String rawStackTrace;

  /// Converts the [rawStackTrace] to a list of [BugsnagStackframe]s.
  List<BugsnagStackframe> get stackTrace {
    return rawStackTrace.split('\n').fold<List<BugsnagStackframe>>([], (acc, line) {
      try {
        final lineExists = line?.isNotEmpty ?? false;
        final lineIsNotNestedAsyncStackTrace = line != '<asynchronous suspension>';
        if (lineExists && lineIsNotNestedAsyncStackTrace) {
          acc.add(BugsnagStackframe.fromString(line));
        }
      } catch (e) {
        print('Failed to parse frame: "$line"');
      }

      return acc;
    });
  }

  List<Map<String, dynamic>> get stackTraceAsJson =>
      stackTrace.map((s) => s.toJson()).cast<Map<String, dynamic>>().toList();

  BugsnagCrashReport({
    @required this.error,
    @required this.rawStackTrace,
  });

  /// Some errors include a more relevant stack trace within their `.toString()`
  /// output versus the stack frame that comes from a `runZoned` error response.
  /// This constructor plucks that embedded stack trace
  factory BugsnagCrashReport.fromEmbeddedStackTrace(Object error) {
    final splitException = error.toString().split('\n');
    final stackStartingLine =
        splitException.firstWhere((e) => e.startsWith('#0'), orElse: () => null);
    if (stackStartingLine == null) {
      return null;
    }

    final stackWithoutDescription =
        splitException.sublist(splitException.indexOf(stackStartingLine));

    return BugsnagCrashReport(
      error: error,
      rawStackTrace: stackWithoutDescription.join('\n'),
    );
  }

  /// Converts the [BugsnagCrashReport] to a JSON-serializable [Map].
  Map<String, dynamic> toJson() => {
        'errorClass': errorClass,
        'message': message,
        'stacktrace': stackTrace.map((f) => f.toJson()).toList(),
        'type': Platform.isIOS ? 'cocoa' : 'android',
      };
}
