import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meditrackmobile/features/auth/models/user.dart';
import 'package:meditrackmobile/features/auth/services/session.dart';

void main() {
  final session = Session.instance;
  final user = User(
    id: 'user-1',
    nom: 'Doe',
    prenom: 'Jane',
    email: 'jane@example.com',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await session.clear();
  });

  test(
    'sign out preserves remembered credentials without activating token',
    () async {
      await session.start('saved-token', user, remember: true);

      expect(await session.signOut(), isTrue);
      expect(session.token, isNull);
      expect(await session.wasExplicitlySignedOut, isTrue);
      expect(await session.loadSavedUserId(), 'user-1');
      expect(session.token, isNull);

      expect(await session.activateSavedToken(), isTrue);
      expect(session.token, 'saved-token');
    },
  );

  test('sign out clears credentials when remember was disabled', () async {
    await session.start('temporary-token', user, remember: false);

    expect(await session.signOut(), isFalse);
    expect(await session.loadSavedUserId(), isNull);
    expect(await session.wasExplicitlySignedOut, isFalse);
  });
}
