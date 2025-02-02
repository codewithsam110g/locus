import 'package:flutter/material.dart';
import 'package:locus/Pages/LoginRegister/loginMain.dart';
import 'package:locus/Pages/LoginRegister/register/register1.dart';
import 'package:locus/widgets/customContainer.dart';
import 'package:locus/widgets/otherOptions.dart';

class Registermain extends StatefulWidget {
  @override
  State<Registermain> createState() => _RegistermainState();
}

class _RegistermainState extends State<Registermain> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 40.0),
                child: Image.asset('assets/img/locus1.png'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Container(
                  height: 9,
                  width: 180,
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(5)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Text(
                  'Register',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.primary,
                    fontFamily: 'Electrolize',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 25.0),
                child: Customcontainer(
                  widget: Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  text: 'Continue with Email',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (builder) => Register1(),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 25.0),
                child: Customcontainer(
                  widget: Image.asset(
                    'assets/img/google.png',
                    height: 30,
                    width: 30,
                  ),
                  text: 'Continue with Google',
                  onTap: () {},
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Otheroptions(
                  text1: 'Already have an account? ',
                  text2: 'Login',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (builder) => Loginmain(),
                      ),
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: 9,
                  width: 180,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
