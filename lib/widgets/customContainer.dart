import 'package:flutter/material.dart';

class Customcontainer extends StatelessWidget {
  final Widget widget;
  final String text;
  final VoidCallback onTap;
  const Customcontainer({
    super.key,
    required this.widget,
    required this.text, 
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            width: 1,
            color: Colors.black,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0,horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              widget,
              Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              Icon(
                Icons.arrow_forward,
                color: Theme.of(context).colorScheme.primary,
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
