import 'package:flutter/material.dart';

class AppButton extends StatefulWidget {
  final String title;
  final VoidCallback onPressed;
  final double? width;
  final double? height;
  final Color backgroundColor;
  final Color? foregroundColor;
  final Color? disabledColor;
  final Color? shadowColor;
  final Gradient? gradient;
  final bool isOutlined;
  final bool isElevated;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final bool isLoading;
  final double elevation;
  final double hoverElevation;
  final double focusElevation;
  final double disabledElevation;
  final TextStyle? textStyle;
  final bool expandWidth;
  final bool isFullWidth;
  final Duration animationDuration;
  final Curve animationCurve;
  final BorderSide? borderSide;
  final bool enableFeedback;
  final List<BoxShadow>? customShadow;
  final double? minWidth;
  final VisualDensity? visualDensity;
  final MaterialTapTargetSize? materialTapTargetSize;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? tooltip;
  final MouseCursor? mouseCursor;

  const AppButton({
    Key? key,
    required this.title,
    required this.onPressed,
    this.width,
    this.height,
    this.backgroundColor = const Color(0xFF5B86E5),
    this.foregroundColor = Colors.white,
    this.disabledColor,
    this.shadowColor,
    this.gradient,
    this.isOutlined = false,
    this.isElevated = true,
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.margin = EdgeInsets.zero,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.elevation = 2.0,
    this.hoverElevation = 4.0,
    this.focusElevation = 8.0,
    this.disabledElevation = 0.0,
    this.textStyle,
    this.expandWidth = false,
    this.isFullWidth = false,
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationCurve = Curves.easeInOut,
    this.borderSide,
    this.enableFeedback = true,
    this.customShadow,
    this.minWidth,
    this.visualDensity,
    this.materialTapTargetSize,
    this.focusNode,
    this.autofocus = false,
    this.tooltip,
    this.mouseCursor,
  }) : super(key: key);

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: widget.animationCurve,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  void _onTapCancel() {
    setState(() {
      _isPressed = false;
    });
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculate width based on parameters
    final double calculatedWidth = widget.isFullWidth
        ? MediaQuery.of(context).size.width
        : (widget.width ?? (widget.expandWidth ? double.infinity : null)) ?? 0;

    // Determine button colors
    final Color effectiveBackgroundColor = widget.isOutlined
        ? Colors.transparent
        : (widget.gradient != null
        ? Colors.transparent
        : widget.backgroundColor);

    final Color effectiveForegroundColor = widget.foregroundColor ??
        (widget.isOutlined ? widget.backgroundColor : Colors.white);

    final Color effectiveDisabledColor = widget.disabledColor ??
        (isDark ? Colors.grey[800]! : Colors.grey[300]!);

    // Build button content
    Widget buttonContent = widget.isLoading
        ? SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(
          widget.isOutlined ? widget.backgroundColor : Colors.white,
        ),
      ),
    )
        : Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.leadingIcon != null)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: widget.leadingIcon!,
          ),
        Flexible(
          child: Text(
            widget.title,
            style: widget.textStyle ??
                theme.textTheme.labelLarge?.copyWith(
                  color: effectiveForegroundColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        if (widget.trailingIcon != null)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: widget.trailingIcon!,
          ),
      ],
    );

    // Build button decoration
    BoxDecoration? decoration;
    if (!widget.isOutlined && widget.gradient == null) {
      decoration = BoxDecoration(
        color: _isPressed
            ? effectiveBackgroundColor.withOpacity(0.9)
            : effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        gradient: widget.gradient,
        boxShadow: widget.customShadow ??
            (widget.isElevated && !widget.isOutlined
                ? [
              BoxShadow(
                color: widget.shadowColor ??
                    effectiveBackgroundColor.withOpacity(0.3),
                blurRadius: _isHovered ? 12 : 8,
                offset: Offset(0, _isHovered ? 4 : 2),
                spreadRadius: _isHovered ? 0 : 0,
              ),
            ]
                : null),
        border: widget.isOutlined
            ? Border.all(
          color: widget.backgroundColor,
          width: widget.borderSide?.width ?? 2.0,
          style: widget.borderSide?.style ?? BorderStyle.solid,
        )
            : null,
      );
    }

    // Build button with animation
    Widget animatedButton = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: widget.mouseCursor ?? SystemMouseCursors.click,
        child: Container(
          constraints: BoxConstraints(
            minWidth: widget.minWidth ?? 64,
            minHeight: widget.height ?? 48,
          ),
          width: calculatedWidth > 0 ? calculatedWidth : null,
          height: widget.height,
          padding: widget.padding,
          margin: widget.margin,
          decoration: decoration,
          child: Center(child: buttonContent),
        ),
      ),
    );

    // Build with gradient if specified
    if (widget.gradient != null && !widget.isOutlined) {
      animatedButton = AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: widget.mouseCursor ?? SystemMouseCursors.click,
          child: Container(
            constraints: BoxConstraints(
              minWidth: widget.minWidth ?? 64,
              minHeight: widget.height ?? 48,
            ),
            width: calculatedWidth > 0 ? calculatedWidth : null,
            height: widget.height,
            padding: widget.padding,
            margin: widget.margin,
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: widget.customShadow ??
                  (widget.isElevated
                      ? [
                    BoxShadow(
                      color: widget.shadowColor ??
                          const Color(0xFF5B86E5).withOpacity(0.3),
                      blurRadius: _isHovered ? 12 : 8,
                      offset: Offset(0, _isHovered ? 4 : 2),
                    ),
                  ]
                      : null),
            ),
            child: Center(child: buttonContent),
          ),
        ),
      );
    }

    // Wrap with gesture detector and tooltip
    Widget button = GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.isLoading ? null : widget.onPressed,
      behavior: HitTestBehavior.opaque,
      child: animatedButton,
    );

    // Add tooltip if specified
    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return button;
  }
}

