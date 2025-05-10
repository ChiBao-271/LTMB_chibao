import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cuoiky/CuoiKy/services/auth_service.dart';
import 'package:cuoiky/CuoiKy/view/register_screen.dart';
import 'package:cuoiky/CuoiKy/view/forgot_password_screen.dart';
import 'package:cuoiky/CuoiKy/view/task_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  void _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      setState(() {
        _isLoading = false;
      });
      if (user != null) {
        print('User UID: ${user.uid}');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TaskListScreen()),
        );
      } else {
        setState(() {
          _errorMessage = 'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = await _authService.signInWithGoogle();
      setState(() {
        _isLoading = false;
      });
      if (user != null) {
        print('User UID: ${user.uid}');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TaskListScreen()),
        );
      } else {
        setState(() {
          _errorMessage = 'Đăng nhập bằng Google thất bại. Vui lòng thử lại.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.cyan[50]!, Colors.teal[50]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Biểu tượng
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.teal[50],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.task_alt,
                      size: 80,
                      color: Colors.teal[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Tiêu đề
                  Text(
                    'Đăng nhập',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[700],
                      shadows: const [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Form đăng nhập
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(24.0),
                      color: Colors.white.withOpacity(0.95),
                      child: Column(
                        children: [
                          // Trường email
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: TextStyle(color: Colors.teal[700]),
                              prefixIcon: Icon(Icons.email, color: Colors.teal[600]),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.teal[600]!, width: 2),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          // Trường mật khẩu
                          TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Mật khẩu',
                              labelStyle: TextStyle(color: Colors.teal[700]),
                              prefixIcon: Icon(Icons.lock, color: Colors.teal[600]),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.teal[600],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.teal[600]!, width: 2),
                              ),
                            ),
                            obscureText: !_isPasswordVisible,
                          ),
                          // Thông báo lỗi
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red, fontSize: 14),
                              ),
                            ),
                          const SizedBox(height: 24),
                          // Nút đăng nhập
                          _isLoading
                              ? const SpinKitCircle(color: Colors.teal, size: 50.0)
                              : Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.teal[600]!, Colors.teal[400]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: const Text(
                                'Đăng nhập',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Nút đăng nhập bằng Google
                          _isLoading
                              ? const SizedBox()
                              : SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _loginWithGoogle,
                              icon: FaIcon(
                                FontAwesomeIcons.google,
                                color: Colors.teal[600],
                                size: 20,
                              ),
                              label: Text(
                                'Đăng nhập bằng Google',
                                style: TextStyle(
                                  color: Colors.teal[600],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                side: BorderSide(color: Colors.teal[600]!, width: 2),
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Nút "Quên mật khẩu?"
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                      ),
                      child: Text(
                        'Quên mật khẩu?',
                        style: TextStyle(
                          color: Colors.teal[600],
                          fontSize: 13,
                          shadows: const [
                            Shadow(
                              color: Colors.black12,
                              offset: Offset(0.5, 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Nút điều hướng
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterScreen()),
                    ),
                    child: Text(
                      'Chưa có tài khoản? Đăng ký ngay',
                      style: TextStyle(
                        color: Colors.teal[600],
                        fontSize: 16,
                        shadows: const [
                          Shadow(
                            color: Colors.black12,
                            offset: Offset(0.5, 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}