import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umbraro/core/storage/token_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('TokenStore migrates legacy shared_preferences keys into memory store', () async {
    SharedPreferences.setMockInitialValues({
      'access_token': 'acc-legacy',
      'refresh_token': 'ref-legacy',
    });
    final prefs = await SharedPreferences.getInstance();
    final mem = <String, String>{};
    final store = TokenStore(memory: mem, prefsTest: prefs);

    final pair = await store.read();
    expect(pair?.access, 'acc-legacy');
    expect(pair?.refresh, 'ref-legacy');
    expect(mem['umbraro_access_token'], 'acc-legacy');
    expect(mem['umbraro_refresh_token'], 'ref-legacy');
    expect(prefs.getString('access_token'), isNull);
    expect(prefs.getString('refresh_token'), isNull);
  });
}
