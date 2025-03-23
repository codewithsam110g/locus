import 'package:flutter/material.dart';

class Innerbutton extends StatelessWidget {
  final String text;
  final VoidCallback function;
  final double hPadding;
  final double vPadding;

  const Innerbutton({
    super.key,
    required this.function,
    required this.text,
    this.hPadding = 3,
    this.vPadding = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        function();
      },
      style: ButtonStyle(
        elevation: MaterialStateProperty.all(0),
        backgroundColor: MaterialStateProperty.all(
          Theme.of(context).colorScheme.primary,
        ),
        side: MaterialStateProperty.all(
          BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
