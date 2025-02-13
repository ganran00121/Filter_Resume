import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'home_screen.dart';

class SigninScreen extends StatefulWidget {
  @override
  _SigninScreenState createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  var _isObscured;

  @override
  void initState(){
    super.initState();
    _isObscured = true;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn() {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    print('Email: $email');
    print('Password: $password');
    // Add API call or authentication logic here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(onPressed: () {}, icon: const Icon(Icons.arrow_back_ios)),
        title: Padding(
          padding: EdgeInsets.only(top: 30.0),
          child: Text(
            'Welcome',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.black,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(40.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Form(
                child: Column(
                  children: [
                    buildTextFormField('Email', _emailController),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _isObscured,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _isObscured =!_isObscured;
                            });
                          },
                          icon: _isObscured ? const Icon(Icons.visibility) : const Icon(Icons.visibility_off) ,
                          padding: const EdgeInsetsDirectional.only(end: 12),
                        ),
                        fillColor: Colors.white,
                        filled: true,
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                        floatingLabelStyle: const TextStyle(color: Colors.black),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(width: 2, color: Colors.grey),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 50),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3498DB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Sign in', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 30,),
              const Divider(),
              const SizedBox(height: 30,),
              SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (){},
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0), side: const BorderSide(width: 3.0, color: Color(0xFFE74C3C))
                    )),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Image.asset('assets/images/google_icon.png', height: 24,),
                        const SizedBox(width: 10),
                        Expanded(
                            child:
                            Text('Google', style: TextStyle(color: Color(0xFFE74C3C)), textAlign: TextAlign.center,)
                        ),
                      ],
                    ),
                  )
              ),
              const SizedBox(height: 12,),
              SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (){},
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0), side: const BorderSide(width: 3.0, color: Color(0xFF3498DB))
                    )),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/facebook_icon.png', height: 24,),
                        const SizedBox(width : 10),
                        Expanded(
                          child: Text('Facebook', style: TextStyle(color: Color(0xFF1877F2)), textAlign: TextAlign.center,),
                        ),
                      ],
                    ),
                  )
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SignupScreen()),
                        );
                      },
                      child: const Text(
                        'Sign up now',
                        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.normal),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget buildTextFormField(String label, TextEditingController controller) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: TextFormField(
      controller: controller,
      style: TextStyle(color: Colors.black),
      decoration: InputDecoration(
        fillColor: Colors.white,
        filled: true,
        labelText: label,
        border: OutlineInputBorder(),
        floatingLabelStyle: const TextStyle(color: Colors.black),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(width: 2, color: Colors.grey),
        ),
      ),
    ),
  );
}

// Widget buildPasswordField(String label, TextEditingController controller) {
//   return Padding(
//     padding: const EdgeInsets.only(bottom: 20),
//     child: TextFormField(
//       controller: controller,
//       obscureText: true,
//       style: TextStyle(color: Colors.black),
//       decoration: InputDecoration(
//         suffixIcon: IconButton(
//             onPressed: onPressed,
//             icon: _isObscured ? ,
//           padding: const EdgeInsetsDirectional.only(end: 12),
//         ),
//         fillColor: Colors.white,
//         filled: true,
//         labelText: label,
//         border: OutlineInputBorder(),
//         floatingLabelStyle: const TextStyle(color: Colors.black),
//         focusedBorder: const OutlineInputBorder(
//           borderSide: BorderSide(width: 2, color: Colors.grey),
//         ),
//       ),
//     ),
//   );
// }
