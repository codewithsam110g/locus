import 'package:flutter/material.dart';

class Inputfields extends StatefulWidget {
  final String title;
  final Widget emoji;
  final TextEditingController controller;
  final String? Function(String?)? onTap;
  final bool keyBoard1;
  final bool obscureText;
  final bool isPasswordField;
  final VoidCallback? suffixIconTap; // ✅ Added suffix icon tap callback
  final IconData? suffixIcon; // ✅ Custom suffix icon

  const Inputfields({
    super.key,
    required this.title,
    required this.emoji,
    required this.controller,
    required this.onTap,
    required this.keyBoard1,
    required this.obscureText,
    this.isPasswordField = false,
    this.suffixIconTap,
    this.suffixIcon, // ✅ Optional icon
  });

  @override
  State<Inputfields> createState() => _InputfieldsState();
}

class _InputfieldsState extends State<Inputfields> {
  bool _isFocused = false;
  bool _isObscure = true;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        setState(() {
          _isFocused = hasFocus;
        });
      },
      child: TextFormField(
        controller: widget.controller,
        validator: widget.onTap,
        style: const TextStyle(color: Colors.black),
        obscureText: widget.isPasswordField ? _isObscure : widget.obscureText,
        decoration: InputDecoration(
          hintText: widget.title,
          hintStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black.withOpacity(_isFocused ? 1 : 0.5),
          ),
          prefixIcon: widget.emoji,
          prefixIconColor: Colors.black.withOpacity(_isFocused ? 1 : 0.5),
          suffixIcon: widget.isPasswordField
              ? IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.black.withOpacity(_isFocused ? 1 : 0.7),
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscure = !_isObscure; // Toggle visibility
                    });
                  },
                )
              : (widget.suffixIcon != null
                  ? IconButton(
                      icon: Icon(widget.suffixIcon,
                          color:
                              Colors.black.withOpacity(_isFocused ? 1 : 0.5)),
                      onPressed: widget.suffixIconTap,
                    )
                  : null),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.black.withOpacity(_isFocused ? 1 : 0.5),
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.black.withOpacity(_isFocused ? 1 : 0.5),
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
        ),
        keyboardType:
            widget.keyBoard1 ? TextInputType.number : TextInputType.text,
      ),
    );
  }
}
