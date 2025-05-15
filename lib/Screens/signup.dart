import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  _SignupState createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final List<List<Color>> _gradients = [
    [const Color.fromARGB(255, 255, 248, 181), const Color.fromARGB(255, 222, 142, 169)],
    [const Color.fromARGB(255, 255, 157, 190), const Color.fromARGB(255, 255, 215, 163)],
    [const Color.fromARGB(255, 171, 202, 255), const Color.fromARGB(255, 243, 177, 255)],
  ];

  int _index = 0;
  final _formKey = GlobalKey<FormState>(); // Form key for validation
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _animateBackground();
  }

  void _animateBackground() {
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _index = (_index + 1) % _gradients.length;
      });
      _animateBackground();
    });
  }

  // Input Field with Validation
  Widget _buildInputField(String label,
      {bool isPassword = false, TextEditingController? controller, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
        TextFormField(
          controller: controller,
          obscureText: isPassword ? !_isPasswordVisible : false,
          validator: validator, // Validation function
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(1000),
              borderSide: const BorderSide(color: Color.fromARGB(255, 114, 114, 114)), // Greyish border color
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(1000),
              borderSide: const BorderSide(color: Color.fromARGB(255, 114, 114, 114)), // Greyish border color
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(1000),
              borderSide: const BorderSide(color: Color.fromARGB(255, 114, 114, 114), width: 1.5), // Darker grey when focused
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Gradient Background
          AnimatedContainer(
            duration: const Duration(seconds: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _gradients[_index],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Scrollable UI Content
          SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.08),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo at the top
                  Align(
                    alignment: Alignment.topCenter,
                    child: SvgPicture.asset(
                      'assets/logo.svg',
                      height: 90,
                      width: 90,
                      placeholderBuilder: (context) => const CircularProgressIndicator(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Register Form
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 50),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 400, // Maximum width for the card
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          width: MediaQuery.of(context).size.width * 0.85, // Use percentage of screen width
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(90),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 10,
                                spreadRadius: 1,
                                color: const Color.fromRGBO(0, 0, 0, 0.3),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey, // Attach form key
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Register Title
                                const Text(
                                  "Register",
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 5),

                                // First Name
                                _buildInputField("First Name", validator: (value) {
                                  if (value == null || value.isEmpty) return "First Name is required";
                                  return null;
                                }),
                                const SizedBox(height: 10),

                                // Last Name
                                _buildInputField("Last Name", validator: (value) {
                                  if (value == null || value.isEmpty) return "Last Name is required";
                                  return null;
                                }),
                                const SizedBox(height: 10),

                                // Email Address
                                _buildInputField("Email Address", controller: _emailController, validator: (value) {
                                  if (value == null || value.isEmpty) return "Email is required";
                                  if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                                    return "Enter a valid email";
                                  }
                                  return null;
                                }),
                                const SizedBox(height: 10),

                                // Password
                                _buildInputField("Enter Password", isPassword: true, controller: _passwordController, validator: (value) {
                                  if (value == null || value.isEmpty) return "Password is required";
                                  if (value.length < 6) return "Password must be at least 6 characters";
                                  if (!RegExp(r'^(?=.*[A-Z])(?=.*\d).{6,}$').hasMatch(value)) {
                                    return "Password must contain an uppercase letter and a number";
                                  }
                                  return null;
                                }),
                                const SizedBox(height: 20),

                                // Register Button
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 175, 128, 179),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    minimumSize: const Size(double.infinity, 50),
                                    shadowColor: const Color.fromRGBO(0, 0, 0, 0.3),
                                    elevation: 6,
                                  ),
                                  onPressed: () async {
                                    if (_formKey.currentState!.validate()) {
                                      // Validation Passed - Proceed with registration
                                      String email = _emailController.text.trim();
                                      String password = _passwordController.text.trim();

                                      final messenger = ScaffoldMessenger.of(context);

                                      try {
                                        await FirebaseAuth.instance.createUserWithEmailAndPassword(
                                          email: email,
                                          password: password,
                                        );

                                        messenger.showSnackBar(
                                          const SnackBar(content: Text("User registered successfully!")),
                                        );
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(builder: (context) => const HomeScreen()),
                                        );
                                      } on FirebaseAuthException catch (e) {
                                        String message = "An error occurred";

                                        if (e.code == 'email-already-in-use') {
                                          message = "This email is already registered.";
                                        } else if (e.code == 'weak-password') {
                                          message = "Password should be at least 6 characters.";
                                        } else if (e.code == 'invalid-email') {
                                          message = "Please enter a valid email.";
                                        }

                                        messenger.showSnackBar(SnackBar(content: Text(message)));
                                      }
                                    }
                                  },
                                  child: const Text(
                                    'Register',
                                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}