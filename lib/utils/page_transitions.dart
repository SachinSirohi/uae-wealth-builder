import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Apple-style page transition with slide and fade
class ApplePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final bool fullscreenDialog;

  ApplePageRoute({
    required this.page,
    this.fullscreenDialog = false,
    RouteSettings? settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            if (fullscreenDialog) {
              // Modal presentation from bottom
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeOutCubic;
              
              var tween = Tween(begin: begin, end: end).chain(
                CurveTween(curve: curve),
              );
              
              var offsetAnimation = animation.drive(tween);
              
              return SlideTransition(
                position: offsetAnimation,
                child: child,
              );
            } else {
              // iOS-style horizontal slide
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeOutCubic;
              
              var tween = Tween(begin: begin, end: end).chain(
                CurveTween(curve: curve),
              );
              
              var offsetAnimation = animation.drive(tween);
              
              // Add subtle fade
              var fadeTween = Tween(begin: 0.8, end: 1.0);
              var fadeAnimation = animation.drive(fadeTween);
              
              return SlideTransition(
                position: offsetAnimation,
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: child,
                ),
              );
            }
          },
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          settings: settings,
        );
}

/// Fade transition for subtle screen changes
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadePageRoute({
    required this.page,
    RouteSettings? settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          settings: settings,
        );
}

/// Scale and fade transition for modal presentations
class ScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  ScalePageRoute({
    required this.page,
    RouteSettings? settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.easeOutCubic;
            
            var scaleTween = Tween(begin: 0.9, end: 1.0).chain(
              CurveTween(curve: curve),
            );
            
            var fadeTween = Tween(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: curve),
            );
            
            return ScaleTransition(
              scale: animation.drive(scaleTween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          settings: settings,
          opaque: false,
          barrierColor: Colors.black54,
        );
}

/// Extension to easily navigate with Apple-style transitions
extension AppleNavigator on BuildContext {
  /// Navigate with iOS-style horizontal slide
  Future<T?> pushApple<T>(Widget page) {
    return Navigator.of(this).push<T>(
      ApplePageRoute(page: page),
    );
  }

  /// Navigate with modal presentation from bottom
  Future<T?> pushModal<T>(Widget page) {
    return Navigator.of(this).push<T>(
      ApplePageRoute(
        page: page,
        fullscreenDialog: true,
      ),
    );
  }

  /// Navigate with fade transition
  Future<T?> pushFade<T>(Widget page) {
    return Navigator.of(this).push<T>(
      FadePageRoute(page: page),
    );
  }

  /// Navigate with scale transition
  Future<T?> pushScale<T>(Widget page) {
    return Navigator.of(this).push<T>(
      ScalePageRoute(page: page),
    );
  }
}

/// Cupertino-style back button
class AppleBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;

  const AppleBackButton({
    super.key,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.back,
            color: color ?? CupertinoTheme.of(context).primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            'Back',
            style: TextStyle(
              color: color ?? CupertinoTheme.of(context).primaryColor,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}
