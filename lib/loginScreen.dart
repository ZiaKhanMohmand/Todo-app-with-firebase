import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:metapi_todo_app/forgotPassword.dart';
import 'package:metapi_todo_app/signupScreen.dart';
import 'package:metapi_todo_app/dashboard.dart';

class LoginScreen extends StatefulWidget {
  // ✅ Accept signup data passed from SignupScreen
  final String? pendingName;
  final String? pendingPhone;
  final String? pendingGender;

  const LoginScreen({
    super.key,
    this.pendingName,
    this.pendingPhone,
    this.pendingGender,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ✅ Controllers inside state class (not global)
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  String? emailError;
  String? passwordError;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool isValidEmail(String email) {
    return RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email);
  }

  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    setState(() {
      emailError = null;
      passwordError = null;
    });

    if (email.isEmpty) {
      setState(() => emailError = "Email is required");
      return;
    }

    if (!isValidEmail(email)) {
      setState(() => emailError = "Enter a valid email");
      return;
    }

    if (password.isEmpty) {
      setState(() => passwordError = "Password is required");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();

      if (!mounted) return;

      final refreshedUser = FirebaseAuth.instance.currentUser;

      // ❌ Email not verified — block login
      if (refreshedUser != null && !refreshedUser.emailVerified) {
        await refreshedUser.sendEmailVerification();
        await FirebaseAuth.instance.signOut();

        setState(() {
          emailError =
              "Please verify your email first. A new verification email has been sent.";
        });
        return;
      }

      // ✅ Email is verified — now save to Firestore if not already saved
      if (refreshedUser != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(refreshedUser.uid)
            .get();

        if (!doc.exists) {
          // ✅ First time login after verification — save all user data
          await FirebaseFirestore.instance
              .collection('users')
              .doc(refreshedUser.uid)
              .set({
                'name': widget.pendingName ?? '',
                'phone': widget.pendingPhone ?? '',
                'gender': widget.pendingGender ?? '',
                'email': refreshedUser.email ?? email,
                'createdAt': FieldValue.serverTimestamp(),
              });
        }
      }

      if (!mounted) return;

      // ✅ Go to Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Dashboard()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        emailError = null;
        passwordError = null;

        switch (e.code) {
          case 'user-not-found':
            emailError = "No account found with this email";
            break;
          case 'wrong-password':
            passwordError = "Incorrect password";
            break;
          case 'invalid-email':
            emailError = "Invalid email format";
            break;
          case 'user-disabled':
            emailError = "This account has been disabled";
            break;
          case 'too-many-requests':
            emailError = "Too many attempts. Try again later";
            break;
          case 'network-request-failed':
            emailError = "No internet connection";
            break;
          case 'invalid-credential':
            emailError = "Invalid email or password";
            passwordError = "Check your credentials";
            break;
          case 'operation-not-allowed':
            emailError = "Login is not enabled for this account";
            break;
          case 'user-token-expired':
            emailError = "Session expired. Please sign in again.";
            break;
          default:
            emailError = e.message ?? "Authentication failed";
            break;
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              Text(
                "Welcome Back",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Login to your account",
                style: TextStyle(fontSize: 16, color: Colors.green.shade600),
              ),

              const SizedBox(height: 40),

              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email, color: Colors.green),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorText: emailError,
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock, color: Colors.green),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorText: passwordError,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.green,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ForgotPassword(),
                    ),
                  );
                },
                child: Text(
                  "Forgot your password?",
                  style: TextStyle(color: Colors.green.shade600),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : loginUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Login", style: TextStyle(fontSize: 16)),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Not registered? "),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignupScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
