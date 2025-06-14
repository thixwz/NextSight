import 'dart:ui'; // Needed for ImageFilter
import 'package:flutter/material.dart';

class GlassmorphicSearchBar extends StatefulWidget {
  final Function(String) onSubmitted;
  final String hintText;
  final FocusNode? focusNode;
  final bool showBackButton;
  final VoidCallback? onBackButtonPressed;
  final TextEditingController? controller; // Added controller

  const GlassmorphicSearchBar({
    super.key,
    required this.onSubmitted,
    this.hintText = 'Ask ChatGPT',
    this.focusNode,
    this.showBackButton = false,
    this.onBackButtonPressed,
    this.controller, // Added controller
  });

  @override
  State<GlassmorphicSearchBar> createState() => _GlassmorphicSearchBarState();
}

class _GlassmorphicSearchBarState extends State<GlassmorphicSearchBar> with TickerProviderStateMixin {
  late TextEditingController _controller;
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;
  late AnimationController _iconAnimationController;
  late Animation<double> _iconRotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(); // Use provided controller or create a new one

    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 50)
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.80).animate(
      CurvedAnimation(parent: _buttonAnimationController, curve: Curves.easeOut)
    );

    _iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _iconRotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconAnimationController, curve: Curves.easeInOut)
    );

    if (widget.showBackButton) {
      _iconAnimationController.forward(from: 1.0); // Start with back arrow if true initially
    } else {
      _iconAnimationController.reverse(from: 0.0); // Start with upload arrow if false initially
    }
  }

  @override
  void didUpdateWidget(GlassmorphicSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showBackButton != oldWidget.showBackButton) {
      if (widget.showBackButton) {
        _iconAnimationController.forward();
      } else {
        _iconAnimationController.reverse();
      }
    }
    // If the external controller instance changes, update our internal reference
    if (widget.controller != null && widget.controller != _controller) {
      // Dispose the old internally managed controller if it wasn't the passed one
      if (oldWidget.controller == null) {
        _controller.dispose();
      }
      _controller = widget.controller!;
    } else if (widget.controller == null && oldWidget.controller != null) {
      // If a controller was previously provided but now it's null, create an internal one
      _controller = TextEditingController(text: oldWidget.controller!.text);
    }
  }

  @override
  void dispose() {
    // Only dispose the controller if it was created internally
    if (widget.controller == null) {
      _controller.dispose();
    }
    _buttonAnimationController.dispose();
    _iconAnimationController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_controller.text.isNotEmpty) {
      widget.onSubmitted(_controller.text);
      // _controller.clear(); // Optionally clear after submit
    }
  }

  void _handleButtonPress() {
    _buttonAnimationController.forward().then((_) {
      _buttonAnimationController.reverse();
      if (widget.showBackButton) {
        widget.onBackButtonPressed?.call();
      } else {
        _handleSubmit();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final Color textColor = theme.colorScheme.onSurface;
    final Color iconColor = isDarkMode ? Colors.white70 : Colors.black54;
    final Color buttonBackgroundColor = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;

    final List<Color> gradientColors = isDarkMode
        ? [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)]
        : [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.05)];

    return ClipRRect(
      borderRadius: BorderRadius.circular(30.0), // Rounded ends
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0), // Kept increased blur
        child: Container(
          height: 50.0, // Set a fixed height for the search bar
          padding: const EdgeInsets.only(left: 16.0, right: 6.0), // Padding for text and button
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30.0),
            border: Border.all(
              color: (isDarkMode ? Colors.white : Colors.black).withOpacity(0.1),
              width: 0.5,
            )
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: widget.focusNode, // Use the passed focusNode here
                  style: const TextStyle(color: Colors.white, fontSize: 16.0),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyle(color: textColor.withOpacity(0.6), fontSize: 16),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10.0), // Adjust for vertical centering
                  ),
                  onSubmitted: (_) => _handleSubmit(), // Submit on keyboard action
                  textInputAction: TextInputAction.send,
                ),
              ),
              ScaleTransition(
                scale: _buttonScaleAnimation,
                child: GestureDetector(
                  onTapDown: (_) => _buttonAnimationController.forward(),
                  onTapUp: (_) {
                    if (_buttonAnimationController.status == AnimationStatus.forward) {
                      _buttonAnimationController.reverse().then((value) {
                        if (widget.showBackButton) {
                          widget.onBackButtonPressed?.call();
                        } else {
                          _handleSubmit();
                        }
                      });
                    } else {
                       _buttonAnimationController.forward().then((_) {
                          _buttonAnimationController.reverse();
                          if (widget.showBackButton) {
                            widget.onBackButtonPressed?.call();
                          } else {
                            _handleSubmit();
                          }
                       });
                    }
                  },
                  onTapCancel: () {
                    if (_buttonAnimationController.status == AnimationStatus.forward) {
                      _buttonAnimationController.reverse();
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.all(4.0), // Margin around the button
                    padding: const EdgeInsets.all(8.0), // Padding inside the button
                    decoration: BoxDecoration(
                      color: buttonBackgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: AnimatedBuilder(
                      animation: _iconAnimationController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _iconRotationAnimation.value * -0.5 * 3.1415926535, // Rotate to left arrow
                          child: Icon(
                            Icons.arrow_upward_rounded, // Always use upward arrow
                            color: iconColor,
                            size: 22,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}