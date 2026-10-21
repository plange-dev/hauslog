/// Plattformabhängige Funktionen: Desktop (dart:io) oder Web.
library;

export 'plattform_io.dart' if (dart.library.js_interop) 'plattform_web.dart';
