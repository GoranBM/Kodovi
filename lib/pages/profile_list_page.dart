import 'package:flutter/material.dart';

import '../models/contact_profile.dart';
import '../pages/login_page.dart';
import '../services/auth_service.dart';
import '../services/onedrive_service.dart';
import 'editor_page.dart';
import 'profile_detail_page.dart';

class ProfileListPage extends StatefulWidget {
  const ProfileListPage({super.key});

  @override
  State<ProfileListPage> createState() => _ProfileListPageState();
}

class _ProfileListPageState extends State<ProfileListPage> {
  static const blue = Color(0xFF002856);

  List<ContactProfile> profiles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      profiles = await OneDriveService.loadAll();
    } catch (e) {
      if (mounted) setState(() => _error = "Greška pri učitavanju podataka.");
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openEditor([ContactProfile? p]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditorPage(existing: p)),
    );
    _load();
  }

  Future<void> _delete(int i) async {
    final profile = profiles[i];
    setState(() => profiles.removeAt(i));
    await OneDriveService.delete(profile);
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blue,
      appBar: AppBar(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        title: const Text("Digitalna vizitka"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Odjava",
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!,
                          style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _load,
                        child: const Text("Pokušaj ponovo"),
                      ),
                    ],
                  ),
                )
              : profiles.isEmpty
                  ? Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: blue,
                        ),
                        onPressed: () => _openEditor(),
                        child: const Text("+ Kreiraj kontakt"),
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              itemCount: profiles.length,
                              itemBuilder: (c, i) {
                                final p = profiles[i];
                                return Card(
                                  child: ListTile(
                                    title: Text(p.name),
                                    subtitle: Text(
                                        "${p.phones.length} tel • ${p.emails.length} mail"),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ProfileDetailPage(profile: p),
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () => _openEditor(p),
                                          icon: const Icon(Icons.edit),
                                        ),
                                        IconButton(
                                          onPressed: () => _delete(i),
                                          icon: const Icon(Icons.delete),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: blue,
                            ),
                            onPressed: () => _openEditor(),
                            child: const Text("+ Novi kontakt"),
                          ),
                        ),
                      ],
                    ),
    );
  }
}
