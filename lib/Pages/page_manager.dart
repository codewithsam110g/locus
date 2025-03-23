import 'package:flutter/material.dart';
import 'package:locus/Pages/LoginRegister/loginMain.dart';
import 'package:locus/Pages/Home/mainScreen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PageManager extends StatelessWidget {
  PageManager({super.key});

  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: StreamBuilder(
          stream: supabase.auth.onAuthStateChange,
          builder: (context, snapshot) {
            
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (((snapshot.data as AuthState).session !=null) ||(snapshot.data as AuthState).event == AuthChangeEvent.signedIn) {
              //(snapshot.data as AuthState).session!.user.id;
              return Mainscreen();
            } else if ((snapshot.data as AuthState).session ==
                null) {
              return Align(
                alignment: AlignmentDirectional.center,
                child: Loginmain(),
              );
            } else {
              return const Center(child: Text('Something Went Wrong!'));
            }
          },
        ),
      );
}
