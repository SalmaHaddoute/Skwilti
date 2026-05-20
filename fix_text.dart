import 'dart:io';

void main() async {
  final file = File('lib/screens/parent_dashboard.dart');
  var content = await file.readAsString();
  
  // Cleanly replace garbled chars
  content = content.replaceAll('Activit', 'Activité');
  content = content.replaceAll('matire', 'matière');
  
  await file.writeAsString(content);
  print('Fixed text encoding!');
}
