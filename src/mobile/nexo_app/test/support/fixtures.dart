import 'dart:convert';

import 'package:nexo_app/core/auth/auth_tokens.dart';
import 'package:nexo_app/core/auth/token_storage.dart';

/// Respuestas con la forma de `docs/endpoints` (contratos del backend).
class Fx {
  Fx._();

  static Map<String, Object?> provider({String id = 'prv_1', String name = 'Hernández Plomería'}) => {
        'providerId': id,
        'kind': 'business',
        'name': name,
        'owner': 'Carlos Hernández',
        'categories': ['plomeria'],
        'specialties': ['Fugas y reparaciones'],
        'bio': 'Fugas, llaves y boilers.',
        'attention': 'both',
        'attentionText': 'Local y a domicilio',
        'distanceKm': 0.4,
        'distanceText': 'a 400 m',
        'publicZone': {
          'label': 'Centro',
          'point': {'lat': 20.05, 'lng': -99.34},
        },
        'radiusKm': 5,
        'schedule': {
          'days': [
            {'open': '08:00', 'close': '18:00'},
            null,
            null,
            null,
            null,
            null,
            null,
          ],
          'urgent': true,
        },
        'status': {'open': true, 'text': 'Abierto ahora · cierra a las 18:00'},
        'visit': {'mode': 'paid', 'text': r'Visita $200'},
        'minPrice': {'fromCents': 35000, 'text': r'Desde $350'},
        'prices': [
          {'service': 'Reparación de fuga', 'fromCents': 35000, 'unit': 'from', 'suffix': ''},
        ],
        'payment': ['Efectivo', 'Transferencia'],
        'responseTime': 'Menos de 1 hora',
        'warranty': '30 días',
        'invoice': true,
        'badges': [
          {'key': 'phoneVerified', 'level': 'verified', 'label': 'Teléfono confirmado'},
        ],
        'trust': {
          'userOpinion': {
            'rating': {'avg': 4.8, 'count': 12},
            'recs': 31,
          },
        },
        'channels': {'chat': true, 'call': false},
        'jobs': 24,
        'updatedText': 'Actualizado ayer',
      };

  static Map<String, Object?> work({String id = 'wrk_1'}) => {
        'workId': id,
        'provider': {'providerId': 'prv_1', 'name': 'Hernández Plomería', 'kind': 'business', 'badges': ['phoneVerified']},
        'category': 'plomeria',
        'title': 'Cambio de llave',
        'textExcerpt': 'Sustituimos la llave de cocina.',
        'images': [
          {'url': 'https://cdn.nexo.test/w/1.jpg', 'thumbUrl': 'https://cdn.nexo.test/w/1_t.jpg'},
        ],
        'zoneLabel': 'Centro',
        'distanceText': 'a 300 m',
        'recs': 12,
        'tag': 'Antes y después',
        'ago': 'hace 2 h',
        'saved': false,
        'recommended': false,
        'canContact': true,
      };

  static Map<String, Object?> request({String id = 'req_1', bool mine = false}) => {
        'requestId': id,
        'category': 'plomeria',
        'title': 'Fuga debajo del lavabo',
        'description': 'Hay una fuga y el piso está húmedo.',
        'urgency': 'today',
        'urgencyText': 'Hoy',
        'zoneLabel': 'Centro',
        'distanceText': 'a 800 m',
        'status': 'open',
        'interestCount': 2,
        'interestedPreview': [
          {'providerId': 'prv_1', 'name': 'Hernández Plomería'},
        ],
        'interestedMoreCount': 1,
        'summaryText': '2 interesados',
        'ago': 'hace 40 min',
        'iAmInterested': false,
        'inMyRadius': true,
        'matchesMyService': true,
        'client': {'displayName': 'Ana M.'},
      };

  static Map<String, Object?> order({String id = 'ord_1', String status = 'pending', String role = 'provider', int version = 3}) => {
        'orderId': id,
        'status': status,
        'statusText': 'Pendiente',
        'role': role,
        'counterpart': {'accountId': 'acc_9', 'displayName': 'Laura G.', 'kind': 'client', 'canCopyPhone': false},
        'category': 'plomeria',
        'description': 'Revisar la fuga del calentador.',
        'attention': 'home',
        'placeZone': 'Centro',
        'version': version,
        'allowedActions': ['accept', 'reject', 'message'],
      };

  static Map<String, Object?> page(List<Object?> items, {String? next}) =>
      {'items': items, 'nextCursor': next, 'hasMore': next != null};
}

/// JWT sin firma válida, solo para leer claims en pruebas.
String fakeJwt(Map<String, Object?> claims) {
  String part(Object o) => base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${part({'alg': 'ES256'})}.${part(claims)}.firma';
}

AuthTokens fakeTokens({String sub = 'acc_1', String mode = 'client', bool hasProvider = false}) => AuthTokens(
      accessToken: fakeJwt({'sub': sub, 'mode': mode, 'has_provider': hasProvider}),
      refreshToken: 'refresh-$sub',
      expiresAt: DateTime.now().add(const Duration(minutes: 10)),
    );

/// Almacenamiento en memoria en lugar del Keystore.
class MemoryTokenStorage extends TokenStorage {
  MemoryTokenStorage();
  final Map<String, String> data = {};

  @override
  Future<AuthTokens?> read() async {
    final a = data['access'], r = data['refresh'];
    if (a == null || r == null) return null;
    return AuthTokens(accessToken: a, refreshToken: r, expiresAt: DateTime.now().add(const Duration(minutes: 5)));
  }

  @override
  Future<void> write(AuthTokens t) async {
    data['access'] = t.accessToken;
    data['refresh'] = t.refreshToken;
  }

  @override
  Future<String?> readName() async => data['name'];

  @override
  Future<void> writeName(String? name) async {
    if (name == null || name.isEmpty) {
      data.remove('name');
    } else {
      data['name'] = name;
    }
  }

  @override
  Future<String?> readMode() async => data['mode'];

  @override
  Future<void> writeMode(String? mode) async {
    if (mode == null) {
      data.remove('mode');
    } else {
      data['mode'] = mode;
    }
  }

  @override
  Future<String?> readDeviceId() async => data['device'];

  @override
  Future<void> writeDeviceId(String? id) async {
    if (id == null || id.isEmpty) {
      data.remove('device');
    } else {
      data['device'] = id;
    }
  }

  @override
  Future<bool> readPushAsked() async => data['pushAsked'] == '1';

  @override
  Future<void> writePushAsked() async {
    data['pushAsked'] = '1';
  }

  @override
  Future<void> clear() async => data.clear();
}
