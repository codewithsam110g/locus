import 'package:flutter/material.dart';

class Otheroptions extends StatelessWidget {
  final String text1;
  final String text2;
  final VoidCallback onTap;
  const Otheroptions({
    super.key,
    required this.text1,
    required this.text2,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Wrap(
        children: [
          Text(
            text1,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              text2,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.primary,
                fontFamily: 'Electrolize'
              ),
            ),
          ),
        ],
      ),
    );
  }
}
