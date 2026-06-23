import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/contact_profile.dart';

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
