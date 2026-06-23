import 'package:flutter/material.dart';

import '../models/contact_profile.dart';
import '../services/onedrive_service.dart';

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

class EditorPage extends StatefulWidget {
  final ContactProfile? existing;

  const EditorPage({super.key, this.existing});

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

  bool _saving = false;

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
    setState(() => _saving = true);
    try {
      final p = ContactProfile(
        pin: widget.existing?.pin, // čuva PIN kod editiranja, novi generira pri kreiranju
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
      await OneDriveService.save(p);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  Widget _buildSection({
    required String label,
    required List<TextEditingController> controllers,
    required VoidCallback onAdd,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              onPressed: onAdd,
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

  Widget _buildAddressSection() {
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
              onPressed: addAddress,
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
                  _field(a.street, "Ulica"),
                  const SizedBox(height: 10),
                  _field(a.city, "Grad"),
                  const SizedBox(height: 10),
                  _field(a.zip, "Poštanski broj",
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 10),
                  _field(a.country, "Država"),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildJobSection() {
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
                      icon: const Icon(Icons.close,
                          size: 18, color: Colors.red),
                      onPressed: () => setState(() => jobs.removeAt(i)),
                    ),
                  ),
                  _field(j.title, "Titula"),
                  const SizedBox(height: 10),
                  _field(j.department, "Odjel"),
                  const SizedBox(height: 10),
                  _field(j.company, "Kompanija"),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _field(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            _buildSection(
              label: "Broj telefona",
              controllers: phones,
              onAdd: addPhone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            _buildSection(
              label: "Email",
              controllers: emails,
              onAdd: addEmail,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            _buildJobSection(),
            const SizedBox(height: 20),
            _buildSection(
              label: "Web stranica",
              controllers: web,
              onAdd: addWeb,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 20),
            _buildAddressSection(),
            const SizedBox(height: 28),
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
                onPressed: _saving ? null : save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("Spremi", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
