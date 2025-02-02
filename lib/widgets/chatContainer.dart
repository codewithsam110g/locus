import 'package:flutter/material.dart';

class Chatcontainer extends StatelessWidget {
  final String img;
  final String text;
  final String name;
  final VoidCallback function;
  const Chatcontainer({
    super.key,
    required this.img,
    required this.text,
    required this.name,
    required this.function,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circle Avatar for the profile image
          CircleAvatar(
            backgroundImage:
                AssetImage(img.isNotEmpty ? img : 'assets/img/mohan.jpg'),
            radius: 20,
          ),
          const SizedBox(width: 10), // Space between avatar and text container

          // Message container with triangle shape at the top left
          Expanded(
            child: Stack(
              children: [
                // Message container
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.black.withOpacity(0.4),
                      width: 1,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  margin: const EdgeInsets.only(left: 8.0, top: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 1, right: 1),
                    child: Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withOpacity(0.3), // Shadow color
                            spreadRadius: 2, // Spread of the shadow
                            blurRadius: 8, // Blur radius of the shadow
                            offset: Offset(
                                4, 4), // Shadow direction (right and down)
                          ),
                        ],
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.black.withOpacity(0.3),
                          width: 1,
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sender's name
                          Text(
                            name.isNotEmpty ? name : 'Unknown',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 5),

                          // Message text
                          Text(
                            text.isNotEmpty ? text : 'No message available',
                            maxLines: 4, // Limits to four lines with ellipsis
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.reply,
                                    color: Colors.black,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Forward',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: function,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.message,
                                      color: Colors.black,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Message',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Triangle shape at the top-left corner
                Positioned(
                  top: 0,
                  left: 0,
                  child: CustomPaint(
                    size: const Size(20, 20),
                    painter: TrianglePainter(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for the triangle shape
class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5) // Triangle color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 8); // Top-left corner
    path.lineTo(8, 8); // Top-right corner
    path.lineTo(8, size.height); // Bottom-left corner
    path.close(); // Connects back to the top-left corner

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
