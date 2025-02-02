import 'package:flutter/material.dart';

class Inputfields extends StatefulWidget {
  final String title;
  final Widget emoji;
  final TextEditingController controller;
  final String? Function(String?)? onTap;
  final bool keyBoard1;
  final bool obscureText;
  final IconData? suffixIcon;
  final VoidCallback? suffixIconTap;

  const Inputfields({
    super.key,
    required this.title,
    required this.emoji,
    required this.controller,
    required this.onTap,
    required this.keyBoard1,
    required this.obscureText,
    this.suffixIcon,
    this.suffixIconTap,
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
        style: const TextStyle(
          color: Colors.black,
        ),
        obscureText: widget.obscureText && _isObscure,
        decoration: InputDecoration(
          hintText: widget.title,
          hintStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black.withOpacity(_isFocused ? 1 : 0.25),
          ),
          prefixIcon: widget.emoji,
          prefixIconColor: Colors.black.withOpacity(_isFocused ? 1 : 0.25),
          suffixIcon: widget.suffixIcon != null
              ? IconButton(
                  icon: Icon(
                    widget.suffixIcon,
                    color: Colors.black.withOpacity(_isFocused ? 1 : 0.5),
                  ),
                  onPressed: widget.suffixIconTap,
                )
              : null,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.black.withOpacity(_isFocused ? 1 : 0.25),
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.black.withOpacity(_isFocused ? 1 : 0.25),
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
        ),
        keyboardType: widget.keyBoard1 ? TextInputType.number : TextInputType.text,
      ),
    );
  }
}
