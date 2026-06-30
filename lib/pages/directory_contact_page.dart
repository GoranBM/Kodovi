import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/directory_service.dart';
import '../services/file_util_stub.dart'
    if (dart.library.io) '../services/file_util_io.dart' as file_util;
import '../widgets/qr_with_logo.dart';

class DirectoryContactPage extends StatelessWidget {
  final DirectoryContact contact;

  const DirectoryContactPage({super.key, required this.contact});

  static const blue = Color(0xFF002856);

  bool get _showCallButton =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _shareContact() async {
    final bytes = Uint8List.fromList(utf8.encode(contact.toVCard()));
    final xfile = await file_util.bytesToXFile(
        bytes, '${contact.displayName}.vcf', 'text/vcard');
    await SharePlus.instance.share(ShareParams(
      files: [xfile],
      subject: contact.displayName,
    ));
  }

  Future<void> _call(BuildContext context, [String? phone]) async {
    final phones = phone != null ? [phone] : contact.allPhones;
    if (phones.isEmpty) return;

    if (phones.length == 1) {
      await launchUrl(
        Uri.parse('tel:${phones.first}'),
        mode: LaunchMode.externalApplication,
      );
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
    if (picked != null) {
      await launchUrl(
        Uri.parse('tel:$picked'),
        mode: LaunchMode.externalApplication,
      );
    }
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
                QrWithLogo(data: contact.toVCard()),
                const SizedBox(height: 24),

                if (contact.jobTitle.isNotEmpty)
                  _infoRow(Icons.work, contact.jobTitle),
                if (contact.department.isNotEmpty)
                  _infoRow(Icons.business, contact.department),
                ...contact.allPhones.map((p) => _infoRow(
                      Icons.phone,
                      p,
                      onTap: () => _call(context, p),
                    )),
                if (contact.mail.isNotEmpty)
                  _infoRow(
                    Icons.email,
                    contact.mail,
                    onTap: () => launchUrl(
                      Uri.parse('mailto:${contact.mail}'),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),

                const SizedBox(height: 32),

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
                      onPressed: _shareContact,
                      icon: const Icon(Icons.share),
                      label: const Text("Dijeli kontakt"),
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

  Widget _infoRow(IconData icon, String text, {VoidCallback? onTap}) {
    final isClickable = onTap != null;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isClickable ? blue : Colors.grey),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  color: isClickable ? blue : null,
                  decoration: isClickable ? TextDecoration.underline : null,
                  decorationColor: blue,
                ),
              ),
            ),
            if (isClickable)
              const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
