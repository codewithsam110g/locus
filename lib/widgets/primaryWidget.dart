import 'package:flutter/material.dart';

class Primarywidget extends StatefulWidget {
  final String img;
  final String name;
  final String lmsg;
  final String time;
  final bool chat;
  final VoidCallback function;
  
  const Primarywidget({
    super.key,
    required this.img,
    required this.name,
    required this.lmsg,
    required this.function,
    required this.time,
    this.chat = false,
  });

  @override
  State<Primarywidget> createState() => _PrimarywidgetState();
}

class _PrimarywidgetState extends State<Primarywidget> {
  // Generate color based on name
  Color getColorFromName(String name) {
    if (name.isEmpty) return Colors.grey;
    
    // Use the ASCII value of the first character to generate a color
    final int asciiValue = name.codeUnitAt(0);
    return Color.fromARGB(
      255,
      (asciiValue * 13) % 255,
      (asciiValue * 7) % 255,
      (asciiValue * 11) % 255,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: widget.function,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: widget.img.isNotEmpty
                          ? (widget.img.contains("asset")
                              ? Image.asset(widget.img)
                              : Image.network(widget.img))
                          : Container(
                              color: getColorFromName(widget.name),
                              child: Center(
                                child: Text(
                                  widget.name.isNotEmpty
                                      ? widget.name[0].toUpperCase()
                                      : "?",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              width: 10,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      widget.lmsg,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color.fromRGBO(155, 155, 155, 1),
                      ),
                      maxLines: 1,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(
                      widget.time,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color.fromRGBO(70, 70, 70, 1),
                      ),
                    )
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}