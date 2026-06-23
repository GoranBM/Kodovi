import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';

// Web: XFile.fromData → browser download, bez pisanja na disk
Future<XFile> bytesToXFile(Uint8List bytes, String name, String mime) async =>
    XFile.fromData(bytes, mimeType: mime, name: name);
