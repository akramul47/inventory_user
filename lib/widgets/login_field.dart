import 'package:flutter/material.dart';
import 'package:inventory_user/utils/pallete.dart';

class LoginField extends StatefulWidget {
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback? onFieldSubmitted;

  const LoginField({
    Key? key,
    required this.hintText,
    required this.controller,
    this.obscureText = false,
    this.onFieldSubmitted,
  }) : super(key: key);

  @override
  State<LoginField> createState() => _LoginFieldState();
}

class _LoginFieldState extends State<LoginField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  @override
  void didUpdateWidget(LoginField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _isObscured = widget.obscureText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 55,
        maxWidth: 400,
      ),
      child: TextFormField(
        controller: widget.controller,
        obscureText: _isObscured,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => widget.onFieldSubmitted?.call(),
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(18),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Pallete.gradient2,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
          ),
          filled: true,
          fillColor:
              isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
          suffixIcon: widget.obscureText
              ? IconButton(
                  icon: Icon(
                    _isObscured ? Icons.visibility_off : Icons.visibility,
                    color: Pallete.gradient2,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscured = !_isObscured;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }
}
