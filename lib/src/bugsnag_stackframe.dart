/// Thrown when the raw stackframe string can't be parsed.
class BugsnagStackframeParseError extends Error {}

/// Represents a single stackframe of the stack trace.
class BugsnagStackframe {
  /// The column number in the file that contains the code that is executing.
  final int columnNumber;

  /// The file name that contains the code that is executing.
  final String? file;

  /// If this stackframe came from within the developed package instead of
  /// a dependency. Defaults `false`.
  final bool inProject;

  /// The line number in the file that contains the code that is executing.
  final int lineNumber;

  /// The method in which the frame is executing.
  final String? method;

  /// The source package of the error
  final String? package;

  /// The raw string representation of the stackframe.
  final String rawString;

  BugsnagStackframe({
    required this.columnNumber,
    required this.file,
    bool? inProject,
    required this.lineNumber,
    required this.method,
    required this.package,
    required this.rawString,
  }) : inProject = inProject ?? false;

  /// Parses the [rawString] into a [BugsnagStackframe].
  factory BugsnagStackframe.fromString(
    String rawString, {
    String? projectPackageName,
  }) {
    final match = matchStackInfo.firstMatch(rawString);

    if (match == null) {
      throw BugsnagStackframeParseError();
    }

    final file = match.group(2);
    final package = file?.split(':').last.split('/').first;

    return BugsnagStackframe(
      columnNumber: int.tryParse(match.group(4) ?? '0')!,
      file: file,
      inProject: projectPackageName == null
          ? false
          : file?.contains(projectPackageName),
      lineNumber: int.tryParse(match.group(3) ?? '0')!,
      method: match.group(1),
      package: package,
      rawString: rawString,
    );
  }

  /// Converts the [BugsnagStackframe] to a JSON-serializable [Map].
  Map<String, dynamic> toJson() => {
        // ideally, className replaces "Runner" in the report view. But it's not quite right.
        // Unsure what the value should be
        'className': package,
        'columnNumber': columnNumber,
        'file': file?.replaceAll(RegExp(r':'), '/'),
        'inProject': inProject,
        'lineNumber': lineNumber,
        'method': method,
      };

  /// Parses a stacktrace line.
  /// Example: `#1      _rootRun (dart:async/zone.dart:1184:13)`
  ///
  /// Also account for `#12     _startIsolate.<anonymous closure> (dart:isolate-patch/isolate_patch.dart:301:19)`
  static final matchStackInfo = RegExp(
      r'#\d+\s+([\S\.]+)(?:.<[\w\s]+>)*\s+\((\w+:[^:]+):?(\d+)?:?(\d+)?\)\s*$');
}
