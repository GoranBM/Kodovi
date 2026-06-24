import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/directory_service.dart';
import '../services/file_util_stub.dart'
    if (dart.library.io) '../services/file_util_io.dart' as file_util;
import 'directory_contact_page.dart';

class DirectoryPage extends StatefulWidget {
  const DirectoryPage({super.key});

  @override
  State<DirectoryPage> createState() => _DirectoryPageState();
}

class _DirectoryPageState extends State<DirectoryPage> {
  static const blue = Color(0xFF002856);

  List<DirectoryContact> _all = [];
  List<DirectoryContact> _filtered = [];
  bool _loading = true;
  String? _error;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(_filter);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await DirectoryService.getUsers();
      if (mounted) {
        setState(() {
          _all = users;
          _filtered = users;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().contains('403')
            ? 'Nema dozvole za imenik.\nOdjavite se i prijavite ponovo nakon što admin odobri pristup.'
            : 'Greška pri učitavanju imenika.');
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  void _filter() {
    final q = _search.text.toLowerCase();
    setState(() {
      _filtered = _all
          .where((c) =>
              c.displayName.toLowerCase().contains(q) ||
              c.jobTitle.toLowerCase().contains(q) ||
              c.department.toLowerCase().contains(q))
          .toList();
    });
  }

  Future<void> _downloadAll() async {
    if (_all.isEmpty) return;
    final allVCards = _all.map((c) => c.toVCard()).join('\r\n');
    final bytes = Uint8List.fromList(utf8.encode(allVCards));
    final xfile = await file_util.bytesToXFile(
        bytes, 'Monting_imenik.vcf', 'text/vcard');
    await SharePlus.instance.share(ShareParams(
      files: [xfile],
      subject: 'Monting imenik',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blue,
      appBar: AppBar(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        title: const Text("Imenik Monting"),
        actions: [
          if (!_loading && _error == null && _all.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: "Preuzmi sve kontakte",
              onPressed: _downloadAll,
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 15)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                            onPressed: _load,
                            child: const Text("Pokušaj ponovo")),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Tražilica
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: TextField(
                        controller: _search,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Pretraži...",
                          hintStyle:
                              const TextStyle(color: Colors.white54),
                          prefixIcon: const Icon(Icons.search,
                              color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white12,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 0),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16, bottom: 4, top: 2),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${_filtered.length} korisnika',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                      ),
                    ),

                    // Lista
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (ctx, i) {
                            final c = _filtered[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: blue,
                                  foregroundColor: Colors.white,
                                  child: Text(
                                    c.displayName.isNotEmpty
                                        ? c.displayName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(c.displayName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  [
                                    if (c.jobTitle.isNotEmpty) c.jobTitle,
                                    if (c.department.isNotEmpty)
                                      c.department,
                                  ].join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: Colors.grey),
                                onTap: () => Navigator.push(
                                  ctx,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DirectoryContactPage(contact: c),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
