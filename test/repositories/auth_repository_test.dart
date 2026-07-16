import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:paper_tracker/repositories/auth_repository.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseDatabase extends Mock implements FirebaseDatabase {}
class MockUser extends Mock implements User {
  @override
  String get uid => 'uid1';
  @override
  String? get email => 'test@example.com';
  @override
  String? get displayName => 'Test User';
  @override
  String? get photoURL => '';
}
class MockUserCredential extends Mock implements UserCredential {
  @override
  User? get user => MockUser();
}
class MockDatabaseReference extends Mock implements DatabaseReference {}
class MockDatabaseEvent extends Mock implements DatabaseEvent {}
class MockDataSnapshot extends Mock implements DataSnapshot {}

void main() {
  late MockFirebaseAuth mockAuth;
  late MockFirebaseDatabase mockDb;
  late AuthRepository repository;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockDb = MockFirebaseDatabase();
    repository = AuthRepository(firebaseAuth: mockAuth, db: mockDb);
  });

  group('AuthRepository', () {
    test('currentUser returns FirebaseAuth currentUser', () {
      when(() => mockAuth.currentUser).thenReturn(MockUser());
      expect(repository.currentUser, isNotNull);
    });

    test('signInWithEmail delegates to FirebaseAuth', () async {
      when(() => mockAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => MockUserCredential());

      final result = await repository.signInWithEmail(
        'test@example.com',
        'password',
      );
      expect(result, isNotNull);
    });

    test('authStateChanges returns the Firebase stream', () {
      when(() => mockAuth.authStateChanges()).thenAnswer((_) => const Stream.empty());
      expect(repository.authStateChanges, isA<Stream<User?>>());
    });
  });
}
