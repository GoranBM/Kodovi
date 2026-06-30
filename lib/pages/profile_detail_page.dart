import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../models/contact_profile.dart';
import '../services/file_util_stub.dart'
    if (dart.library.io) '../services/file_util_io.dart' as file_util;
import '../widgets/qr_with_logo.dart';

class ProfileDetailPage extends StatelessWidget {
  final ContactProfile profile;

  ProfileDetailPage({super.key, required this.profile});

  final ScreenshotController screenshotController = ScreenshotController();

  String _buildVCard() {
    final lines = <String>[
      'BEGIN:VCARD',
      'VERSION:3.0',
      'N:${profile.name};;;;',
      'FN:${profile.name}',
    ];
    for (final p in profile.phones) {
      lines.add('TEL;TYPE=CELL:$p');
    }
    for (final e in profile.emails) {
      lines.add('EMAIL;TYPE=WORK:$e');
    }
    for (final j in profile.jobs) {
      if (j.title.isNotEmpty) lines.add('TITLE:${j.title}');
      if (j.company.isNotEmpty) {
        lines.add('ORG:${j.company}'
            '${j.department.isNotEmpty ? ";${j.department}" : ""}');
      }
    }
    for (final w in profile.web) {
      lines.add('URL:$w');
    }
    for (final a in profile.addresses) {
      lines.add(
          'ADR;TYPE=WORK:;;${a.street};${a.city};;${a.zip};${a.country}');
    }
    lines.add('END:VCARD');
    return '${lines.join('\r\n')}\r\n';
  }

  Future<void> _shareQR() async {
    final bytes = await screenshotController.capture();
    if (bytes == null) return;
    // Na mobileu: piše na pravi temp file → Outlook ne dobije prazan ShaXXX.temp
    // Na webu: XFile.fromData → download
    final xfile = await file_util.bytesToXFile(
        bytes, 'qr_${profile.name}.png', 'image/png');
    await SharePlus.instance.share(
        ShareParams(files: [xfile], text: profile.name));
  }

  Future<void> _shareVCard() async {
    final bytes = Uint8List.fromList(utf8.encode(_buildVCard()));
    final xfile = await file_util.bytesToXFile(
        bytes, '${profile.name}.vcf', 'text/vcard');
    await SharePlus.instance.share(ShareParams(
      files: [xfile],
      subject: profile.name,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(profile.name)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Screenshot(
              controller: screenshotController,
              child: QrWithLogo(data: _buildVCard()),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002856),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _shareQR,
                  icon: const Icon(Icons.qr_code),
                  label: const Text("Dijeli QR"),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002856),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _shareVCard,
                  icon: const Icon(Icons.person_add),
                  label: const Text("Dijeli kontakt"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
