import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:paper_tracker/models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseDatabase _db;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseDatabase? db,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseDatabase.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<User?> signInWithEmail(String email, String password) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  Future<User?> signUpWithEmail(
      String email, String password, String displayName) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      await user.updateDisplayName(displayName);
      await _createUserDocument(user, displayName: displayName);
    }
    return user;
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<void> _createUserDocument(User user, {String? displayName}) async {
    final userModel = UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: displayName ?? user.displayName ?? '',
      photoUrl: user.photoURL ?? '',
      createdAt: DateTime.now(),
    );
    await _db.ref('users/${user.uid}').set(userModel.toMap());
  }

  Future<UserModel?> getUserById(String uid) async {
    final snapshot = await _db.ref('users/$uid').get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return UserModel.fromMap(data);
    }
    return null;
  }

  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    final snapshot = await _db.ref('users').get();
    if (!snapshot.exists) return [];
    final results = <UserModel>[];
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final lowerQuery = query.toLowerCase();
    data.forEach((key, value) {
      final user = UserModel.fromMap(Map<String, dynamic>.from(value));
      if (user.email.toLowerCase().contains(lowerQuery) ||
          user.displayName.toLowerCase().contains(lowerQuery)) {
        results.add(user);
      }
    });
    return results.take(10).toList();
  }
}
