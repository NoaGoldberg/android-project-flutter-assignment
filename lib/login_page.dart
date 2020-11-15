import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_repository.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextStyle style = TextStyle(fontFamily: 'Montserrat', fontSize: 20.0);
  TextEditingController _email;
  TextEditingController _password;
  TextEditingController _password2;
  final _formKey = GlobalKey<FormState>();
  final _key = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: "");
    _password = TextEditingController(text: "");
    _password2 = TextEditingController(text: "");
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserRepository>(context);
    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Text("Login"),
      ),
      body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
              child: Text("Welcome to Startup Names Generator, please log in bellow", textAlign: TextAlign.left,  style: TextStyle(fontSize: 16))
          ),
      Form(
        key: _formKey,
        //child: Center(
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  controller: _email,
                  validator: (value) =>
                      (value.isEmpty) ? "Please Enter Email" : null,
                  style: style,
                  decoration: InputDecoration(
                      prefixIcon: Icon(Icons.email),
                      labelText: "Email",
                      border: OutlineInputBorder()
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  obscureText: true,
                  controller: _password,
                  validator: (value) =>
                      (value.isEmpty) ? "Please Enter Password" : null,
                  style: style,
                  decoration: InputDecoration(
                      prefixIcon: Icon(Icons.lock),
                      labelText: "Password",
                      border: OutlineInputBorder()),
                ),
              ),
              user.status == Status.Authenticating
                  ? Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          Container(
                            width: 340,
                          height: 40,
                          child: Material(
                            borderRadius: BorderRadius.circular(20.0),
                        color: Colors.red,
                        child: MaterialButton(
                          onPressed: () async {
                            if (_formKey.currentState.validate()) {
                              if (!await user.signIn(
                                  _email.text, _password.text))
                                _key.currentState.showSnackBar(SnackBar(
                                  content: Text("There was an error logging into the app"),
                                ));
                            }
                          },
                          child: Text(
                            "Log In",
                            style: style.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),

                        )
                          ),
                           Container(
                            width: 500,
                             height: 40,
                             margin: const EdgeInsets.all(8),
                          child: Material(
                            borderRadius: BorderRadius.circular(20.0),
                            color: Colors.teal,
                        child: MaterialButton(
                          onPressed: () async {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) => Padding(
                              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                              child: Container(
                                height: 200,
                                padding: EdgeInsets.all(10),
                                child: ListView(
                                  // crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Center(
                                        child: Text("Please confirm your password below:", style: TextStyle(fontSize: 18,))
                                    ),
                                    Divider(),
                                    Text("Password", textAlign: TextAlign.left,  style: TextStyle(fontSize: 12, color: Colors.red)),

                                TextFormField(
                                  obscureText: true,
                                  controller: _password2,
                                  validator: (value) =>
                                  (false) ? "Passwords must match" : null,
                                  // (value == _password.text) ? "Passwords must match" : null,
                                  style: style,
                                ),
                                    Center (
                                        child: Container(
                                            margin: EdgeInsets.all(16),
                                      child: RaisedButton(
                                        color: Colors.teal,
                                          textColor: Colors.white,
                                          onPressed: () {
                                              if (_formKey.currentState.validate()) {
                                                _key.currentState.showSnackBar(SnackBar(
                                                  content: Text("${_password2.text}, ${_password.text}"),
                                                  // TODO: THIS
                                                ));
                                              }
                                          },
                                        child: Text("Confirm"),
                                        )
                                        )
                                    )
                                  ],
                                ),
                              ),
                              ),
                            );
                          },
                          child: Text(
                            "New user? Click to sign up",
                            style: style.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),

                        ),
                           ),
                      ],
                      ),
                    ),
            ],
          ),
        //),
      ),
      ]
      )
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _password2.dispose();
    super.dispose();
  }
}
