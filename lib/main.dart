import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

// ================= THEME =================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF002856);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: blue,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: blue),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          alignLabelWithHint: true,
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: blue),
          
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF002856),
          ),
        ),
      ),
      home: const ProfileListPage(),
    );
  }
}

// ================= MODEL =================

class ContactProfile {
  String name;
  List<String> phones;
  List<String> emails;
  List<String> web;
  List<Address> addresses;

  ContactProfile({
    required this.name,
    required this.phones,
    required this.emails,
    required this.web,
    required this.addresses,
  });

  Map<String, dynamic> toJson() => {
        "name": name,
        "phones": phones,
        "emails": emails,
        "web": web,
        "addresses": addresses.map((e) => e.toJson()).toList(),
      };

  static ContactProfile fromJson(Map<String, dynamic> json) {
    return ContactProfile(
      name: json["name"] ?? "",
      phones: List<String>.from(json["phones"] ?? []),
      emails: List<String>.from(json["emails"] ?? []),
      web: List<String>.from(json["web"] ?? []),
      addresses: (json["addresses"] as List? ?? [])
          .map((e) => Address.fromJson(e))
          .toList(),
    );
  }
}

class Address {
  String street;
  String city;
  String zip;
  String country;

  Address({
    required this.street,
    required this.city,
    required this.zip,
    required this.country,
  });

  Map<String, dynamic> toJson() => {
        "street": street,
        "city": city,
        "zip": zip,
        "country": country,
      };

  static Address fromJson(Map<String, dynamic> json) {
    return Address(
      street: json["street"] ?? "",
      city: json["city"] ?? "",
      zip: json["zip"] ?? "",
      country: json["country"] ?? "",
    );
  }
}

// ================= STORAGE =================

class Storage {
  static const key = "profiles";

  static Future<List<ContactProfile>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(key) ?? [];
    return data.map((e) => ContactProfile.fromJson(jsonDecode(e))).toList();
  }

  static Future<void> save(List<ContactProfile> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      key,
      list.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }
}

// ================= LIST =================

class ProfileListPage extends StatefulWidget {
  const ProfileListPage({super.key});

  @override
  State<ProfileListPage> createState() => _ProfileListPageState();
}

class _ProfileListPageState extends State<ProfileListPage> {
  List<ContactProfile> profiles = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    profiles = await Storage.load();
    setState(() {});
  }

  Future<void> openEditor([ContactProfile? p, int? i]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditorPage(existing: p, index: i),
      ),
    );
    load();
  }

  Future<void> delete(int i) async {
    profiles.removeAt(i);
    await Storage.save(profiles);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF002856);

    return Scaffold(
      backgroundColor: blue,
      appBar: AppBar(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        title: const Text("QR Contacts"),
      ),
      body: profiles.isEmpty
          ? Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: blue,
                ),
                onPressed: () => openEditor(),
                child: const Text("+ Kreiraj kontakt"),
              ),
            )
          : Column(
              children: [
                Expanded(
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
                              builder: (_) => ProfileDetailPage(profile: p),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                  onPressed: () => openEditor(p, i),
                                  icon: const Icon(Icons.edit)),
                              IconButton(
                                  onPressed: () => delete(i),
                                  icon: const Icon(Icons.delete)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: blue,
                    ),
                    onPressed: () => openEditor(),
                    child: const Text("+ Novi kontakt"),
                  ),
                )
              ],
            ),
    );
  }
}

// ================= EDITOR =================

class EditorPage extends StatefulWidget {
  final ContactProfile? existing;
  final int? index;

  const EditorPage({super.key, this.existing, this.index});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final name = TextEditingController();

  List<TextEditingController> phones = [];
  List<TextEditingController> emails = [];
  List<TextEditingController> web = [];

  List<AddressController> addresses = [];

  @override
  void initState() {
    super.initState();

    if (widget.existing != null) {
      name.text = widget.existing!.name;

      phones = widget.existing!.phones
          .map((e) => TextEditingController(text: e))
          .toList();

      emails = widget.existing!.emails
          .map((e) => TextEditingController(text: e))
          .toList();

      web = widget.existing!.web
          .map((e) => TextEditingController(text: e))
          .toList();

      addresses = widget.existing!.addresses
          .map((a) => AddressController()
            ..street.text = a.street
            ..city.text = a.city
            ..zip.text = a.zip
            ..country.text = a.country)
          .toList();
    }
  }

