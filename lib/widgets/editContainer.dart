import 'package:flutter/material.dart';

class Editcontainer extends StatelessWidget {
  final String text;
  final VoidCallback function;
  final bool need;
  final IconData icon;
  const Editcontainer({
    super.key,
    required this.text,
    required this.function,
    required this.need,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: function,
      child: Container(
        width: double.infinity,
        height: height * 0.07,
        decoration: BoxDecoration(
          border: Border.all(
            width: 1,
            color: Colors.black,
          ),
            color: Theme.of(context).colorScheme.tertiary,
            borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.only(left: 25, right: 25),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    text,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.tertiaryContainer),
                  )
                ],
              ),
              if (need)
                Icon(
                  Icons.arrow_forward,
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                )
            ],
          ),
        ),
      ),
    );
  }
}