// Pre-defined gradient styles for quick use
class ButtonGradients {
  static Gradient blue = LinearGradient(
    colors: [Color(0xFF5B86E5), Color(0xFF36D1DC)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static Gradient purple = LinearGradient(
    colors: [Color(0xFF9C27B0), Color(0xFF673AB7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Gradient sunset = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFFA726)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Gradient green = LinearGradient(
    colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static Gradient dark = LinearGradient(
    colors: [Color(0xFF424242), Color(0xFF212121)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

// Pre-defined button styles for common use cases
class AppButtonStyles {
  static AppButton primary({
    required String title,
    required VoidCallback onPressed,
    double? width,
    bool isLoading = false,
    Widget? leadingIcon,
  }) {
    return AppButton(
      title: title,
      onPressed: onPressed,
      width: width,
      gradient: ButtonGradients.blue,
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      leadingIcon: leadingIcon,
      isLoading: isLoading,
      isFullWidth: width == null,
    );
  }

  static AppButton secondary({
    required String title,
    required VoidCallback onPressed,
    double? width,
    bool isLoading = false,
  }) {
    return AppButton(
      title: title,
      onPressed: onPressed,
      width: width,
      backgroundColor: Colors.transparent,
      isOutlined: true,
      borderSide: const BorderSide(color: Color(0xFF5B86E5), width: 2),
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      isLoading: isLoading,
      isFullWidth: width == null,
    );
  }

  static AppButton danger({
    required String title,
    required VoidCallback onPressed,
    double? width,
    bool isLoading = false,
  }) {
    return AppButton(
      title: title,
      onPressed: onPressed,
      width: width,
      backgroundColor: Colors.red,
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      isLoading: isLoading,
      isFullWidth: width == null,
    );
  }

  static AppButton success({
    required String title,
    required VoidCallback onPressed,
    double? width,
    bool isLoading = false,
  }) {
    return AppButton(
      title: title,
      onPressed: onPressed,
      width: width,
      gradient: ButtonGradients.green,
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      isLoading: isLoading,
      isFullWidth: width == null,
    );
  }

  static AppButton icon({
    required String title,
    required VoidCallback onPressed,
    required IconData icon,
    double? width,
    bool isLoading = false,
    bool isLeading = true,
  }) {
    return AppButton(
      title: title,
      onPressed: onPressed,
      width: width,
      gradient: ButtonGradients.blue,
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      leadingIcon: isLeading
          ? Icon(icon, size: 20, color: Colors.white)
          : null,
      trailingIcon: !isLeading
          ? Icon(icon, size: 20, color: Colors.white)
          : null,
      isLoading: isLoading,
      isFullWidth: width == null,
    );
  }

  static AppButton small({
    required String title,
    required VoidCallback onPressed,
    double? width,
    bool isLoading = false,
  }) {
    return AppButton(
      title: title,
      onPressed: onPressed,
      width: width,
      height: 36,
      backgroundColor: const Color(0xFF5B86E5),
      borderRadius: 8,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      textStyle: const TextStyle(fontSize: 12),
      isLoading: isLoading,
    );
  }

  static AppButton large({
    required String title,
    required VoidCallback onPressed,
    double? width,
    bool isLoading = false,
  }) {
    return AppButton(
      title: title,
      onPressed: onPressed,
      width: width,
      height: 56,
      gradient: ButtonGradients.blue,
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      isLoading: isLoading,
      isFullWidth: width == null,
    );
  }
}