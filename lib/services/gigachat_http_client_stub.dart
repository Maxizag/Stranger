import 'package:http/http.dart' as http;

/// Web и прочие платформы без `dart:io`: обычный клиент (без обхода SSL).
http.Client createGigachatHttpClient() => http.Client();
