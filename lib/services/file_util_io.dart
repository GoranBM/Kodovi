import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// Mobile/desktop: piše na pravi temp file da ga Outlook i sl. može pročitati
Future<XFile> bytesToXFile(Uint8List bytes, String name, String mime) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$name');
  await file.writeAsBytes(bytes, flush: true);
  return XFile(file.path, mimeType: mime, name: name);
}
