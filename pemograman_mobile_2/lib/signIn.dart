import 'package:flutter/material.dart';
import 'package:pemograman_mobile_2/home.dart';
import 'package:pemograman_mobile_2/app_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pemograman_mobile_2/config.dart';

/// ─── Interactive Login Mascot ───
/// Custom animated mascot in pure Flutter (Vector-based containers and bounds).
/// Looks directly at the mouse cursor (anak panah) as it moves on the screen,
/// falls back to looking at the username input, and covers its eyes when typing password.
/// When login is successful, it grabs the top of the card and runs off-screen carrying it!
class LoginMascot extends StatefulWidget {
  final TextEditingController usernameController;
  final FocusNode usernameFocusNode;
  final FocusNode passwordFocusNode;
  final Offset mousePosition;
  final bool isMouseHovering;
  final bool isSuccess;

  const LoginMascot({
    super.key,
    required this.usernameController,
    required this.usernameFocusNode,
    required this.passwordFocusNode,
    required this.mousePosition,
    required this.isMouseHovering,
    required this.isSuccess,
  });

  @override
  State<LoginMascot> createState() => _LoginMascotState();
}

class _LoginMascotState extends State<LoginMascot> {
  bool _isCoveringEyes = false;
  double _usernameLength = 0;

  @override
  void initState() {
    super.initState();
    widget.usernameFocusNode.addListener(_onFocusChange);
    widget.passwordFocusNode.addListener(_onFocusChange);
    widget.usernameController.addListener(_onUsernameChange);
    _isCoveringEyes = widget.passwordFocusNode.hasFocus;
    _usernameLength = widget.usernameController.text.length.toDouble();
  }

