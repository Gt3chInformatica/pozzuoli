import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'HomeAfterLogin.dart';
import 'InfoPage.dart';
import 'StartApp.dart';
import 'sql_helper.dart';
import 'package:http/http.dart' as http;

class LoginApp extends StatefulWidget {
  final Data data;
  LoginApp({required this.data});

  @override
  _LoginAppState createState() => _LoginAppState();
}

class _LoginAppState extends State<LoginApp> {
  String? name = "";
  String? email = "";
  String? phone = "";
  String? value = "";
  String token = "";
  String jwtToken = "";

  Map<String, dynamic> responseJson = new Map<String, dynamic>();

  //TextController to read text entered in text field
  TextEditingController password = TextEditingController();
  TextEditingController confirmpassword = TextEditingController();

  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();

  final _controllerEmail = new TextEditingController();

  bool _isHidden = true;

  List<Map<String, dynamic>> _userData = [];

  void _refreshUserData() async {
    //final db = await SQLHelper.db();
    //SQLHelper.createTablesUserData(db);
    final data = await SQLHelper.getUserData();

    /*final db = await SQLHelper.db();
     SQLHelper.onUpgrade(db);*/
    if (data.isNotEmpty) {
      setState(() {
        _userData = data;
        // _isLoading = false;
      });
    }
  }

  void _clearFieldEmail() {
    // Clear everything in the text field
    _controllerEmail.clear();
    // Call setState to update the UI
    setState(() {});
  }

