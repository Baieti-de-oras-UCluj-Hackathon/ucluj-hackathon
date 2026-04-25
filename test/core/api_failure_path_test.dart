import 'package:flutter_test/flutter_test.dart';
import 'package:umbraro/core/services/api_client.dart';

void main() {
  test('ApiException 403 detail without NEEDS is not needs registration', () {
    final e = ApiException(403, 'forbidden', detail: {'code': 'OTHER'});
    expect(e.isNeedsRegistration, isFalse);
  });
}
