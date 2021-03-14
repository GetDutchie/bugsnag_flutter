import 'package:flutter_test/flutter_test.dart';
import 'package:matcher/matcher.dart';
import 'package:bugsnag_flutter/src/bugsnag_stackframe.dart';

void main() {
  group('BugsnagStackframe', () {
    test('default constructor', () {
      final stackframe = BugsnagStackframe(
        rawString: 'raw',
        method: 'a method',
        package: 'my_package',
        file: 'a file',
        lineNumber: 3,
        columnNumber: 4,
      );
      expect(stackframe.rawString, 'raw');
      expect(stackframe.file, 'a file');
      expect(stackframe.lineNumber, 3);
      expect(stackframe.columnNumber, 4);
      expect(stackframe.package, 'my_package');
      expect(stackframe.method, 'a method');
    });

    group('.fromString', () {
      test('with column', () {
        final rawString =
            '#0      main (package:mypackage/lib/app/main_development.dart:7:5)';
        final stackframe = BugsnagStackframe.fromString(rawString,
            projectPackageName: 'mypackage');
        expect(stackframe.rawString, rawString);
        expect(
            stackframe.file, 'package:mypackage/lib/app/main_development.dart');
        expect(stackframe.lineNumber, 7);
        expect(stackframe.columnNumber, 5);
        expect(stackframe.package, 'mypackage');
        expect(stackframe.method, 'main');
        expect(stackframe.inProject, true);
      });

      test('without column', () {
        final rawString =
            '#4      _CustomZone.runUnary (dart:async/zone.dart:1100)';
        final stackframe = BugsnagStackframe.fromString(rawString);
        expect(stackframe.rawString, rawString);
        expect(stackframe.file, 'dart:async/zone.dart');
        expect(stackframe.lineNumber, 1100);
        expect(stackframe.package, 'async');
        expect(stackframe.columnNumber, 0);
        expect(stackframe.method, '_CustomZone.runUnary');
        expect(stackframe.inProject, false);
      });

      test('without line or column', () {
        final rawString =
            '#23     MethodChannel._invokeMethod (package:flutter/src/services/platform_channel.dart)';
        final stackframe = BugsnagStackframe.fromString(rawString);
        expect(stackframe.rawString, rawString);
        expect(stackframe.columnNumber, 0);
        expect(stackframe.lineNumber, 0);
        expect(stackframe.method, 'MethodChannel._invokeMethod');
        expect(stackframe.inProject, false);
      });
    });

    test(
        'BugsnagStackframe.fromString() throws when stackframe cannot be parsed',
        () {
      expect(() => BugsnagStackframe.fromString(''),
          throwsA(TypeMatcher<BugsnagStackframeParseError>()));
    });

    test('#toJson returns a map', () {
      final rawString =
          '#0      main (package:mypackage/lib/app/main_development.dart:7:5)';
      final stackframe = BugsnagStackframe.fromString(rawString,
          projectPackageName: 'mypackage');
      expect(stackframe.toJson(), {
        'className': 'mypackage',
        'columnNumber': 5,
        'file': 'package/mypackage/lib/app/main_development.dart',
        'lineNumber': 7,
        'method': 'main',
        'inProject': true,
      });
    });
  });
}
