import 'dart:io';

void main() {
  final dir = Directory('lib');
  int updated = 0;
  
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      var content = entity.readAsStringSync();
      bool changed = false;
      
      if (content.contains('CachedCachedNetworkImageProvider')) {
        // Fix the double replacement issue
        content = content.replaceAll('CachedCachedNetworkImageProvider', 'CachedNetworkImage');
        changed = true;
      }
      
      if (content.contains('CachedNetworkImageProviderProvider')) {
        content = content.replaceAll('CachedNetworkImageProviderProvider', 'CachedNetworkImageProvider');
        changed = true;
      }

      if (changed) {
        entity.writeAsStringSync(content);
        print('Fixed: ${entity.path}');
        updated++;
      }
    }
  }
  print('Finished fixing $updated files. Please run flutter run again.');
}
