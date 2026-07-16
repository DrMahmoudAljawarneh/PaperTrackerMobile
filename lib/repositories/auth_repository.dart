import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:paper_tracker/models/user_model.dart';
import 'package:paper_tracker/utils/cache.dart';
import 'package:paper_tracker/utils/firebase_utils.dart';

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

  Future<void> updateDisplayName(String displayName) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;
    await user.updateDisplayName(displayName);
    await user.reload();
    // Also update in RTDB
    await _db.ref('users/${user.uid}/displayName').set(displayName);
  }

  Future<void> sendPasswordReset(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateOrcidId(String orcidId) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;
    await _db.ref('users/${user.uid}/orcidId').set(orcidId);
  }

  Future<void> signOut() async {
    _allUsersCache.invalidate();
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
      final data = safeCastMap(snapshot.value);
      return UserModel.fromMap(data);
    }
    return null;
  }

  final TtlCache<List<UserModel>> _allUsersCache = TtlCache(ttlMinutes: 10);

  Future<List<UserModel>> _getAllUsersCached() async {
    final cached = _allUsersCache.value;
    if (cached != null) return cached;
    final snapshot = await _db.ref('users').get();
    if (!snapshot.exists) return [];
    final data = safeCastMap(snapshot.value);
    final users = data.entries
        .map((e) => UserModel.fromMap(safeCastMap(e.value)))
        .toList();
    _allUsersCache.set(users);
    return users;
  }

  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    final allUsers = await _getAllUsersCached();
    final lowerQuery = query.toLowerCase();
    return allUsers
        .where((u) =>
            u.email.toLowerCase().contains(lowerQuery) ||
            u.displayName.toLowerCase().contains(lowerQuery))
        .take(10)
        .toList();
  }
}
