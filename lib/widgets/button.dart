import 'package:flutter/material.dart';

class Button1 extends StatelessWidget {
  final String title;
  final Color colors;
  final Color textColor;
  final VoidCallback onTap;

  const Button1({
    super.key,
    required this.title,
    required this.colors,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 7,
      shadowColor: Colors.black.withOpacity(0.4),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        decoration: BoxDecoration(
          color: colors,
          borderRadius: BorderRadius.circular(6),
          
        ),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            elevation: 0, // Set elevation to 0 to rely on custom shadow
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            backgroundColor: colors,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
                fontFamily: 'Electrolize',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
