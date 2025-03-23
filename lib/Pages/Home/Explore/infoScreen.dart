import 'dart:ui';

import 'package:flutter/material.dart';

class Infoscreen extends StatelessWidget {
  final Map<String, dynamic> communityData;

  const Infoscreen({super.key, required this.communityData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(
            height: 15,
          ),
          Container(
            height: 6,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          SizedBox(
            height: 30,
          ),
          Center(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1), // Shadow color
                    blurRadius: 3, // Spread of the shadow
                    spreadRadius: 2, // Extent of the shadow
                    offset: Offset(0, 4), // Shadow position (x, y)
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundImage: communityData['logo_link']
                        .toString()
                        .contains("asset")
                    ? AssetImage(communityData['logo_link']) as ImageProvider
                    : NetworkImage(communityData['logo_link']) as ImageProvider,
              ),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Center(
            child: Text(
              "About ${communityData['title'] ?? 'Unknown Community'}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 25,
                color: Theme.of(context).colorScheme.primary,
                fontFamily: 'Electrolize',
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Description'),
            subtitle: Text(communityData['desc'] ?? 'No description'),
          ),
          ListTile(
            leading: const Icon(Icons.tag),
            title: const Text('Tags'),
            subtitle: Text(communityData['tags'] ?? 'No tags'),
          ),
        ],
      ),
    );
  }
}
