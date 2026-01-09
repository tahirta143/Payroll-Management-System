import 'package:flutter/material.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final bool obscureText;
  final String? Function(String?)? validator;
  final bool isEnabled;
  final bool isReadOnly;
  final Function(String)? onChanged;
  final Function()? onTap;
  final Color? fillColor;
  final Color? borderColor;
  final double borderRadius;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? contentPadding;
  final int? maxLines;
  final int? maxLength;
  final String? errorText;
  final bool showErrorBorder;
  final bool autoFocus;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final Function(String)? onSubmitted;
  final TextCapitalization textCapitalization;
  final bool showCounter;
  final Color? focusedBorderColor;
  final double focusedBorderWidth;
  final bool showLabelAsTitle;
  final bool isRequired;
  final Widget? customSuffix;
  final String? helperText;

  const AppTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.hintText,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.obscureText = false,
    this.validator,
    this.isEnabled = true,
    this.isReadOnly = false,
    this.onChanged,
    this.onTap,
    this.fillColor,
    this.borderColor,
    this.borderRadius = 12.0,
    this.textStyle,
    this.contentPadding,
    this.maxLines = 1,
    this.maxLength,
    this.errorText,
    this.showErrorBorder = true,
    this.autoFocus = false,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
    this.showCounter = false,
    this.focusedBorderColor,
    this.focusedBorderWidth = 2.0,
    this.showLabelAsTitle = false,
    this.isRequired = false,
    this.customSuffix,
    this.helperText,
  }) : super(key: key);

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _isObscured = false;
  bool _isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _toggleObscureText() {
    setState(() {
      _isObscured = !_isObscured;
    });
  }

  Widget? _buildSuffixIcon() {
    if (widget.customSuffix != null) return widget.customSuffix;

    if (widget.obscureText) {
      return IconButton(
        onPressed: _toggleObscureText,
        icon: Icon(
          _isObscured ? Icons.visibility : Icons.visibility_off,
          color: Colors.grey[600],
          size: 22,
        ),
        splashRadius: 20,
        padding: const EdgeInsets.all(2),
      );
    }

    if (widget.suffixIcon != null) {
      return IconButton(
        onPressed: widget.onSuffixIconPressed,
        icon: Icon(
          widget.suffixIcon,
          color: _isFocused ? const Color(0xFF5B86E5) : Colors.grey[600],
          size: 22,
        ),
        splashRadius: 20,
        padding: const EdgeInsets.all(2),
      );
    }

    return null;
  }

  Color _getBorderColor() {
    if (widget.errorText != null && widget.errorText!.isNotEmpty) {
      return Colors.red;
    }
    if (_isFocused) {
      return widget.focusedBorderColor ?? const Color(0xFF5B86E5);
    }
    return widget.borderColor ?? Colors.grey[300]!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabelAsTitle)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Text(
                  widget.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.grey[700],
                  ),
                ),
                if (widget.isRequired)
                  Padding(
                    padding: const EdgeInsets.only(left: 2.0),
                    child: Text(
                      '*',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
          ),

        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          keyboardType: widget.keyboardType,
          obscureText: _isObscured,
          enabled: widget.isEnabled,
          readOnly: widget.isReadOnly,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          autofocus: widget.autoFocus,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          style: widget.textStyle ?? theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: widget.showLabelAsTitle ? widget.hintText : widget.label,
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            labelText: widget.showLabelAsTitle ? null : widget.label,
            labelStyle: TextStyle(
              color: _isFocused
                  ? const Color(0xFF5B86E5)
                  : Colors.grey[600],
            ),
            prefixIcon: widget.prefixIcon != null
                ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                widget.prefixIcon,
                color: _isFocused
                    ? const Color(0xFF5B86E5)
                    : Colors.grey[600],
                size: 22,
              ),
            )
                : null,
            suffixIcon: _buildSuffixIcon(),
            filled: true,
            fillColor: widget.fillColor ??
                (isDark
                    ? Colors.grey[900]!.withOpacity(0.6)
                    : Colors.grey[50]),
            contentPadding: widget.contentPadding ?? const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(
                color: widget.borderColor ?? Colors.grey[300]!,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(
                color: _getBorderColor(),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(
                color: widget.focusedBorderColor ?? const Color(0xFF5B86E5),
                width: widget.focusedBorderWidth,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: 1.0,
              ),
            ),
            errorBorder: widget.showErrorBorder
                ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(
                color: Colors.red,
                width: 1.5,
              ),
            )
                : null,
            focusedErrorBorder: widget.showErrorBorder
                ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(
                color: Colors.red,
                width: widget.focusedBorderWidth,
              ),
            )
                : null,
            errorText: widget.errorText,
            errorStyle: const TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            counterText: widget.showCounter ? null : '',
            helperText: widget.helperText,
            helperStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
          validator: widget.validator,
          onChanged: widget.onChanged,
          onTap: widget.onTap,
          onFieldSubmitted: widget.onSubmitted,
        ),

        if (widget.maxLength != null && widget.showCounter)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${widget.controller.text.length}/${widget.maxLength}',
                  style: TextStyle(
                    color: widget.controller.text.length > widget.maxLength!
                        ? Colors.red
                        : Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}