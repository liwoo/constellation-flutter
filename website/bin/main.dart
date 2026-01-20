import 'dart:io';
import 'package:static_shock/static_shock.dart';

Future<void> main(List<String> arguments) async {
  final staticShock = StaticShock()
    // Pick source files
    ..pick(DirectoryPicker.parse('source'))

    // Core plugins
    ..plugin(const MarkdownPlugin())
    ..plugin(const JinjaPlugin())
    ..plugin(const PrettyUrlsPlugin())
    ..plugin(const SassPlugin())
    ..plugin(DraftingPlugin());

  await staticShock.generateSite();

  // Copy images directory to build output
  await _copyDirectory(
    Directory('source/images'),
    Directory('build/images'),
  );
  print('Copied images to build/images');

  // Copy index.html directly (Static Shock doesn't pick up plain HTML)
  final indexSource = File('source/index.html');
  if (await indexSource.exists()) {
    await indexSource.copy('build/index.html');
    print('Copied index.html to build/');
  }

  // Clean up unwanted output directories
  final layoutsDir = Directory('build/_layouts');
  if (await layoutsDir.exists()) {
    await layoutsDir.delete(recursive: true);
    print('Cleaned up build/_layouts');
  }
}

/// Recursively copy a directory to a new location
Future<void> _copyDirectory(Directory source, Directory destination) async {
  if (!await source.exists()) {
    print('Source directory does not exist: ${source.path}');
    return;
  }

  await destination.create(recursive: true);

  await for (final entity in source.list(recursive: false)) {
    final newPath = '${destination.path}/${entity.uri.pathSegments.last}';

    if (entity is File) {
      await entity.copy(newPath);
    } else if (entity is Directory) {
      await _copyDirectory(entity, Directory(newPath));
    }
  }
}
