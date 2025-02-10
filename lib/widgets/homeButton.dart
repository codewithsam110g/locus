import 'package:flutter/material.dart';

class HomeButton extends StatelessWidget {
  final String text;
  final double vpadding;
  final double hpadding;
  final VoidCallback function;
  final bool selected;
  const HomeButton({
    super.key,
    required this.text,
    required this.vpadding,
    required this.hpadding,
    required this.function, 
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: function,
      style: ButtonStyle(
        elevation: MaterialStateProperty.all(0),
        backgroundColor: MaterialStateProperty.all(selected ? Colors.white : Colors.transparent),
        side: MaterialStateProperty.all(
          BorderSide(
            color: Colors.white,
            width: 1.5,
          ),
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: hpadding, vertical: vpadding),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.black : Theme.of(context).colorScheme.secondary,
          ),
        ),
      ),
    );
  }
}
