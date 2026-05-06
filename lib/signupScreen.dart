import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:metapi_todo_app/loginScreen.dart';

// Controllers declared inside the class (not globally — bad practice)
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  String? gender;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? nameError;
  String? phoneError;
  String? genderError;
  String? emailError;
  String? passwordError;
  String? confirmPasswordError;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  bool isValidEmail(String email) {
    return RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email);
  }

  bool isValidPhone(String phone) {
    return RegExp(r"^[0-9]{10,15}$").hasMatch(phone);
  }

  Future<void> registerUser() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    // ✅ Reset all errors
    setState(() {
      nameError = null;
      phoneError = null;
      genderError = null;
      emailError = null;
      passwordError = null;
      confirmPasswordError = null;
    });

    // ✅ Validate all fields
    bool hasError = false;

    if (name.isEmpty) {
      nameError = "Name is required";
      hasError = true;
    }

    if (phone.isEmpty) {
      phoneError = "Phone is required";
      hasError = true;
    } else if (!isValidPhone(phone)) {
      phoneError = "Enter valid phone number";
      hasError = true;
    }

    if (gender == null) {
      genderError = "Please select gender";
      hasError = true;
    }

    if (email.isEmpty) {
      emailError = "Email is required";
      hasError = true;
    } else if (!isValidEmail(email)) {
      emailError = "Enter valid email";
      hasError = true;
    }

    if (password.isEmpty) {
      passwordError = "Password is required";
      hasError = true;
    } else if (password.length < 6) {
      passwordError = "Minimum 6 characters required";
      hasError = true;
    }

    if (confirmPassword.isEmpty) {
      confirmPasswordError = "Confirm password is required";
      hasError = true;
    } else if (password != confirmPassword) {
      confirmPasswordError = "Passwords do not match";
      hasError = true;
    }

    setState(() {});

    // ⛔ Stop if any validation failed
    if (hasError) return;

    setState(() => _isLoading = true);

    try {
      // ✅ Step 1: Create user in Firebase Auth only
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;

      if (user != null) {
        // ✅ Step 2: Send verification email
        await user.sendEmailVerification();

        // ✅ Step 3: Sign out — Firestore data saved later at login
        await FirebaseAuth.instance.signOut();
      }

      if (!mounted) return;

      // ✅ Step 4: Navigate to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Verification email sent. Please verify before logging in.',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
            emailError = "Email already registered";
            break;
          case 'invalid-email':
            emailError = "Invalid email format";
            break;
          case 'weak-password':
            passwordError = "Password is too weak";
            break;
          default:
            emailError = e.message ?? "Signup failed";
            break;
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon,
    String? error, {
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.green),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      errorText: error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text("Sign Up"),
        backgroundColor: Colors.green,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              TextField(
                controller: nameController,
                decoration: _inputDecoration("Name", Icons.person, nameError),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration("Phone", Icons.phone, phoneError),
              ),

              const SizedBox(height: 15),

              Text(
                "Gender",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),

              Row(
                children: [
                  Radio(
                    value: "Male",
                    groupValue: gender,
                    onChanged: (value) =>
                        setState(() => gender = value.toString()),
                  ),
                  const Text("Male"),
                  Radio(
                    value: "Female",
                    groupValue: gender,
                    onChanged: (value) =>
                        setState(() => gender = value.toString()),
                  ),
                  const Text("Female"),
                  Radio(
                    value: "Other",
                    groupValue: gender,
                    onChanged: (value) =>
                        setState(() => gender = value.toString()),
                  ),
                  const Text("Other"),
                ],
              ),

              if (genderError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    genderError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),

              const SizedBox(height: 15),

              TextField(
                controller: emailController,
                decoration: _inputDecoration("Email", Icons.email, emailError),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: passwordController,
                obscureText: _obscurePassword,
                decoration: _inputDecoration(
                  "Password",
                  Icons.lock,
                  passwordError,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.green,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: _inputDecoration(
                  "Confirm Password",
                  Icons.lock_outline,
                  confirmPasswordError,
                  suffix: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.green,
                    ),
                    onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Register", style: TextStyle(fontSize: 16)),
                ),
              ),

              const SizedBox(height: 20),

              Center(
                child: TextButton(
                  onPressed: () {
                    if (Navigator.canPop(context)) Navigator.pop(context);
                  },
                  child: const Text(
                    "Back to Login",
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
