

import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {

  FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
          );
      return userCredential.user;
    } catch (e) {
      print("Error during sign up: $e");
      return null;


  }
}

  Future<User?> LoginWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.logInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print("Error during sign up: $e");
      return null;


    }
  }