  @override
  void dispose() {
    widget.usernameFocusNode.removeListener(_onFocusChange);
    widget.passwordFocusNode.removeListener(_onFocusChange);
    widget.usernameController.removeListener(_onUsernameChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _isCoveringEyes = widget.passwordFocusNode.hasFocus;
      });
    }
  }

  void _onUsernameChange() {
    if (mounted) {
      setState(() {
        _usernameLength = widget.usernameController.text.length.toDouble();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double xLook = 0.0;
    double yLook = 0.0;

    final bool isEyesClosed = _isCoveringEyes || widget.isSuccess;

    if (!isEyesClosed) {
      if (widget.isMouseHovering && widget.mousePosition != Offset.zero) {
        // Calculate relative look direction to the mouse cursor (anak panah)
        try {
          final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null && renderBox.hasSize) {
            final Offset mascotPos = renderBox.localToGlobal(Offset.zero);
            final Size size = renderBox.size;
            final Offset mascotCenter = mascotPos + Offset(size.width / 2, size.height / 2);
            final Offset diff = widget.mousePosition - mascotCenter;
            
            final double dist = diff.distance;
            final double maxDist = 350.0; // limit tracking radius
            final double normalizedDist = (dist / maxDist).clamp(0.0, 0.5);
            
            if (dist > 0) {
              xLook = (diff.dx / dist) * normalizedDist * 1.4;
              yLook = (diff.dy / dist) * normalizedDist * 1.4;
            }
          }
        } catch (_) {
          // Fallback to username input text length
          xLook = -0.5 + (_usernameLength * 0.05);
        }
      } else {
        // Default text-length tracking
        xLook = -0.5 + (_usernameLength * 0.05);
        yLook = 0.1;
      }
    }

    // Clamp eyes looking bounds to keep pupils inside eyes
    xLook = xLook.clamp(-0.6, 0.6);
    yLook = yLook.clamp(-0.6, 0.6);

    // Dynamic hand positioning (Left Hand)
    double handLeft = 24;
    double handLeftBottom = _isCoveringEyes ? 56 : 10;
    if (widget.isSuccess) {
      handLeft = 6;            // Grab outer edge
      handLeftBottom = -14;    // Hold onto the top card border
    }

    // Dynamic hand positioning (Right Hand)
    double handRight = 24;
    double handRightBottom = _isCoveringEyes ? 56 : 10;
    if (widget.isSuccess) {
      handRight = 6;
      handRightBottom = -14;
    }

    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Bear Ears
          // Left Ear
          Positioned(
            left: 18,
            top: 12,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFC2A878),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2C2F33), width: 3),
              ),
            ),
          ),
          // Right Ear
          Positioned(
            right: 18,
            top: 12,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFC2A878),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2C2F33), width: 3),
              ),
            ),
          ),

          // 2. Bear Head (Face Base)
          Container(
            width: 106,
            height: 106,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3A3D42), Color(0xFF232528)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFC2A878), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),

          // 3. Eyes
          // Left Eye
          Positioned(
            left: 38,
            top: 50,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 18,
              height: isEyesClosed ? 3 : 18,
              decoration: BoxDecoration(
                color: isEyesClosed ? const Color(0xFFC2A878) : Colors.white,
                borderRadius: BorderRadius.circular(isEyesClosed ? 1.5 : 9),
              ),
              child: isEyesClosed
                  ? const SizedBox.shrink()
                  : Align(
                      alignment: Alignment(xLook, yLook),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E1E1E),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
            ),
          ),
          // Right Eye
          Positioned(
            right: 38,
            top: 50,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 18,
              height: isEyesClosed ? 3 : 18,
              decoration: BoxDecoration(
                color: isEyesClosed ? const Color(0xFFC2A878) : Colors.white,
                borderRadius: BorderRadius.circular(isEyesClosed ? 1.5 : 9),
              ),
              child: isEyesClosed
                  ? const SizedBox.shrink()
                  : Align(
                      alignment: Alignment(xLook, yLook),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E1E1E),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
            ),
          ),

          // 4. Muzzle & Nose
          Positioned(
            bottom: 26,
            child: Container(
              width: 28,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFFC2A878).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Container(
                  width: 10,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC2A878),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),

          // 5. Hands (Paws animating up or down depending on success/focus)
          // Left Hand
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            left: handLeft,
            bottom: handLeftBottom,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFC2A878),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF1E1E1E), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          // Right Hand
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            right: handRight,
            bottom: handRightBottom,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFC2A878),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF1E1E1E), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Logo extends StatelessWidget {
  final TextEditingController usernameController;
  final FocusNode usernameFocusNode;
  final FocusNode passwordFocusNode;
  final Offset mousePosition;
  final bool isMouseHovering;
  final bool isSuccess;

  const Logo({
    super.key,
    required this.usernameController,
    required this.usernameFocusNode,
    required this.passwordFocusNode,
    required this.mousePosition,
    required this.isMouseHovering,
    required this.isSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LoginMascot(
          usernameController: usernameController,
          usernameFocusNode: usernameFocusNode,
          passwordFocusNode: passwordFocusNode,
          mousePosition: mousePosition,
          isMouseHovering: isMouseHovering,
          isSuccess: isSuccess,
        ),
        const SizedBox(height: 20),
        Text(
          "LONIKA_STORE",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isSmallScreen ? 28 : 36,
            fontWeight: FontWeight.w900,
            letterSpacing: 4.0,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "INVENTORY & SALES SYSTEM",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class signIn extends StatefulWidget {
  const signIn({super.key});

  @override
  State<signIn> createState() => _signInState();
}

class _signInState extends State<signIn> {
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Offset _mousePosition = Offset.zero;
  bool _isMouseHovering = false;

  // Animation values for transition after login success
  bool _isSuccessTransition = false;
  double _cardTranslateX = 0.0;
  double _cardTranslateY = 0.0;
  double _cardRotation = 0.0;

  @override
  void dispose() {
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Triggered when login succeeds
  void _playSuccessTransition() {
    setState(() {
      _isSuccessTransition = true;
      _cardTranslateY = -35.0; // Lift up slightly
      _cardRotation = -0.06;   // Tilt slightly to indicate pulling/lifting
    });

    // Wait for the paws to grab, then run off-screen to the right!
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() {
          _cardTranslateX = MediaQuery.of(context).size.width + 300; // Slide completely off-screen
          _cardTranslateY = -90.0;  // Lift higher
          _cardRotation = -0.16;    // Tilt more while running/dragging
        });
      }
    });

    // Navigate to Home screen after the off-screen animation finishes
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: MouseRegion(
        onHover: (event) {
          if (!_isSuccessTransition) {
            setState(() {
              _mousePosition = event.position;
              _isMouseHovering = true;
            });
          }
        },
        onExit: (event) {
          setState(() {
            _isMouseHovering = false;
          });
        },
        child: Stack(
          children: [
            // Background ambient lights
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.gold.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -150,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.goldSubtle,
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 650),
                  curve: _isSuccessTransition ? Curves.easeInOutBack : Curves.linear,
                  transform: Matrix4.translationValues(_cardTranslateX, _cardTranslateY, 0.0)
                    ..rotateZ(_cardRotation),
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
                  constraints: BoxConstraints(maxWidth: isSmallScreen ? 400 : 850),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(24.0),
                    border: Border.all(color: AppTheme.surfaceBorder, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: isSmallScreen
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Logo(
                              usernameController: _usernameController,
                              usernameFocusNode: _usernameFocusNode,
                              passwordFocusNode: _passwordFocusNode,
                              mousePosition: _mousePosition,
                              isMouseHovering: _isMouseHovering,
                              isSuccess: _isSuccessTransition,
                            ),
                            const SizedBox(height: 32),
                            _Form(
                              usernameController: _usernameController,
                              passwordController: _passwordController,
                              usernameFocusNode: _usernameFocusNode,
                              passwordFocusNode: _passwordFocusNode,
                              onLoginSuccess: _playSuccessTransition,
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: Logo(
                                usernameController: _usernameController,
                                usernameFocusNode: _usernameFocusNode,
                                passwordFocusNode: _passwordFocusNode,
                                mousePosition: _mousePosition,
                                isMouseHovering: _isMouseHovering,
                                isSuccess: _isSuccessTransition,
                              ),
                            ),
                            const SizedBox(
                              height: 280,
                              child: VerticalDivider(
                                color: AppTheme.surfaceBorder,
                                thickness: 1.5,
                                width: 64,
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: _Form(
                                  usernameController: _usernameController,
                                  passwordController: _passwordController,
                                  usernameFocusNode: _usernameFocusNode,
                                  passwordFocusNode: _passwordFocusNode,
                                  onLoginSuccess: _playSuccessTransition,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Form extends StatefulWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final FocusNode usernameFocusNode;
  final FocusNode passwordFocusNode;
  final VoidCallback onLoginSuccess;

  const _Form({
    required this.usernameController,
    required this.passwordController,
    required this.usernameFocusNode,
    required this.passwordFocusNode,
    required this.onLoginSuccess,
  });

  @override
  State<_Form> createState() => __FormState();
}

class __FormState extends State<_Form> {
  bool _isPasswordVisible = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController get usernameController => widget.usernameController;
  TextEditingController get passwordController => widget.passwordController;

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final username = usernameController.text;
    final password = passwordController.text;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );
      Navigator.of(context).pop(); // close loading
      if (response.statusCode == 200) {
        widget.onLoginSuccess(); // Trigger mascot carrying the box transition!
      } else {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Login gagal')));
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal koneksi ke server')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              focusNode: widget.usernameFocusNode,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Masukkan Username Anda';
                }
                return null;
              },
              controller: usernameController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: AppTheme.formInputDecoration(
                label: 'Username',
              ).copyWith(
                hintText: 'Masukkan Username Anda',
                prefixIcon: const Icon(Icons.person_outline_rounded, color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.backgroundAlt,
              ),
            ),
            _gap(),
            TextFormField(
              focusNode: widget.passwordFocusNode,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Masukkan Password Anda';
                }
                if (value.length < 6) {
                  return 'Password Harus Lebih Dari 6 Karakter';
                }
                return null;
              },
              obscureText: !_isPasswordVisible,
              controller: passwordController,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: AppTheme.formInputDecoration(
                label: 'Password',
              ).copyWith(
                hintText: 'Masukkan Password Anda',
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.backgroundAlt,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            _gap(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: AppTheme.primaryButton.copyWith(
                  padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 14.0)),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: _login,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _gap() => const SizedBox(height: 16);