  Future<void> LoginToServer(jsonData) async {
    final headers = {
      "Content-type": "application/json",
      "Authorization": token
    };
    try {
      //Decodifico il json ricevuto in input
      Map<String, dynamic> responseJson = json.decode(jsonData);

      //Richiesta post al server
      final response = await http.post(
          Uri.parse(
              Uri.encodeFull('http://95.110.130.12:8080/olysislogin/login')),
          headers: headers,
          body: jsonEncode(responseJson));

      //Se l'invio al server è andato a buon fine
      if (response.statusCode == 200) {
        jwtToken = response.headers.entries.last.value;
        token = "Bearer " + jwtToken;

        int userId = await getUserID();
        String cognome_nome = await getUserData(userId);
        print("sono userID in login: " + userId.toString());

        responseJson = json.decode(cognome_nome);
        String cogn_nome = responseJson['response'];

        widget.data.user_id = userId;
        widget.data.cognome_nome = cogn_nome;
        widget.data.tokenSend = token;

        setState(() {
          print("login effettuato");
          Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
              builder: (context) => HomeAfterLogin(data: widget.data)));
        });
      } else if (response.statusCode == 401) {
        Widget okButton = TextButton(
          child: Text("OK"),
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => LoginApp(data: widget.data)));
          },
        );
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                  title: Text("Attenzione!"),
                  content: Text("Errore, credenziali inserite non valide!"),
                  actions: [okButton]);
            });
      } else {
        print("error, not sent");

        Widget okButton = TextButton(
          child: Text("OK"),
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => LoginApp(data: widget.data)));
          },
        );
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                  title: Text("Attenzione!"),
                  content: Text(
                      "Errore nell\'effettuare il login, problemi di connessione al server. Contattare l'amministratore del sistema."),
                  actions: [okButton]);
            });
      }
    } catch (e) {
      print("catch " + e.toString());
      return null;
    }
  }

  Future<int> getUserID() async {
    //Richiesta get al server
    final response = await http.get(
        Uri.parse('http://95.110.130.12:8080/olysislogin/user/getIdByToken'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': token,
          'jwt': jwtToken
        });
    int userid = 0;

    //Se l'invio al server è andato a buon fine
    if (response.statusCode == 200) {
      userid = int.parse(response.body);
      _addUserData(userid);
    }
    return userid;
  }

  Future<String> getUserData(userid) async {
    //Richiesta get al server
    final response = await http.get(
        Uri.parse(
            'http://95.110.130.12:8080/olysislogin/user/getName?userid=${userid}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': token,
          'jwt': jwtToken
        });

    String userData = "";
    print("sono response.statusCode: " + response.statusCode.toString());
    if (response.statusCode == 200) {
      userData = response.body;
    }
    print("sono userData: " + userData.toString());
    return userData;
  }

  Future<void> _addUserData(userid) async {
    //final db = await SQLHelper.db();
    //SQLHelper.createTables(db);

    final data = await SQLHelper.getUserData();
    if (data.isNotEmpty) {
      for (Map<String, dynamic> element in data) {
        //SQLHelper.deleteUserData(element['id']);
        //se esistono già i dati nel db
        if ((email != element['email']) && (userid != element['userID'])) {
          SQLHelper.createUserData(_controllerEmail.text, userid);
        }
      }
    } else {
      SQLHelper.createUserData(_controllerEmail.text, userid);
    }
    _refreshUserData();
  }

  void _goToInfoPage() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => InfoPage()));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => true,
        child: Scaffold(
          appBar: AppBar(
            title: Text("Login", style: TextStyle(color: Colors.black)),
            actions: <Widget>[
              IconButton(
                  icon: Icon(Icons.info), // The "-" icon
                  onPressed: _goToInfoPage)
            ],
            backgroundColor: Colors.orange.shade200,
            iconTheme:
                IconThemeData(color: Colors.black //change your color here
                    ),
          ),
          body: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formkey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 0, left: 10, right: 10),
                      child: Center(
                        child: Container(
                            width: 200,
                            height: 150,
                            /*decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(50.0)),*/
                            child: Image.asset(
                                'asset/images/logo_OLYSIS_trasp.png')),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          bottom: 15, left: 10, right: 10),
                      child: TextFormField(
                        controller: _controllerEmail,
                        keyboardType: TextInputType.text,
                        onChanged: (value) {
                          // Call setState to update the UI
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          labelText: 'E-mail',
                          hintText: 'Inserisci indirizzo e-mail',
                          border: OutlineInputBorder(),
                          icon: Icon(Icons.email),
                          suffixIcon: _controllerEmail.text.length == 0
                              ? null
                              : IconButton(
                                  onPressed: _clearFieldEmail,
                                  icon: Icon(Icons.clear),
                                ),
                        ),
                        validator: (value) {
                          if (value == "") {
                            return 'Il campo non può essere vuoto';
                          }
                          if (!RegExp("^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+.[a-z]")
                              .hasMatch(value!)) {
                            return 'Indirizzo e-mail non valido';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          email = value;
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          bottom: 15, left: 10, right: 10),
                      child: TextFormField(
                        controller: password,
                        keyboardType: TextInputType.text,
                        obscureText: _isHidden,
                        decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Inserisci password',
                            border: OutlineInputBorder(),
                            icon: Icon(Icons.lock)),
                        validator: (value) {
                          if (value == "") {
                            return 'Il campo non può essere vuoto';
                          }
                          return null;
                        },
                      ),
                    ),
                    GestureDetector(
                      child: Text("Password dimenticata?",
                          style: TextStyle(
                              decoration: TextDecoration.underline,
                              color: Colors.blue,
                              fontSize: 15)),
                      onTap: () async {
                        const url =
                            'http://95.110.130.12:8080/olysislogin/#/forgotpassword';
                        if (await canLaunch(url)) launch(url);
                      },
                    ),
                    SizedBox(height: 40),
                    SizedBox(height: 20),
                    SizedBox(
                      width: 200,
                      height: 50,
                      child: RaisedButton(
                        color: Colors.blue,
                        shape: RoundedRectangleBorder(
                            // set the value to a very big number like 100, 1000...
                            borderRadius: BorderRadius.circular(100)),
                        onPressed: () {
                          if (_formkey.currentState!.validate()) {
                            String email = _controllerEmail.text;
                            String passwd = password.text;
                            final jsonData = {
                              "email": email,
                              "password": passwd
                            };
                            LoginToServer(jsonEncode(jsonData));
                            print("successful");
                            return;
                          } else {
                            print("UnSuccessfull");
                          }
                        },
                        textColor: Colors.white,
                        child: Text("Login"),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}
