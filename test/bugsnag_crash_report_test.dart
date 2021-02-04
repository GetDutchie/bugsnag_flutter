import 'package:bugsnag_flutter/src/bugsnag_crash_report.dart';
import 'package:flutter_test/flutter_test.dart';

const stackTrace = '''
#0      main (package:herer/main_development.dart:7:5)
<asynchronous suspension>
#1      _runMainZoned.<anonymous closure>.<anonymous closure> (dart:ui/hooks.dart:189:25)
#2      _rootRun (dart:async/zone.dart:1124:13)
#3      _CustomZone.run (dart:async/zone.dart:1021:19)
#4      _runZoned (dart:async/zone.dart:1516:10)
#5      runZoned (dart:async/zone.dart:1500:12)
#6      _runMainZoned.<anonymous closure> (dart:ui/hooks.dart:180:5)
#7      _startIsolate.<anonymous closure> (dart:isolate/runtime/libisolate_patch.dart:300:19)
#8      _RawReceivePortImpl._handleMessage (dart:isolate/runtime/libisolate_patch.dart:171:12)
''';

const errorOutput = '''Unhandled error NoSuchMethodError: The getter 'access' was called on null.
Receiver: null
Tried calling: access occurred in Instance of 'PinInBloc'.
#0      Object.noSuchMethod (dart:core-patch/object_patch.dart:51:5)
#1      PinInBloc.mapEventToState (package:herer/app/blocs/pin_in_bloc/pin_in_bloc.dart:24:9)
<asynchronous suspension>
#2      Bloc._bindEventsToStates.<anonymous closure> (package:bloc/src/bloc.dart:231:20)
#3      Stream.asyncExpand.<anonymous closure>.<anonymous closure> (dart:async/stream.dart:644:30)
#4      _rootRunUnary (dart:async/zone.dart:1206:13)
#5      _CustomZone.runUnary (dart:async/zone.dart:1100:19)
#6      _CustomZone.runUnaryGuarded (dart:async/zone.dart:1005:7)
#7      _BufferingStreamSubscription._sendData (dart:async/stream_impl.dart:357:11)
#8      _DelayedData.perform (dart:async/stream_impl.dart:611:14)
#9      _StreamImplEvents.handleNext (dart:async/stream_impl.dart:730:11)
#10     _PendingEvents.schedule.<anonymous closure> (dart:async/stream_impl.dart:687:7)
#11     _rootRun (dart:async/zone.dart:1182:47)
#12     _CustomZone.run (dart:async/zone.dart:1093:19)
#13     _CustomZone.runGuarded (dart:async/zone.dart:997:7)
#14     _CustomZone.bindCallbackGuarded.<anonymous closure> (dart:async/zone.dart:1037:23)
#15     _rootRun (dart:async/zone.dart:1190:13)
#16     _CustomZone.run (dart:async/zone.dart:1093:19)
#17     _CustomZone.runGuarded (dart:async/zone.dart:997:7)
#18     _CustomZone.bindCallbackGuarded.<anonymous closure> (dart:async/zone.dart:1037:23)
#19     _microtaskLoop (dart:async/schedule_microtask.dart:41:21)
#20     _startMicrotaskLoop (dart:async/schedule_microtask.dart:50:5)''';

class MockError extends Object {
  final String string;
  MockError(this.string);
  String toString() => string;
}

void main() {
  group('BugsnagCrashReport', () {
    group('default constructor', () {
      test('with an error', () {
        final error = Error();
        final report = BugsnagCrashReport(error: error, rawStackTrace: stackTrace);
        expect(report.error, error);
        expect(report.rawStackTrace, stackTrace);
      });

      test('with an exception', () {
        final exception = Exception();
        final report = BugsnagCrashReport(error: exception, rawStackTrace: stackTrace);
        expect(report.error, exception);
        expect(report.rawStackTrace, stackTrace);
      });
    });

    test('.fromEmbeddedStackTrace', () {
      final error = MockError(errorOutput);
      final report = BugsnagCrashReport.fromEmbeddedStackTrace(error);
      expect(report.error, error);
      expect(report.stackTrace.first.lineNumber, 51);
      expect(report.stackTrace.last.method, '_startMicrotaskLoop');
    });

    group('#errorClass', () {
      test('with an error', () {
        final error = AssertionError('a message');
        final report = BugsnagCrashReport(error: error, rawStackTrace: stackTrace);
        expect(report.errorClass, 'AssertionError');
      });

      test('with an exception', () {
        final exception = IntegerDivisionByZeroException();
        final report = BugsnagCrashReport(error: exception, rawStackTrace: stackTrace);
        expect(report.errorClass, 'IntegerDivisionByZeroException');
      });
    });

    test('#message', () {
      final assertionError = AssertionError('a message');
      var report = BugsnagCrashReport(error: assertionError, rawStackTrace: stackTrace);
      expect(report.message, 'Assertion failed: "a message"');

      final error = Error();
      report = BugsnagCrashReport(error: error, rawStackTrace: stackTrace);
      expect(report.message, "Instance of 'Error'");
    });

    test('#stackTrace', () {
      final error = ArgumentError('a message');
      final report = BugsnagCrashReport(error: error, rawStackTrace: stackTrace);
      expect(report.stackTrace.length, 9);

      final frame = report.stackTrace.last;
      expect(frame.method, '_RawReceivePortImpl._handleMessage');
      expect(frame.file, 'dart:isolate/runtime/libisolate_patch.dart');
      expect(frame.lineNumber, 171);
      expect(frame.columnNumber, 12);
    });

    test('#toJson', () {
      final error = ArgumentError('a message');
      final report = BugsnagCrashReport(error: error, rawStackTrace: stackTrace);
      final jsonMap = report.toJson();

      expect(jsonMap['errorClass'], 'ArgumentError');
      expect(jsonMap['message'], 'Invalid argument(s): a message');

      final frame = jsonMap['stacktrace'].last;
      expect(frame['method'], '_RawReceivePortImpl._handleMessage');
      expect(frame['file'], 'isolate/runtime/libisolate_patch.dart');
      expect(frame['lineNumber'], 171);
      expect(frame['columnNumber'], 12);
    });
  });
}
