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
  List<JobInfo> jobs;

  

  ContactProfile({
    required this.name,
    required this.phones,
    required this.emails,
    required this.web,
    required this.addresses,
    required this.jobs,
  });

  Map<String, dynamic> toJson() => {
        "name": name,
        "phones": phones,
        "emails": emails,
        "web": web,
        "addresses": addresses.map((e) => e.toJson()).toList(),
        "jobs": jobs.map((e) => e.toJson()).toList(),
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
      jobs: (json["jobs"] as List? ?? [])
          .map((e) => JobInfo.fromJson(e))
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

class JobInfo {
  String title;
  String department;
  String company;

  JobInfo({
    required this.title,
    required this.department,
    required this.company,
  });

  Map<String, dynamic> toJson() => {
        "title": title,
        "department": department,
        "company": company,
      };

  static JobInfo fromJson(Map<String, dynamic> json) {
    return JobInfo(
      title: json["title"] ?? "",
      department: json["department"] ?? "",
      company: json["company"] ?? "",
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
        title: const Text("Digitalna vizitka"),
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
  static const blue = Color(0xFF002856);

  final name = TextEditingController();

  List<TextEditingController> phones = [];
  List<TextEditingController> emails = [];
  List<TextEditingController> web = [];
  List<AddressController> addresses = [];
  List<JobController> jobs = [];

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
      jobs = widget.existing!.jobs
          .map((j) => JobController()
            ..title.text = j.title
            ..department.text = j.department
            ..company.text = j.company)
          .toList();    
    }
  }

  void addPhone() => setState(() => phones.add(TextEditingController()));
  void addEmail() => setState(() => emails.add(TextEditingController()));
  void addWeb() => setState(() => web.add(TextEditingController()));
  void addAddress() => setState(() => addresses.add(AddressController()));
  void addJob() => setState(() => jobs.add(JobController()));

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
      jobs: jobs
          .map((j) => JobInfo(
                title: j.title.text,
                department: j.department.text,
                company: j.company.text,
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

  // ── Sekcija s labelom lijevo i "+" gumbom desno ──────────────────────────
  Widget buildSection({
    required String label,
    required List<TextEditingController> controllers,
    required VoidCallback onAdd,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Naslov sekcije + "+" gumb desno
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: blue,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            ElevatedButton.icon(
              onPressed: onAdd,  // ili addAddress za drugi slučaj
              icon: const Icon(Icons.add, size: 14, color: Colors.white),
              label: const Text(
                "Dodaj",
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: StadiumBorder(), // ← ovo je pilula
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Polja
        ...controllers.asMap().entries.map((entry) {
          final i = entry.key;
          final c = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: c,
                    keyboardType: keyboardType,
                    style: const TextStyle(color: blue),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: blue),
                      ),
                    ),
                  ),
                ),
                // Gumb za brisanje pojedinog polja
                if (controllers.length > 1)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.red),
                    onPressed: () => setState(() => controllers.removeAt(i)),
                    padding: const EdgeInsets.only(left: 4),
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Sekcija za adrese ─────────────────────────────────────────────────────
  Widget buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Adresa",
              style: TextStyle(
                color: blue,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            ElevatedButton.icon(
              onPressed: addAddress,  // ili addAddress za drugi slučaj
              icon: const Icon(Icons.add, size: 14, color: Colors.white),
              label: const Text(
                "Dodaj",
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: StadiumBorder(), // ← ovo je pilula
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...addresses.asMap().entries.map((entry) {
          final i = entry.key;
          final a = entry.value;
          return Card(
            color: const Color(0xFFEAF3FF),
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brisanje adrese
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.close,
                          size: 18, color: Colors.red),
                      onPressed: () => setState(() => addresses.removeAt(i)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  _addressField(a.street, "Ulica"),
                  const SizedBox(height: 10),
                  _addressField(a.city, "Grad"),
                  const SizedBox(height: 10),
                  _addressField(a.zip, "Poštanski broj",
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 10),
                  _addressField(a.country, "Država"),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

Widget buildJobSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Posao",
            style: TextStyle(
              color: blue,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          ElevatedButton.icon(
            onPressed: addJob,
            icon: const Icon(Icons.add, size: 14, color: Colors.white),
            label: const Text(
              "Dodaj",
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: blue,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: const StadiumBorder(),
              elevation: 0,
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),

      ...jobs.asMap().entries.map((entry) {
        final i = entry.key;
        final j = entry.value;

        return Card(
          color: const Color(0xFFEAF3FF),
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.red,
                    ),
                    onPressed: () =>
                        setState(() => jobs.removeAt(i)),
                  ),
                ),

                _addressField(
                  j.title,
                  "Titula",
                ),

                const SizedBox(height: 10),

                _addressField(
                  j.department,
                  "Odjel",
                ),

                const SizedBox(height: 10),

                _addressField(
                  j.company,
                  "Kompanija",
                ),
              ],
            ),
          ),
        );
      }),
    ],
  );
}
  Widget _addressField(
    TextEditingController c,
    String label, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: c,
      keyboardType: keyboardType,
      style: const TextStyle(color: blue),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: blue),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: blue),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kontakt")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // ← FIX: sve lijevo
          children: [
            // ── Ime i prezime ──────────────────────────────────────────────
            TextField(
              controller: name,
              style: const TextStyle(color: blue),
              decoration: const InputDecoration(
                labelText: "Ime i prezime",
                labelStyle: TextStyle(color: blue),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: blue),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Telefon ────────────────────────────────────────────────────
            buildSection(
              label: "Broj telefona",
              controllers: phones,
              onAdd: addPhone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),

            // ── Email ──────────────────────────────────────────────────────
            buildSection(
              label: "Email",
              controllers: emails,
              onAdd: addEmail,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),

            buildJobSection(),
            const SizedBox(height: 20),

            // ── Web ────────────────────────────────────────────────────────
            buildSection(
              label: "Web stranica",
              controllers: web,
              onAdd: addWeb,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 20),

            // ── Adresa ─────────────────────────────────────────────────────
            buildAddressSection(),
            const SizedBox(height: 28),

            // ── Spremi ─────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: save,
                child: const Text("Spremi", style: TextStyle(fontSize: 16)),
              ),
            ),
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

class JobController {
  TextEditingController title = TextEditingController();
  TextEditingController department = TextEditingController();
  TextEditingController company = TextEditingController();
}

// ================= QR =================

class ProfileDetailPage extends StatelessWidget {
  final ContactProfile profile;

  ProfileDetailPage({
    super.key,
    required this.profile,
  });

  final ScreenshotController screenshotController = ScreenshotController();

  String qr() {
    String phones =
        profile.phones.map((e) => "TEL;TYPE=CELL:$e").join("\r\n");

    String emails =
        profile.emails.map((e) => "EMAIL;TYPE=WORK:$e").join("\r\n");

    String websites = profile.web.map((e) => "URL:$e").join("\r\n");

    String addresses = profile.addresses.map((a) {
      return "ADR;TYPE=WORK:;;${a.street};${a.city};;${a.zip};${a.country}";
    }).join("\r\n");

    String jobsData = profile.jobs.map((j) {
    final lines = <String>[];

    if (j.title.isNotEmpty) {
      lines.add("TITLE:${j.title}");
    }

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

  Future<void> shareQR() async {
    final image = await screenshotController.capture();

    if (image == null) return;

    final dir = await getTemporaryDirectory();

    final file = File("${dir.path}/qr_contact.png");

    await file.writeAsBytes(image);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: profile.name,
    );
  }

Future<void> shareVCard() async {
  final dir = await getTemporaryDirectory();

  final file = File('${dir.path}/contact.vcf');

  await file.writeAsString(qr());

  await Share.shareXFiles([
    XFile(file.path),
  ]);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(profile.name),
      ),
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
                      child: Image.asset(
                        'assets/monting_logo.jpeg',
                      ),
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
                  onPressed: shareQR,
                  icon: const Icon(Icons.qr_code),
                  label: const Text("Dijeli QR"),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002856),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: shareVCard,
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