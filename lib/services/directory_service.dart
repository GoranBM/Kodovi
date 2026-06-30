import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class DirectoryContact {
  final String id;
  final String displayName;
  final String jobTitle;
  final String mobilePhone;
  final List<String> businessPhones;
  final String department;
  final String mail;

  const DirectoryContact({
    required this.id,
    required this.displayName,
    required this.jobTitle,
    required this.mobilePhone,
    required this.businessPhones,
    required this.department,
    required this.mail,
  });

  factory DirectoryContact.fromJson(Map<String, dynamic> json) =>
      DirectoryContact(
        id: json['id'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        jobTitle: json['jobTitle'] as String? ?? '',
        mobilePhone: json['mobilePhone'] as String? ?? '',
        businessPhones: List<String>.from(json['businessPhones'] ?? []),
        department: json['department'] as String? ?? '',
        mail: json['mail'] as String? ?? '',
      );

  List<String> get allPhones => [
        if (mobilePhone.isNotEmpty) mobilePhone,
        ...businessPhones,
      ];

  String toVCard() {
    final lines = <String>[
      'BEGIN:VCARD',
      'VERSION:3.0',
      'FN:$displayName',
      'N:$displayName;;;;',
    ];
    for (final p in allPhones) {
      lines.add('TEL;TYPE=WORK,VOICE:$p');
    }
    if (mail.isNotEmpty) lines.add('EMAIL;TYPE=WORK:$mail');
    if (jobTitle.isNotEmpty) lines.add('TITLE:$jobTitle');
    if (department.isNotEmpty) lines.add('ORG:$department');
    lines.add('END:VCARD');
    return '${lines.join('\r\n')}\r\n';
  }
}

class DirectoryService {
  static const _base = 'https://graph.microsoft.com/v1.0';

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'ConsistencyLevel': 'eventual',
    };
  }

  /// Dohvati sve licencirane korisnike tenanta, sortirane abecedno.
  static Future<List<DirectoryContact>> getUsers() async {
    final h = await _headers();
    final all = <DirectoryContact>[];

    String? url = '$_base/users'
        r'?$select=id,displayName,jobTitle,mobilePhone,businessPhones,department,mail,assignedLicenses'
        r'&$filter=assignedLicenses/$count ne 0'
        r'&$count=true'
        r'&$top=999';

    while (url != null) {
      final res = await http.get(Uri.parse(url), headers: h);
      if (res.statusCode != 200) {
        throw Exception('${res.statusCode}');
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final users = (body['value'] as List)
          .map((u) => DirectoryContact.fromJson(u as Map<String, dynamic>))
          .where((u) => u.displayName.isNotEmpty && u.allPhones.isNotEmpty)
          .toList();
      all.addAll(users);
      url = body['@odata.nextLink'] as String?;
    }

    all.sort((a, b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return all;
  }
}
