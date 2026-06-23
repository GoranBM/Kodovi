import 'package:web/web.dart';

void navigateTo(String url) => window.location.href = url;
void cleanUrl() => window.history.replaceState(null, '', '/');
void saveLocal(String key, String value) =>
    window.localStorage.setItem(key, value);
String? readLocal(String key) => window.localStorage.getItem(key);
void removeLocal(String key) => window.localStorage.removeItem(key);
