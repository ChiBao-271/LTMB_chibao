import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/auth_model.dart';
import '../models/user.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateDisplayName(String displayName) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
    } catch (e) {
      throw Exception('Cập nhật tên hiển thị thất bại: $e');
    }
  }

  AuthModel? _userFromFirebaseUser(firebase_auth.User? user) {
    return user != null
        ? AuthModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
    )
        : null;
  }

  Stream<AuthModel?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }

  Future<AuthModel?> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      firebase_auth.UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      firebase_auth.User? user = result.user;

      // Tạo user trong Firestore sau khi đăng ký
      if (user != null) {
        final newUser = User(
          id: user.uid,
          username: user.email?.split('@')[0] ?? 'unknown',
          password: '',
          email: user.email ?? '',
          avatar: null,
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
          role: 'user',
        );
        await _firestore.collection('users').doc(newUser.id).set(newUser.toMap());
      }

      return _userFromFirebaseUser(user);
    } catch (e) {
      throw Exception('Đăng ký thất bại: $e');
    }
  }

  Future<AuthModel?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      firebase_auth.UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      firebase_auth.User? user = result.user;
      return _userFromFirebaseUser(user);
    } catch (e) {
      throw Exception('Đăng nhập thất bại: $e');
    }
  }

  Future<AuthModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Bạn đã hủy đăng nhập bằng Google');
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      firebase_auth.UserCredential userCredential = await _auth.signInWithCredential(credential);
      firebase_auth.User? user = userCredential.user;

      // Tạo user trong Firestore nếu chưa tồn tại
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          final newUser = User(
            id: user.uid,
            username: user.email?.split('@')[0] ?? 'unknown',
            password: '',
            email: user.email ?? '',
            avatar: null,
            createdAt: DateTime.now(),
            lastActive: DateTime.now(),
            role: 'user',
          );
          await _firestore.collection('users').doc(newUser.id).set(newUser.toMap());
        }
      }

      return _userFromFirebaseUser(user);
    } catch (e) {
      print('Lỗi đăng nhập Google: $e');
      throw Exception('Đăng nhập bằng Google thất bại: $e');
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      throw Exception('Gửi email đặt lại mật khẩu thất bại: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      throw Exception('Đăng xuất thất bại: $e');
    }
  }
}