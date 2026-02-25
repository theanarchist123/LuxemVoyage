import 'dart:io';

void main() {
  final dir = Directory('lib');
  int filesUpdated = 0;

  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = entity.readAsStringSync();
      if (content.contains('.withOpacity(')) {
        // Replace .withOpacity( with .withValues(alpha: 
        final newContent = content.replaceAll('.withOpacity(', '.withValues(alpha: ');
        entity.writeAsStringSync(newContent);
        print('Updated: ${entity.path}');
        filesUpdated++;
      }
    }
  }

  print('\nFinished updating $filesUpdated files. Please review the changes.');
}
