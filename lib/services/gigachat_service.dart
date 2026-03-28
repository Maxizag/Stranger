import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:neznakomets/models/message.dart';
import 'package:neznakomets/services/gigachat_http_client_stub.dart'
    if (dart.library.io) 'package:neznakomets/services/gigachat_http_client_io.dart'
    as gigachat_http;
import 'package:uuid/uuid.dart';

const String kSystemPrompt = """
Ты анонимный собеседник в приложении «Незнакомец».
Люди приходят к тебе, чтобы сказать то, что не могут сказать никому.
Твоя роль — выслушать и помочь человеку разобраться в себе через диалог.
Правила:
1) Никогда не давай советов если тебя об этом не просят.
2) Никогда не осуждай и не оценивай действия человека.
3) Не используй психологические термины и не веди себя как психолог.
4) В конце каждого своего ответа задай один короткий вопрос — глубокий, немного неудобный, который заставляет думать. Просто задай вопрос, не объясняй почему ты его задаёшь.
5) Отвечай коротко: 2-4 предложения максимум.
6) Пиши на русском языке, разговорно, без канцелярита.
7) Ты не знаешь кто этот человек и никогда не узнаешь — это делает разговор особенно честным.

Важно: никогда не пиши про себя в третьем лице, не объясняй что ты собираешься сделать, не пиши 'а потом спрошу' или похожие мета-комментарии. Просто говори.
""";

/// Текст при сетевых ошибках чата (и для UI при сбое токена).
const String kGigachatFallbackReply =
    'не могу ответить прямо сейчас. попробуй ещё раз.';

/// Ошибка получения OAuth-токена (нужно отдельно от сетевых сбоев чата).
class GigachatTokenException implements Exception {
  GigachatTokenException(this.message);
  final String message;

  @override
  String toString() => message;
}

class GigachatService {
  GigachatService({http.Client? httpClient})
      : _client = httpClient ?? _createHttpClient();

  static const String _oauthUrl =
      'https://ngw.devices.sberbank.ru:9443/api/v2/oauth';
  static const String _chatUrl =
      'https://gigachat.devices.sberbank.ru/api/v1/chat/completions';

  final http.Client _client;
  final Uuid _uuid = const Uuid();

  String? _accessToken;
  DateTime? _tokenExpiresAt;

  /// Web (Chrome): обычный [http.Client]. Нативно — [IOClient] без проверки SSL для API Сбера.
  static http.Client _createHttpClient() {
    if (kIsWeb) {
      return http.Client();
    }
    return gigachat_http.createGigachatHttpClient();
  }

  Future<String> _ensureToken() async {
    final now = DateTime.now();
    if (_accessToken != null &&
        _tokenExpiresAt != null &&
        now.isBefore(_tokenExpiresAt!.subtract(const Duration(seconds: 30)))) {
      return _accessToken!;
    }
    await _fetchToken();
    final t = _accessToken;
    if (t == null || t.isEmpty) {
      throw GigachatTokenException(
        'Не удалось получить токен GigaChat: пустой access_token',
      );
    }
    return t;
  }

