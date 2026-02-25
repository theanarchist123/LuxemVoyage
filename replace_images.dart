import 'dart:io';

void main() {
  final dir = Directory('lib');
  int updated = 0;
  
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      var content = entity.readAsStringSync();
      bool changed = false;
      
      if (content.contains('NetworkImage(')) {
        content = content.replaceAll('NetworkImage(', 'CachedNetworkImageProvider(');
        changed = true;
      }
      
      final imageNetworkRegex = RegExp(r'Image\.network\(([^,\)]+)(,?)');
      if (imageNetworkRegex.hasMatch(content)) {
        content = content.replaceAllMapped(imageNetworkRegex, (m) {
          final url = m.group(1);
          final comma = m.group(2) ?? '';
          if (comma.isEmpty) {
              return 'CachedNetworkImage(imageUrl: $url';
          }
          return 'CachedNetworkImage(imageUrl: $url$comma';
        });
        
        // Swap errorBuilder to errorWidget
        content = content.replaceAll('errorBuilder:', 'errorWidget:');
        changed = true;
      }
      
      // Update BouncingScrollPhysics
      if (content.contains('BouncingScrollPhysics()')) {
        content = content.replaceAll('BouncingScrollPhysics()', 'BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())');
        changed = true;
      }

      if (changed) {
        if (!content.contains("import 'package:cached_network_image/cached_network_image.dart';")) {
           content = "import 'package:cached_network_image/cached_network_image.dart';\n" + content;
        }
        entity.writeAsStringSync(content);
        print('Updated: ${entity.path}');
        updated++;
      }
    }
  }
  print('Finished updating $updated files.');
}
