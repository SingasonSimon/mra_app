import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/models/user_profile.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // GoogleSignIn instance with serverClientId for Android
  // The serverClientId is the Web Client ID from Firebase Console
  // Get it from: Firebase Console > Authentication > Sign-in method > Google > Web Client ID
  // For Android, you need the Web application OAuth 2.0 Client ID, not the Android client ID
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Use Web Client ID from Firebase Console > Authentication > Sign-in method > Google
    // This is different from the Android client ID in google-services.json
    // If you haven't created a Web app, create one and get its OAuth 2.0 Client ID
    serverClientId: '746414767673-gbhe98fnqr2qg664o8iiqjm6m2aosdao.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

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
      // Trigger the authentication flow
      // For v7.2.0+, use signIn() instead of authenticate()
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        throw Exception('Google sign in was cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.idToken == null) {
        throw Exception('Failed to get ID token from Google');
      }
      
      // Create a new credential
      // For Android with Firebase Auth, idToken is required, accessToken is optional
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken, // May be null on Android, that's OK
      );

      // Once signed in, return the UserCredential
      final userCredential = await _auth.signInWithCredential(credential);

      // Create profile if new user
      if (userCredential.user != null && userCredential.additionalUserInfo?.isNewUser == true) {
        await _createUserProfile(
          userCredential.user!.uid,
          userCredential.user!.displayName ?? 'User',
        );
      }

      return userCredential;
    } catch (e) {
      throw Exception('Google sign in failed: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> _createUserProfile(String uid, String name) async {
    await _firestore.collection('users').doc(uid).set({
      'profile': {
        'name': name,
        'conditions': [],
        'caregiverIds': [],
      },
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

