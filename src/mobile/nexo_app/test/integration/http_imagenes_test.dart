import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/data/http_nexo_api.dart';
import 'package:nexo_app/data/nexo_api.dart';

import '../support/mock_adapter.dart';

/// Spec 036 · grupo `imagenes`: subida en tres pasos.
void main() {
  test('pide URL firmada, sube con PUT y confirma', () async {
    final a = MockAdapter();
    final storage = MockAdapter();
    a.on('POST', '/v1/discovery/uploads', {
      'uploadId': 'upl_1',
      'uploadUrl': 'https://storage.nexo.test/bucket/upl_1?sig=abc',
      'headers': {'Content-Type': 'image/jpeg', 'x-ms-blob-type': 'BlockBlob'},
    });
    a.on('POST', '/v1/discovery/uploads/upl_1/complete', {'status': 'ready'});
    storage.on('PUT', '/bucket/upl_1', null, status: 201);
    final api = HttpNexoApi(testDio(a), uploadDio: Dio()..httpClientAdapter = storage);
    final id = await api.upload(
      PickedImage(path: '/tmp/foto.jpg', bytes: Uint8List.fromList(List.filled(2048, 7)), contentType: 'image/jpeg', width: 800, height: 600),
      purpose: 'work',
    );
    expect(id, 'upl_1');
    final ticket = a.last('POST', '/v1/discovery/uploads').body as Map;
    expect(ticket, {'purpose': 'work', 'contentType': 'image/jpeg', 'size': 2048, 'width': 800, 'height': 600});
    final put = storage.last('PUT', '/bucket/upl_1');
    expect(put.host, 'storage.nexo.test');
    expect(put.header('x-ms-blob-type'), 'BlockBlob');
    expect(a.calls.last.path, '/v1/discovery/uploads/upl_1/complete');
  });
}
