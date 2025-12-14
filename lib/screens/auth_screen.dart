import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Required for FirebaseAuthException
import 'package:paperpulse/screens/dashboard_screen.dart'; // Import DashboardScreen

import '../model/auth_model.dart';
import '../services/auth_services.dart'; // Import AuthService

// Define the custom colors used in the Tailwind config for consistency
const Color primaryBlue = Color(0xFF4c51bf); // #4c51bf
const Color secondaryPurple = Color(0xFF805ad5); // #805ad5

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Service instance
  final AuthService _auth =  AuthService();

  // State management
  bool _isLogin = true;
  bool _isLoading = false; // Loading state for buttons

  // New state for password visibility toggle
  bool _isPasswordVisible = false;

  // Form keys for validation
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  // Controllers for direct access to password fields (critical for Confirm Password validation)
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Placeholder for form field values (only for non-controller fields)
  String _email = '';
  String _name = '';

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Function to switch between Login and Sign Up
  void _toggleView() {
    // Clear passwords when switching views
    _passwordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      _isLogin = !_isLogin;
      _isPasswordVisible = false; // Reset visibility
    });
  }

  // Function to toggle password visibility
  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  // Helper to show error messages
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // --- UI Widget Builders ---

  Widget _buildTextField({
    required String label,
    required IconData icon,
    bool isPassword = false, // Defaulted to false
    required void Function(String?) onSaved,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.emailAddress,
    TextEditingController? controller,
    // Parameters for visibility control
    bool passwordVisible = false,
    VoidCallback? toggleVisibility,
  }) {
    // Only apply suffix icon logic if it's a password field
    final suffixIcon = isPassword
        ? IconButton(
      icon: Icon(
        passwordVisible ? Icons.visibility : Icons.visibility_off,
        color: primaryBlue.withOpacity(0.7),
      ),
      onPressed: toggleVisibility,
    )
        : null;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      // Obscure text if it's a password field AND not currently visible
      obscureText: isPassword && !passwordVisible,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryBlue.withOpacity(0.7)),
        suffixIcon: suffixIcon, // Add the show/hide icon
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      ),
      validator: validator,
      onSaved: onSaved,
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Welcome Back',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            label: 'Email Address',
            icon: Icons.email,
            onSaved: (value) => _email = value!.trim(),
            validator: (value) {
              if (value == null || !value.contains('@')) {
                return 'Please enter a valid email address.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Password field with visibility toggle
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            icon: Icons.lock,
            isPassword: true,
            // FIX: Removed assignment to non-existent _password variable
            onSaved: (value) {},
            validator: (value) {
              if (value == null || value.length < 6) {
                return 'Password must be at least 6 characters.';
              }
              return null;
            },
            passwordVisible: _isPasswordVisible,
            toggleVisibility: _togglePasswordVisibility,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitLogin, // Disable button when loading
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              elevation: 4,
            ),
            child: _isLoading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
                : const Text(
              'LOG IN',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: _isLoading ? null : _toggleView, // Disable button when loading
            child: const Text.rich(
              TextSpan(
                text: "Don't have an account? ",
                style: TextStyle(color: Colors.grey),
                children: [
                  TextSpan(
                    text: 'Create Account',
                    style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupForm() {
    return Form(
      key: _signupFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Create Account',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            label: 'Full Name',
            icon: Icons.person,
            isPassword: false,
            keyboardType: TextInputType.text,
            onSaved: (value) => _name = value!.trim(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Email Address',
            icon: Icons.email,
            isPassword: false,
            onSaved: (value) => _email = value!.trim(),
            validator: (value) {
              if (value == null || !value.contains('@')) {
                return 'Please enter a valid email address.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Primary Password field
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            icon: Icons.lock,
            isPassword: true,
            onSaved: (value) {}, // Value retrieved from controller
            validator: (value) {
              if (value == null || value.length < 6) {
                return 'Password must be at least 6 characters.';
              }
              return null;
            },
            passwordVisible: _isPasswordVisible,
            toggleVisibility: _togglePasswordVisibility,
          ),
          const SizedBox(height: 16),
          // Confirm Password field with match validation
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            icon: Icons.lock,
            isPassword: true,
            onSaved: (value) {}, // Value retrieved from controller
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password.';
              }
              // Check if the confirmation matches the primary password
              if (value != _passwordController.text) {
                return 'Passwords do not match.';
              }
              return null;
            },
            passwordVisible: _isPasswordVisible,
            toggleVisibility: _togglePasswordVisibility,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitSignup, // Disable button when loading
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryPurple,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              elevation: 4,
            ),
            child: _isLoading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
                : const Text(
              'SIGN UP',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: _isLoading ? null : _toggleView, // Disable button when loading
            child: const Text.rich(
              TextSpan(
                text: "Already have an account? ",
                style: TextStyle(color: Colors.grey),
                children: [
                  TextSpan(
                    text: 'Back to Log In',
                    style: TextStyle(fontWeight: FontWeight.bold, color: secondaryPurple),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Submission Handlers (Real Firebase Auth) ---

  void _submitLogin() async {
    if (_loginFormKey.currentState!.validate()) {
      _loginFormKey.currentState!.save();
      setState(() => _isLoading = true);

      final String password = _passwordController.text; // Get password from controller

      try {
        final AppUser? user = await _auth.signInWithEmailAndPassword(_email, password);

        // **SUCCESSFUL LOGIN: Navigate to Dashboard**
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) =>  DashboardScreen(initialUser: user)),
              (Route<dynamic> route) => false, // Remove all previous routes
        );
      } on FirebaseAuthException catch (e) {
        setState(() => _isLoading = false);
        String errorMessage = 'Login Failed: Please check your credentials.';
        if (e.code == 'user-not-found') {
          errorMessage = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Incorrect password.';
        }
        _showError(errorMessage);
      } catch (e) {
        setState(() => _isLoading = false);
        _showError('An unexpected error occurred during login.');
      }
    }
  }

  void _submitSignup() async {
    if (_signupFormKey.currentState!.validate()) {
      _signupFormKey.currentState!.save();
      setState(() => _isLoading = true);

      final String password = _passwordController.text; // Get password from controller

      try {
        final AppUser? user = await _auth.signUpWithEmailAndPassword(_email, password, _name);

        // **SUCCESSFUL SIGNUP: Navigate to Dashboard**
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) =>  DashboardScreen(initialUser: user)),
              (Route<dynamic> route) => false, // Remove all previous routes
        );
      } on FirebaseAuthException catch (e) {
        setState(() => _isLoading = false);
        String errorMessage = 'Signup Failed: Please try again.';
        if (e.code == 'weak-password') {
          errorMessage = 'The password provided is too weak.';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'An account already exists for that email.';
        }
        _showError(errorMessage);
      } catch (e) {
        setState(() => _isLoading = false);
        _showError('An unexpected error occurred during signup.');
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // The Container provides the full-screen gradient background
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, secondaryPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        // Transparent background so the gradient shows through
        backgroundColor: Colors.transparent,
        body: Center(
          // SingleChildScrollView prevents overflow on smaller screens (mobile)
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                // AnimatedSwitcher handles the transition between Login and Sign Up views
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  // Use a key to force the AnimatedSwitcher to recognize a change
                  key: ValueKey<bool>(_isLogin),
                  child: _isLogin
                      ? _buildLoginForm()
                      : _buildSignupForm(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}