import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/models/user_profile.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static final Future<void>
  _googleSignInInitialization = _googleSignIn.initialize(
    serverClientId:
        '746414767673-gbhe98fnqr2qg664o8iiqjm6m2aosdao.apps.googleusercontent.com',
  );

  Future<void> _ensureGoogleSignInInitialized() async {
    await _googleSignInInitialization;
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _createUserProfile(credential.user!.uid, name);
      }

      return credential;
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate(
        scopeHint: const <String>['email', 'profile'],
      );

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
        throw Exception('Failed to get ID token from Google');
      }

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null &&
          userCredential.additionalUserInfo?.isNewUser == true) {
        await _createUserProfile(
          userCredential.user!.uid,
          userCredential.user!.displayName ?? 'User',
        );
      }

      return userCredential;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        throw Exception('Google sign in was cancelled');
      }
      final String reason = e.description ?? e.code.name;
      throw Exception('Google sign in failed: $reason');
    } catch (e) {
      throw Exception('Google sign in failed: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    await _ensureGoogleSignInInitialized();
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> _createUserProfile(String uid, String name) async {
    await _firestore.collection('users').doc(uid).set({
      'profile': {'name': name, 'conditions': [], 'caregiverIds': []},
    }, SetOptions(merge: true));
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;

    final data = doc.data();
    final profileData = data?['profile'] as Map<String, dynamic>?;
    if (profileData == null) return null;

    return UserProfile.fromMap(uid, profileData);
  }

  Future<void> updateUserProfile(String uid, UserProfile profile) async {
    await _firestore.collection('users').doc(uid).update({
      'profile': profile.toMap(),
    });
  }
}
