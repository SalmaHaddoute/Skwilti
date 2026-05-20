import 'dart:io';

void main() async {
  final file = File('lib/screens/parent_dashboard.dart');
  final content = await file.readAsString();
  
  final tmpFile = File('lib/screens/_home_tab_combined.dart.tmp');
  final combinedCode = await tmpFile.readAsString();
  
  final homeTabStart = content.indexOf('class _HomeTab extends StatefulWidget {');
  final contactTabStart = content.indexOf('class _ContactTab extends StatefulWidget {');
  
  if (homeTabStart == -1 || contactTabStart == -1) {
    print('Failed to find markers');
    return;
  }
  
  final newContent = content.substring(0, homeTabStart) + combinedCode + '\n\n' + content.substring(contactTabStart);
  
  await file.writeAsString(newContent);
  print('Successfully replaced tabs!');
}
