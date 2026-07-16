import 'package:flutter_test/flutter_test.dart';
import 'package:paper_tracker/models/user_model.dart';

void main() {
  group('UserModel', () {
    final now = DateTime.now();
    final user = UserModel(
      uid: 'uid1',
      email: 'alice@test.com',
      displayName: 'Alice',
      photoUrl: 'https://example.com/photo.png',
      createdAt: now,
    );

    test('toMap and fromMap round-trip', () {
      final map = user.toMap();
      final restored = UserModel.fromMap(map);
      expect(restored.uid, user.uid);
      expect(restored.email, user.email);
      expect(restored.displayName, user.displayName);
    });

    test('equatable works', () {
      final same = user.copyWith();
      expect(user, same);
    });

    test('default values are empty', () {
      final minimal = UserModel(
        uid: 'u1',
        email: '',
        displayName: '',
        photoUrl: '',
        createdAt: now,
      );
      expect(minimal.email, isEmpty);
      expect(minimal.displayName, isEmpty);
    });
  });
}
