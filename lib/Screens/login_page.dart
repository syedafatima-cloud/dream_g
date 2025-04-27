import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_ap/screens/home_screen.dart';
import 'signup.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final List<List<Color>> _gradients = [
    [const Color.fromARGB(255, 255, 248, 181), const Color.fromARGB(255, 222, 142, 169)],
    [const Color.fromARGB(255, 255, 157, 190), const Color.fromARGB(255, 255, 215, 163)],
    [const Color.fromARGB(255, 171, 202, 255), const Color.fromARGB(255, 243, 177, 255)],
  ];

  int _currentGradient = 0;
  int _nextGradient = 1;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _currentGradient = _nextGradient;
            _nextGradient = (_nextGradient + 1) % _gradients.length;
          });
          _animationController.reset();
          _animationController.forward();
        }
      });
      
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildInputField(String label,
      {bool isPassword = false, 
      TextEditingController? controller, 
      String? Function(String?)? validator,
      TextInputType keyboardType = TextInputType.text,
      Widget? prefixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: const TextStyle(
            fontSize: 14, 
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          )
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: isPassword ? !_isPasswordVisible : false,
          validator: validator,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            prefixIcon: prefixIcon,
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.black54,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black38, width: 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black38, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();
      final messenger = ScaffoldMessenger.of(context);

      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email, 
          password: password
        );
        
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text("Login successful!"),
              backgroundColor: Colors.green,
            )
          );
          Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                                    );
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = "An error occurred. Please try again.";
        
        if (e.code == 'user-not-found' || e.code == 'wrong-password') {
          errorMessage = "Incorrect email or password";
        } else if (e.code == 'email-already-in-use') {
          errorMessage = "Email already in use";
        } else if (e.code == 'invalid-email') {
          errorMessage = "Invalid email address";
        } else if (e.code == 'too-many-requests') {
          errorMessage = "Too many attempts. Please try again later.";
        } else if (e.code == 'network-request-failed') {
          errorMessage = "Network error. Check your connection.";
        } else if (e.message != null) {
          errorMessage = e.message!;
        }
        
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            )
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text("Error: $e"),
              backgroundColor: Colors.red,
            )
          );
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
  Future<void> _resetPassword(String email) async {
  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password reset link sent to your email"),
          backgroundColor: Colors.green,
        )
      );
    }
  } on FirebaseAuthException catch (e) {
    String errorMessage = "Failed to send reset email";
    
    if (e.code == 'user-not-found') {
      errorMessage = "No user found with this email";
    } else if (e.code == 'invalid-email') {
      errorMessage = "Invalid email address";
    } else if (e.message != null) {
      errorMessage = e.message!;
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        )
      );
    }
  }
}
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 400 || size.height < 600;
    
    return Scaffold(
      body: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.lerp(_gradients[_currentGradient][0], _gradients[_nextGradient][0], _animation.value)!,
                  Color.lerp(_gradients[_currentGradient][1], _gradients[_nextGradient][1], _animation.value)!,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    SvgPicture.asset(
                      'assets/logo.svg',
                      height: isSmallScreen ? 60 : 80,
                      width: isSmallScreen ? 60 : 80,
                      placeholderBuilder: (context) => const SizedBox(
                        height: 80,
                        width: 80,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                    
                    SizedBox(height: isSmallScreen ? 20 : 30),
                    
                    // Login Card
                    Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      padding: EdgeInsets.all(isSmallScreen ? 14 : 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(90),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 8,
                            spreadRadius: 1,
                            color: const Color.fromRGBO(0, 0, 0, 0.3),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Login Title - smaller and not bold
                            const Text(
                              "Welcome Back",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.normal,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Sign in to continue",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Email Address
                            _buildInputField(
                              "Email Address",
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: const Icon(Icons.email_outlined, size: 20, color: Colors.black54),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Email is required";
                                }
                                if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                                  return "Enter a valid email";
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 14),
                            
                            // Password
                            _buildInputField(
                              "Password",
                              isPassword: true,
                              controller: _passwordController,
                              prefixIcon: const Icon(Icons.lock_outline, size: 20, color: Colors.black54),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Password is required";
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Forgot Password Link
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  // Show dialog to get email
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Reset Password"),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text("Enter your email to receive a password reset link"),
                                          const SizedBox(height: 16),
                                          TextFormField(
                                            initialValue: _emailController.text,
                                            keyboardType: TextInputType.emailAddress,
                                            decoration: const InputDecoration(
                                              labelText: "Email",
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: (value) {
                                              _emailController.text = value;
                                            },
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            if (_emailController.text.isNotEmpty) {
                                              _resetPassword(_emailController.text.trim());
                                              Navigator.pop(context);
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text("Please enter your email"),
                                                  backgroundColor: Colors.red,
                                                )
                                              );
                                            }
                                          },
                                          child: const Text("Send"),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(50, 24),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  "Forgot Password?",
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Login Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 3,
                                ),
                                onPressed: _isLoading ? null : _handleLogin,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Register Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Don't have an account? ",
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const Signup()),
                                    );
                                  },
                                  child: const Text(
                                    "Register",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
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
      ),
    );
  }
}