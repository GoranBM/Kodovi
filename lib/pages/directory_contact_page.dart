import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/directory_service.dart';
import '../services/file_util_stub.dart'
    if (dart.library.io) '../services/file_util_io.dart' as file_util;

class DirectoryContactPage extends StatelessWidget {
  final DirectoryContact contact;

  const DirectoryContactPage({super.key, required this.contact});

  static const blue = Color(0xFF002856);

  bool get _showCallButton =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _addToContacts() async {
    final bytes = Uint8List.fromList(utf8.encode(contact.toVCard()));
    final xfile = await file_util.bytesToXFile(
        bytes, '${contact.displayName}.vcf', 'text/vcard');
    await SharePlus.instance.share(ShareParams(files: [xfile]));
  }

  Future<void> _call(BuildContext context) async {
    final phones = contact.allPhones;
    if (phones.isEmpty) return;

    if (phones.length == 1) {
      await launchUrl(Uri.parse('tel:${phones.first}'));
      return;
    }

    if (!context.mounted) return;
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Odaberi broj'),
        children: phones
            .map((p) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, p),
                  child: Text(p),
                ))
            .toList(),
      ),
    );
    if (picked != null) await launchUrl(Uri.parse('tel:$picked'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(contact.displayName)),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // QR kod
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: QrImageView(
                    data: contact.toVCard(),
                    size: 250,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: blue,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: blue,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Podaci o kontaktu
                if (contact.jobTitle.isNotEmpty)
                  _infoRow(Icons.work, contact.jobTitle),
                if (contact.department.isNotEmpty)
                  _infoRow(Icons.business, contact.department),
                for (final p in contact.allPhones)
                  _infoRow(Icons.phone, p),
                if (contact.mail.isNotEmpty)
                  _infoRow(Icons.email, contact.mail),

                const SizedBox(height: 32),

                // Akcije
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    if (_showCallButton && contact.allPhones.isNotEmpty)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        onPressed: () => _call(context),
                        icon: const Icon(Icons.call),
                        label: const Text("Nazovi"),
                      ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      onPressed: _addToContacts,
                      icon: const Icon(Icons.person_add),
                      label: const Text("Dodaj u kontakte"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
          ],
        ),
      );
}
