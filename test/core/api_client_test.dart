import 'package:flutter_test/flutter_test.dart';
import 'package:umbraro/core/services/api_client.dart';

void main() {
  test('ApiException isNeedsRegistration when detail is map', () {
    final e = ApiException(404, 'x', detail: {
      'code': 'NEEDS_REGISTRATION',
      'message': 'm',
    });
    expect(e.isNeedsRegistration, isTrue);
  });
}
