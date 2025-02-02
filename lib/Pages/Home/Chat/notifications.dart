import 'package:flutter/material.dart';
import 'package:locus/Pages/Home/Chat/chatInterface.dart';
import 'package:locus/widgets/primaryWidget.dart';

class Notifications extends StatefulWidget {
  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  final chatLists = [
    {
      'img': 'assets/img/mohan.jpg',
      'name': 'Mohan',
      'lmsg': 'Hello',
      'id': 'mohan123'
    },
    {
      'img': 'assets/img/mohan.jpg',
      'name': 'Nagendra',
      'lmsg': 'Hello',
      'id': 'mohan123'
    },
    {
      'img': 'assets/img/mohan.jpg',
      'name': 'Bala',
      'lmsg': 'Hello',
      'id': 'mohan123'
    },
    {
      'img': 'assets/img/mohan.jpg',
      'name': 'Veera',
      'lmsg': 'Hello',
      'id': 'mohan123'
    },
    {
      'img': 'assets/img/mohan.jpg',
      'name': 'Venkatesh',
      'lmsg': 'Hello',
      'id': 'mohan123'
    },
    {
      'img': 'assets/img/mohan.jpg',
      'name': 'Ponnuru',
      'lmsg': 'Hello',
      'id': 'mohan123'
    },
    {
      'img': 'assets/img/mohan.jpg',
      'name': 'Venkat',
      'lmsg': 'Hello',
      'id': 'mohan123'
    },
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(top: 60.0, left: 20, right: 20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Messages',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                      fontFamily: 'Electrolize'),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).maybePop();
                  },
                  child: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 0,
            ),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.vertical,
                itemCount: chatLists.length,
                itemBuilder: (context, index) {
                  final chatList = chatLists[index];
                  return Primarywidget(
                      img: chatList['img'] as String,
                      name: chatList['name'] as String,
                      lmsg: chatList['lmsg'] as String,
                      function: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (builder) => Chatinterface(
                              name: chatList['name'] as String,
                              img: chatList['img'] as String,
                            ),
                          ),
                        );
                      });
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
