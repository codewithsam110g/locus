import 'package:flutter/material.dart';

class Explorecontainer extends StatelessWidget {
  final String name;
  final String description;
  final String img;

  Explorecontainer({
    super.key,
    required this.name,
    required this.description,
    required this.img,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            width: 1,
            color: Colors.black,
          ),
        ),
        padding: const EdgeInsets.all(5.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10), // Image border radius
                child: img.contains('asset')
                    ? Image.asset(
                        img,
                        height: 80,
                        width: 60,
                        fit: BoxFit.cover,
                      )
                    : Image.network(
                        img,
                        height: 80,
                        width: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/img/clubs.jpg', // Fallback image
                            height: 80,
                            width: 60,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(width: 10), // Space between image and text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      fontFamily: 'Electrolize',
                    ),
                  ),
                  const SizedBox(
                      height: 4), // Space between name and description
                  Text(
                    description,
                    maxLines: 2, // Limit the description to 2 lines
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
