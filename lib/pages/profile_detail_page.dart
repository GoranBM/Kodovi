import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../models/contact_profile.dart';
import '../services/file_util_stub.dart'
    if (dart.library.io) '../services/file_util_io.dart' as file_util;

class ProfileDetailPage extends StatelessWidget {
  final ContactProfile profile;

  ProfileDetailPage({super.key, required this.profile});

  final ScreenshotController screenshotController = ScreenshotController();

  String _buildVCard() {
    final phones =
        profile.phones.map((e) => "TEL;TYPE=CELL:$e").join("\r\n");
    final emails =
        profile.emails.map((e) => "EMAIL;TYPE=WORK:$e").join("\r\n");
    final websites = profile.web.map((e) => "URL:$e").join("\r\n");
    final addresses = profile.addresses.map((a) {
      return "ADR;TYPE=WORK:;;${a.street};${a.city};;${a.zip};${a.country}";
    }).join("\r\n");
    final jobsData = profile.jobs.map((j) {
      final lines = <String>[];
      if (j.title.isNotEmpty) lines.add("TITLE:${j.title}");
      if (j.company.isNotEmpty) {
        lines.add(
          "ORG:${j.company}${j.department.isNotEmpty ? ';${j.department}' : ''}",
        );
      }
      return lines.join("\r\n");
    }).join("\r\n");

    return [
      "BEGIN:VCARD",
      "VERSION:3.0",
      "N:${profile.name};;;;",
      "FN:${profile.name}",
      phones,
      emails,
      jobsData,
      websites,
      addresses,
      "END:VCARD",
    ].join("\r\n");
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
    await SharePlus.instance.share(ShareParams(files: [xfile]));
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
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    QrImageView(
                      data: _buildVCard(),
                      size: 250,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF002856),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF002856),
                      ),
                    ),
                    Container(
                      width: 55,
                      height: 55,
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset('assets/monting_logo.jpeg'),
                    ),
                  ],
                ),
              ),
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