  Future<void> _fetchToken() async {
    final uri = Uri.parse(_oauthUrl);
    final clientId = dotenv.env['GIGACHAT_CLIENT_ID']!.trim();
    final authKey = dotenv.env['GIGACHAT_AUTH_KEY']!.trim();
    final credentials = '$clientId:$authKey';
    final base64Credentials = base64Encode(utf8.encode(credentials));
    const bodyString = 'scope=GIGACHAT_API_PERS';

    final request = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/x-www-form-urlencoded'
      ..headers['Accept'] = 'application/json'
      ..headers['RqUID'] = _uuid.v4()
      ..headers['Authorization'] = 'Basic $base64Credentials'
      ..body = bodyString;

    // ignore: avoid_print
    print('Auth header: Basic $base64Credentials');
    // ignore: avoid_print
    print('URL: ${request.url}');
    // ignore: avoid_print
    print('Body: ${request.body}');

    try {
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode != 200) {
        final body = utf8.decode(response.bodyBytes);
        debugPrint(
          'GigaChat OAuth error: status=${response.statusCode} body=$body',
        );
        throw GigachatTokenException(
          'Не удалось получить токен GigaChat: HTTP ${response.statusCode}',
        );
      }

      final map =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final token = map['access_token'] as String?;
      if (token == null || token.isEmpty) {
        debugPrint('GigaChat OAuth: нет access_token в ответе: $map');
        throw GigachatTokenException(
          'Не удалось получить токен GigaChat: в ответе нет access_token',
        );
      }
      _accessToken = token;
      _tokenExpiresAt = _parseExpiry(map);
      debugPrint(
        'GigaChat OAuth: токен получен, истекает: $_tokenExpiresAt',
      );
    } on GigachatTokenException {
      rethrow;
    } catch (e, st) {
      debugPrint('GigaChat OAuth exception: $e\n$st');
      throw GigachatTokenException(
        'Не удалось получить токен GigaChat: $e',
      );
    }
  }

  /// Разбор срока действия: `expires_at` (unix) или `expires_in` (секунды).
  DateTime _parseExpiry(Map<String, dynamic> map) {
    final at = map['expires_at'];
    if (at is int) {
      if (at > 20000000000) {
        return DateTime.fromMillisecondsSinceEpoch(at);
      }
      return DateTime.fromMillisecondsSinceEpoch(at * 1000);
    }
    if (at is String) {
      final parsed = int.tryParse(at);
      if (parsed != null) {
        return parsed > 20000000000
            ? DateTime.fromMillisecondsSinceEpoch(parsed)
            : DateTime.fromMillisecondsSinceEpoch(parsed * 1000);
      }
    }
    final sec = map['expires_in'];
    if (sec is int) {
      return DateTime.now().add(Duration(seconds: sec));
    }
    return DateTime.now().add(const Duration(minutes: 25));
  }

  List<Map<String, String>> _buildMessages(List<Message> history) {
    final tail = history.length > 10
        ? history.sublist(history.length - 10)
        : List<Message>.from(history);
    return [
      {'role': 'system', 'content': kSystemPrompt.trim()},
      ...tail.map(
        (m) => {
          'role': m.isUser ? 'user' : 'assistant',
          'content': m.text,
        },
      ),
    ];
  }

  Future<String> sendMessage({
    required List<Message> history,
    required String userText,
  }) async {
    assert(
      history.isEmpty ||
          (history.last.isUser && history.last.text == userText),
      'history должен заканчиваться сообщением пользователя с текстом userText',
    );

    try {
      final token = await _ensureToken();
      final messages = _buildMessages(history);

      final bodyMap = <String, dynamic>{
        'model': 'GigaChat',
        'messages': messages,
        'max_tokens': 300,
        'temperature': 0.8,
      };
      final body = jsonEncode(bodyMap);

      final response = await _client
          .post(
            Uri.parse(_chatUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        debugPrint(
          'GigaChat chat error: status=${response.statusCode} '
          'body=${utf8.decode(response.bodyBytes)}',
        );
        return kGigachatFallbackReply;
      }

      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final choices = data['choices'];
      if (choices is! List || choices.isEmpty) {
        debugPrint('GigaChat chat: нет choices в ответе: $data');
        return kGigachatFallbackReply;
      }
      final first = choices.first;
      if (first is! Map<String, dynamic>) {
        return kGigachatFallbackReply;
      }
      final msg = first['message'];
      if (msg is! Map<String, dynamic>) {
        return kGigachatFallbackReply;
      }
      final content = msg['content'];
      if (content is! String || content.trim().isEmpty) {
        debugPrint('GigaChat chat: пустой content: $msg');
        return kGigachatFallbackReply;
      }
      return content.trim();
    } on GigachatTokenException catch (e, st) {
      debugPrint('GigaChatTokenException: $e\n$st');
      rethrow;
    } catch (e, st) {
      debugPrint('GigaChat sendMessage error: $e\n$st');
      return kGigachatFallbackReply;
    }
  }
}
