import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

// ================= MODELS =================

class Item {
  TextEditingController controller;
  Item(this.controller);
}

class AddressItem {
  TextEditingController ulica = TextEditingController();
  TextEditingController broj = TextEditingController();
  TextEditingController grad = TextEditingController();
  TextEditingController zupanija = TextEditingController();
  TextEditingController postanski = TextEditingController();
  TextEditingController drzava = TextEditingController();
}

// ================= HOME =================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final imeController = TextEditingController();

  final ScreenshotController screenshotController = ScreenshotController();

  List<Item> telefoni = [];
  List<Item> emailovi = [];
  List<Item> webovi = [];
  List<AddressItem> adrese = [];

  String qrData = "";

  // ================= INIT =================

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ================= STORAGE =================

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      imeController.text = prefs.getString("ime") ?? "";

      telefoni = (prefs.getStringList("tel") ?? [])
          .map((e) => Item(TextEditingController(text: e)))
          .toList();

      emailovi = (prefs.getStringList("mail") ?? [])
          .map((e) => Item(TextEditingController(text: e)))
          .toList();

      webovi = (prefs.getStringList("web") ?? [])
          .map((e) => Item(TextEditingController(text: e)))
          .toList();
    });
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("ime", imeController.text);
    await prefs.setStringList(
        "tel", telefoni.map((e) => e.controller.text).toList());
    await prefs.setStringList(
        "mail", emailovi.map((e) => e.controller.text).toList());
    await prefs.setStringList(
        "web", webovi.map((e) => e.controller.text).toList());
  }

  // ================= ADD / REMOVE =================

  void addItem(List<Item> list) {
    setState(() => list.add(Item(TextEditingController())));
  }

  void removeItem(List<Item> list, int index) {
    setState(() => list.removeAt(index));
  }

  void addAddress() {
    setState(() => adrese.add(AddressItem()));
  }

  // ================= VCARD =================

  String buildVCARD() {
    String tel =
        telefoni.map((e) => "TEL:${e.controller.text}").join("\n");

    String mail =
        emailovi.map((e) => "EMAIL:${e.controller.text}").join("\n");

    String web =
        webovi.map((e) => "URL:${e.controller.text}").join("\n");

    String adr = adrese.map((a) {
      return "ADR:;;${a.ulica.text} ${a.broj.text};${a.grad.text};${a.zupanija.text};${a.postanski.text};${a.drzava.text}";
    }).join("\n");

    return '''
BEGIN:VCARD
VERSION:3.0
FN:${imeController.text}
$tel
$mail
$web
$adr
END:VCARD
''';
  }

  Future<void> generiraj() async {
    await saveData();

    setState(() {
      qrData = buildVCARD();
    });
  }

  // ================= QR ACTIONS =================

  Future<void> downloadQR() async {
    final image = await screenshotController.capture();
    if (image == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/qr_contact.png');

    await file.writeAsBytes(image);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("QR spremljen")),
    );
  }

  Future<void> shareQR() async {
    final image = await screenshotController.capture();
    if (image == null) return;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/qr_temp.png');

    await file.writeAsBytes(image);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: "Moj QR kontakt",
    );
  }

  // ================= UI HELPERS =================

  Widget buildList(String title, List<Item> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold)),

        const SizedBox(height: 10),

        ...list.asMap().entries.map((e) {
          return Row(
            children: [
              Expanded(
                child: TextField(
                  controller: e.value.controller,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => removeItem(list, e.key),
              )
            ],
          );
        }),

        TextButton(
          onPressed: () => addItem(list),
          child: Text("+ Dodaj $title"),
        ),
      ],
    );
  }

  Widget buildAdrese() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Adrese",
            style: TextStyle(fontWeight: FontWeight.bold)),

        const SizedBox(height: 10),

        ...adrese.map((a) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  TextField(controller: a.ulica, decoration: const InputDecoration(labelText: "Ulica")),
                  TextField(controller: a.broj, decoration: const InputDecoration(labelText: "Broj")),
                  TextField(controller: a.grad, decoration: const InputDecoration(labelText: "Grad")),
                  TextField(controller: a.zupanija, decoration: const InputDecoration(labelText: "Županija")),
                  TextField(controller: a.postanski, decoration: const InputDecoration(labelText: "Poštanski")),
                  TextField(controller: a.drzava, decoration: const InputDecoration(labelText: "Država")),
                ],
              ),
            ),
          );
        }),

        TextButton(
          onPressed: addAddress,
          child: const Text("+ Dodaj adresu"),
        ),
      ],
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("QR Contact PRO")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: imeController,
              decoration: const InputDecoration(labelText: "Ime"),
            ),

            const SizedBox(height: 20),

            buildList("Telefoni", telefoni),
            buildList("Emailovi", emailovi),
            buildList("Web", webovi),
            buildAdrese(),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: generiraj,
              child: const Text("Generiraj QR"),
            ),

            const SizedBox(height: 20),

            if (qrData.isNotEmpty)
              Screenshot(
                controller: screenshotController,
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      QrImageView(
                        data: qrData,
                        size: 300,
                        errorCorrectionLevel:
                            QrErrorCorrectLevel.H,
                      ),
                      Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Image.asset(
                              'assets/monting_logo.jpeg'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            if (qrData.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: downloadQR,
                    icon: const Icon(Icons.download),
                    label: const Text("Download"),
                  ),
                  ElevatedButton.icon(
                    onPressed: shareQR,
                    icon: const Icon(Icons.share),
                    label: const Text("Share"),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}