  void addPhone() => setState(() => phones.add(TextEditingController()));
  void addEmail() => setState(() => emails.add(TextEditingController()));
  void addWeb() => setState(() => web.add(TextEditingController()));
  void addAddress() => setState(() => addresses.add(AddressController()));

  Future<void> save() async {
    final list = await Storage.load();

    final p = ContactProfile(
      name: name.text,
      phones: phones.map((e) => e.text).toList(),
      emails: emails.map((e) => e.text).toList(),
      web: web.map((e) => e.text).toList(),
      addresses: addresses
          .map((a) => Address(
                street: a.street.text,
                city: a.city.text,
                zip: a.zip.text,
                country: a.country.text,
              ))
          .toList(),
    );

    if (widget.index != null) {
      list[widget.index!] = p;
    } else {
      list.add(p);
    }

    await Storage.save(list);
    if (!context.mounted) return;
    Navigator.pop(context);
  }

  Widget buildList(String title, List<TextEditingController> list, VoidCallback add) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        ...list.map((c) => TextField(
              controller: c,
              style: const TextStyle(color: Color(0xFF002856)),
              decoration: const InputDecoration(
                labelStyle: TextStyle(color: Color(0xFF002856)),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF002856)),
                ),
                border: OutlineInputBorder(),
              ),
            )),
        TextButton(
          onPressed: add,
          child: Text("+ Dodaj $title"),
        )
      ],
    );
  }

  Widget buildAddress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Adrese",
          style: TextStyle(color: Color(0xFF002856), fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        ...addresses.map((a) {
          return Card(
            color: const Color(0xFFEAF3FF),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: a.street,
                    decoration: const InputDecoration(labelText: "Ulica"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: a.city,
                    decoration: const InputDecoration(labelText: "Grad"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: a.zip,
                    decoration: const InputDecoration(labelText: "Poštanski broj"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: a.country,
                    decoration: const InputDecoration(labelText: "Država"),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        }),

        TextButton(
          onPressed: addAddress,
          child: const Text(
            "+ Dodaj adresu",
            style: TextStyle(color: Color(0xFF002856)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kontakt")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: name,
              textAlign: TextAlign.left,
              decoration: const InputDecoration(labelText: "Ime"),
            ),
            const SizedBox(height: 20),
            buildList("Telefoni", phones, addPhone),
            buildList("Emailovi", emails, addEmail),
            buildList("Web", web, addWeb),
            buildAddress(),
            const SizedBox(height: 20),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF002856),
                  foregroundColor: Colors.white,
                ),
                onPressed: save,
                child: const Text("Spremi"),
              )
          ],
        ),
      ),
    );
  }
}

class AddressController {
  TextEditingController street = TextEditingController();
  TextEditingController city = TextEditingController();
  TextEditingController zip = TextEditingController();
  TextEditingController country = TextEditingController();
}

// ================= QR =================

class ProfileDetailPage extends StatelessWidget {
  final ContactProfile profile;

  const ProfileDetailPage({super.key, required this.profile});

String qr() {
  String phones =
      profile.phones.map((e) => "TEL;TYPE=CELL:$e").join("\r\n");

  String emails =
      profile.emails.map((e) => "EMAIL;TYPE=WORK:$e").join("\r\n");

  String websites =
      profile.web.map((e) => "URL:$e").join("\r\n");

  String addresses = profile.addresses.map((a) {
    return "ADR;TYPE=WORK:;;${a.street};${a.city};;${a.zip};${a.country}";
  }).join("\r\n");

  return [
    "BEGIN:VCARD",
    "VERSION:3.0",
    "FN:${profile.name}",
    phones,
    emails,
    websites,
    addresses,
    "END:VCARD",
  ].join("\r\n");
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(profile.name)),
      body: Center(
        child: Stack(
        alignment: Alignment.center,
        children: [
          QrImageView(
            data: qr(),
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
      )
      ),
      
    );
  }
}