import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:student_app/staff_app/controllers/auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController userCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  bool obscure = true;

  late final AuthController auth;
  @override
  void initState() {
    super.initState();

    // ✅ Safely get AuthController (registered in main.dart)
    auth = Get.find<AuthController>();

    // ✅ Clear previous user input
    userCtrl.clear();
    passCtrl.clear();
  }

  @override
  void dispose() {
    userCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ---------------- BACKGROUND ----------------
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0A4CF5),
                  Color(0xFF8A2BE2),
                  Color(0xFFE247D6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // ---------------- WAVE ----------------
          Positioned(
            bottom: -80,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: _WaveClipper(),
              child: Container(
                height: 330,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.withOpacity(0.7),
                      Colors.pinkAccent.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ---------------- CONTENT ----------------
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        "assets/icon/SSG.jpeg",
                        height: 140,
                        width: 140,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      "e-SSG",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          // ---------- USERNAME ----------
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.80),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: TextField(
                              controller: userCtrl,
                              cursorColor: Colors.black,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(
                                  Icons.person,
                                  color: Colors.black,
                                ),
                                border: InputBorder.none,
                                labelText: " Enter Your User ID",
                                labelStyle: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13,
                                ),
                                hintText: "Enter ID",
                                hintStyle: const TextStyle(
                                  color: Colors.black45,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ---------- PASSWORD ----------
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.80),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: TextField(
                              controller: passCtrl,
                              obscureText: obscure,
                              cursorColor: Colors.black,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.lock,
                                  color: Colors.black,
                                ),
                                border: InputBorder.none,
                                labelText: "Password",
                                labelStyle: const TextStyle(
                                  color: Colors.black54,
                                ),
                                floatingLabelStyle: const TextStyle(
                                  color: Colors.black,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscure
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.black,
                                  ),
                                  onPressed: () =>
                                      setState(() => obscure = !obscure),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          // ---------- LOGIN BUTTON ----------
                          Obx(
                            () => SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                onPressed: auth.isLoading.value
                                    ? null
                                    : () async {
                                        FocusScope.of(context).unfocus();

                                        final username = userCtrl.text.trim();
                                        final password = passCtrl.text.trim();

                                        if (username.isEmpty ||
                                            password.isEmpty) {
                                          Get.snackbar(
                                            "Error",
                                            "Please enter username & password",
                                            backgroundColor: Colors.red,
                                            colorText: Colors.white,
                                          );
                                          return;
                                        }

                                        await auth.login(username, password);
                                      },
                                child: auth.isLoading.value
                                    ? const CircularProgressIndicator(
                                        color: Colors.black,
                                      )
                                    : const Text(
                                        "Login",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      "@ e-SSG",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- WAVE CLIPPER ----------------
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height * 0.5);

    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.80,
      size.width * 0.60,
      size.height * 0.60,
    );

    path.quadraticBezierTo(
      size.width * 0.85,
      size.height * 0.40,
      size.width,
      size.height * 0.70,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
