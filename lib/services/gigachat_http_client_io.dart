import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Android / iOS / desktop: `IOClient` с отключённой проверкой сертификата (GigaChat / Сбер).
http.Client createGigachatHttpClient() {
  final ioHttp = HttpClient();
  ioHttp.badCertificateCallback = (cert, host, port) => true;
  return IOClient(ioHttp);
}
