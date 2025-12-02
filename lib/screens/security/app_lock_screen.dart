import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../../constants/app_constants.dart';

/// App lock screen with biometric and PIN authentication
class AppLockScreen extends StatefulWidget {
  final Widget child;
  final bool isEnabled;
  final VoidCallback? onUnlocked;

  const AppLockScreen({
    super.key,
    required this.child,
    this.isEnabled = true,
    this.onUnlocked,
  });

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> with WidgetsBindingObserver {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isLocked = true;
  bool _canCheckBiometrics = false;
  bool _showPinFallback = false;
  String _enteredPin = '';
  String _storedPin = '1234'; // TODO: Load from secure storage
  bool _isPinSet = true; // TODO: Check if PIN is set
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.isEnabled) {
      _checkBiometrics();
    } else {
      _isLocked = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && widget.isEnabled) {
      // Lock the app when it goes to background
      setState(() {
        _isLocked = true;
        _showPinFallback = false;
        _enteredPin = '';
        _errorMessage = '';
      });
    } else if (state == AppLifecycleState.resumed && _isLocked && widget.isEnabled) {
      // Try biometric auth when app is resumed
      _authenticateWithBiometrics();
    }
  }

  Future<void> _checkBiometrics() async {
    try {
      _canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (_canCheckBiometrics && isDeviceSupported) {
        _authenticateWithBiometrics();
      } else {
        // Fallback to PIN if biometrics not available
        setState(() {
          _showPinFallback = true;
        });
      }
    } on PlatformException catch (e) {
      debugPrint('Biometric check error: $e');
      setState(() {
        _showPinFallback = true;
      });
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access Wealth Builder',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (authenticated) {
        _unlock();
      } else {
        setState(() {
          _showPinFallback = true;
        });
      }
    } on PlatformException catch (e) {
      debugPrint('Biometric auth error: $e');
      setState(() {
        _showPinFallback = true;
      });
    }
  }

  void _unlock() {
    setState(() {
      _isLocked = false;
      _enteredPin = '';
      _errorMessage = '';
    });
    widget.onUnlocked?.call();
  }

  void _onPinDigitPressed(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
        _errorMessage = '';
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onDeletePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = '';
      });
    }
  }

  void _verifyPin() {
    if (_enteredPin == _storedPin) {
      _unlock();
    } else {
      setState(() {
        _errorMessage = 'Incorrect PIN. Please try again.';
        _enteredPin = '';
      });
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocked || !widget.isEnabled) {
      return widget.child;
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, Color(0xFF004D00)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // App Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.secondary,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Wealth Builder',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _showPinFallback ? 'Enter your PIN' : 'Authenticate to continue',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
              const Spacer(),

              if (_showPinFallback) ...[
                // PIN dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index < _enteredPin.length
                            ? AppColors.secondary
                            : Colors.white.withOpacity(0.3),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),

                // Error message
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(
                        color: Colors.red.shade200,
                        fontSize: 14,
                      ),
                    ),
                  ),

                // PIN pad
                _buildPinPad(),
                const SizedBox(height: 24),

                // Biometric button (if available)
                if (_canCheckBiometrics)
                  TextButton.icon(
                    onPressed: _authenticateWithBiometrics,
                    icon: const Icon(Icons.fingerprint, color: Colors.white),
                    label: const Text(
                      'Use Biometrics',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ] else ...[
                // Biometric prompt
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fingerprint,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _authenticateWithBiometrics,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text('Authenticate'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showPinFallback = true;
                        });
                      },
                      child: const Text(
                        'Use PIN instead',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinPad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['1', '2', '3'].map((d) => _buildPinButton(d)).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['4', '5', '6'].map((d) => _buildPinButton(d)).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['7', '8', '9'].map((d) => _buildPinButton(d)).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 72), // Empty space
              _buildPinButton('0'),
              _buildDeleteButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPinButton(String digit) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _onPinDigitPressed(digit);
      },
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.1),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            digit,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _onDeletePressed();
      },
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: const Center(
          child: Icon(
            Icons.backspace_outlined,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}

/// PIN setup dialog for first-time users
class PinSetupDialog extends StatefulWidget {
  final Function(String) onPinSet;

  const PinSetupDialog({super.key, required this.onPinSet});

  @override
  State<PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<PinSetupDialog> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String _errorMessage = '';

  void _onDigitPressed(String digit) {
    if (_isConfirming) {
      if (_confirmPin.length < 4) {
        setState(() {
          _confirmPin += digit;
          _errorMessage = '';
        });
        if (_confirmPin.length == 4) {
          _verifyPins();
        }
      }
    } else {
      if (_pin.length < 4) {
        setState(() {
          _pin += digit;
          _errorMessage = '';
        });
        if (_pin.length == 4) {
          setState(() {
            _isConfirming = true;
          });
        }
      }
    }
  }

  void _onDeletePressed() {
    if (_isConfirming && _confirmPin.isNotEmpty) {
      setState(() {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      });
    } else if (!_isConfirming && _pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _verifyPins() {
    if (_pin == _confirmPin) {
      widget.onPinSet(_pin);
      Navigator.pop(context);
    } else {
      setState(() {
        _errorMessage = 'PINs do not match. Try again.';
        _confirmPin = '';
        _isConfirming = false;
        _pin = '';
      });
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isConfirming ? 'Confirm Your PIN' : 'Create a PIN',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: 8),
            Text(
              _isConfirming
                  ? 'Enter the same PIN again'
                  : 'This PIN will unlock your app',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 24),

            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final currentPin = _isConfirming ? _confirmPin : _pin;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < currentPin.length
                        ? AppColors.primary
                        : Colors.grey.shade300,
                  ),
                );
              }),
            ),

            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: TextStyle(color: AppColors.danger),
              ),
            ],
            const SizedBox(height: 24),

            // Simplified PIN pad for dialog
            _buildDialogPinPad(),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogPinPad() {
    return Column(
      children: [
        for (var row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', 'del']
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((d) {
                if (d.isEmpty) {
                  return const SizedBox(width: 64, height: 48);
                } else if (d == 'del') {
                  return InkWell(
                    onTap: _onDeletePressed,
                    child: Container(
                      width: 64,
                      height: 48,
                      alignment: Alignment.center,
                      child: const Icon(Icons.backspace_outlined),
                    ),
                  );
                } else {
                  return InkWell(
                    onTap: () => _onDigitPressed(d),
                    child: Container(
                      width: 64,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade100,
                      ),
                      child: Text(
                        d,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }
              }).toList(),
            ),
          ),
      ],
    );
  }
}
