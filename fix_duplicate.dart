import 'dart:io';

void main() async {
  final file = File('lib/screens/parent_dashboard.dart');
  final lines = await file.readAsLines();
  
  final out = <String>[];
  bool seenSectionLabel = false;
  bool skipping = false;
  
  for (int i = 0; i < lines.length; i++) {
    final l = lines[i];
    if (l.startsWith('class _SectionLabel extends StatelessWidget {')) {
      if (seenSectionLabel) {
        skipping = true;
        continue;
      }
      seenSectionLabel = true;
    }
    
    if (skipping) {
      if (l.startsWith('}')) {
        skipping = false;
      }
      continue;
    }
    
    out.add(l);
  }
  
  await file.writeAsString(out.join('\n'));
  print('Fixed duplicate _SectionLabel');
}
