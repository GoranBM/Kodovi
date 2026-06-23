import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/contact_profile.dart';
import 'auth_service.dart';

class OneDriveService {
  static const _base = 'https://graph.microsoft.com/v1.0';
  static const _folder = 'vizitka';

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {'Authorization': 'Bearer $token'};
  }

  static Future<void> ensureFolder() async {
    final h = await _headers();
    final res = await http.get(
      Uri.parse('$_base/me/drive/root:/$_folder'),
      headers: h,
    );
    if (res.statusCode == 404) {
      await http.post(
        Uri.parse('$_base/me/drive/root/children'),
        headers: {...h, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _folder,
          'folder': {},
          '@microsoft.graph.conflictBehavior': 'fail',
        }),
      );
    }
  }

  static Future<List<ContactProfile>> loadAll() async {
    await ensureFolder();
    final h = await _headers();
    final res = await http.get(
      Uri.parse('$_base/me/drive/root:/$_folder:/children?\$select=name'),
      headers: h,
    );
    if (res.statusCode != 200) return [];

    final items = (jsonDecode(res.body)['value'] as List)
        .where((item) => (item['name'] as String).endsWith('.json'))
        .toList();

    final profiles = <ContactProfile>[];
    for (final item in items) {
      final fileRes = await http.get(
        Uri.parse('$_base/me/drive/root:/$_folder/${item['name']}:/content'),
        headers: h,
      );
      if (fileRes.statusCode == 200) {
        profiles.add(ContactProfile.fromJson(
            jsonDecode(utf8.decode(fileRes.bodyBytes))));
      }
    }
    return profiles;
  }

  static Future<void> save(ContactProfile profile) async {
    final h = await _headers();
    await http.put(
      Uri.parse(
          '$_base/me/drive/root:/$_folder/${profile.pin}.json:/content'),
      headers: {...h, 'Content-Type': 'application/octet-stream'},
      body: utf8.encode(jsonEncode(profile.toJson())),
    );
  }

  static Future<void> delete(ContactProfile profile) async {
    final h = await _headers();
    await http.delete(
      Uri.parse('$_base/me/drive/root:/$_folder/${profile.pin}.json'),
      headers: h,
    );
  }
}
