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

  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

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
    final q = _search.text.toLowerCase().trim();
    if (q.isEmpty) {
      setState(() => _filtered = List.of(_all));
      return;
    }
    // Za pretragu broja: ukloni ne-znamenke iz upita i iz broja
    final digits = q.replaceAll(RegExp(r'\D'), '');
    setState(() {
      _filtered = _all.where((c) {
        if (c.displayName.toLowerCase().contains(q)) return true;
        if (c.jobTitle.toLowerCase().contains(q)) return true;
        if (c.department.toLowerCase().contains(q)) return true;
        if (c.mail.toLowerCase().contains(q)) return true;
        if (digits.isNotEmpty &&
            c.allPhones.any(
                (p) => p.replaceAll(RegExp(r'\D'), '').contains(digits))) {
          return true;
        }
        return false;
      }).toList();
    });
  }

  Future<void> _downloadAll() async {
    if (_all.isEmpty) return;
    final vcards = _all.map((c) => c.toVCard()).join('\r\n');
    final bytes = Uint8List.fromList(utf8.encode(vcards));
    final xfile =
        await file_util.bytesToXFile(bytes, 'Monting_imenik.vcf', 'text/vcard');
    await SharePlus.instance
        .share(ShareParams(files: [xfile], subject: 'Monting imenik'));
  }

  Future<void> _downloadSelected() async {
    final contacts =
        _all.where((c) => _selectedIds.contains(c.id)).toList();
    if (contacts.isEmpty) return;
    final vcards = contacts.map((c) => c.toVCard()).join('\r\n');
    final bytes = Uint8List.fromList(utf8.encode(vcards));
    final name = contacts.length == 1
        ? '${contacts.first.displayName}.vcf'
        : 'Monting_odabrani.vcf';
    final subject = contacts.length == 1
        ? contacts.first.displayName
        : 'Odabrani kontakti';
    final xfile = await file_util.bytesToXFile(bytes, name, 'text/vcard');
    await SharePlus.instance.share(ShareParams(files: [xfile], subject: subject));
    _clearSelection();
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _startSelection(String id) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(id);
    });
  }

  void _clearSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_selectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _clearSelection();
      },
      child: Scaffold(
        backgroundColor: blue,
        appBar: AppBar(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          leading: _selectionMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clearSelection,
                )
              : null,
          title: Text(
            _selectionMode
                ? '${_selectedIds.length} odabrano'
                : 'Imenik Monting',
          ),
          actions: [
            if (_selectionMode && _selectedIds.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: "Preuzmi odabrane",
                onPressed: _downloadSelected,
              ),
            if (!_selectionMode &&
                !_loading &&
                _error == null &&
                _all.isNotEmpty)
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                        child: TextField(
                          controller: _search,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Ime, pozicija, broj, mail...",
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
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            itemCount: _filtered.length,
                            itemBuilder: (ctx, i) {
                              final c = _filtered[i];
                              final isSelected =
                                  _selectedIds.contains(c.id);
                              return Card(
                                color: isSelected
                                    ? Colors.blue.shade100
                                    : null,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                child: ListTile(
                                  leading: _selectionMode
                                      ? Checkbox(
                                          value: isSelected,
                                          activeColor: blue,
                                          onChanged: (_) =>
                                              _toggleSelect(c.id),
                                        )
                                      : CircleAvatar(
                                          backgroundColor: blue,
                                          foregroundColor: Colors.white,
                                          child: Text(
                                            c.displayName.isNotEmpty
                                                ? c.displayName[0]
                                                    .toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                                fontWeight:
                                                    FontWeight.bold),
                                          ),
                                        ),
                                  title: Text(c.displayName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  subtitle: Text(
                                    [
                                      if (c.jobTitle.isNotEmpty)
                                        c.jobTitle,
                                      if (c.department.isNotEmpty)
                                        c.department,
                                    ].join(' · '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: _selectionMode
                                      ? null
                                      : const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 14,
                                          color: Colors.grey),
                                  onTap: _selectionMode
                                      ? () => _toggleSelect(c.id)
                                      : () => Navigator.push(
                                            ctx,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  DirectoryContactPage(
                                                      contact: c),
                                            ),
                                          ),
                                  onLongPress: _selectionMode
                                      ? null
                                      : () => _startSelection(c.id),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
