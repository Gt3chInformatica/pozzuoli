import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';


class SignUp extends StatefulWidget {
  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp>{

  String? name = "";
  String? email = "";
  String? phone = "";
  String? value = "";

  //TextController to read text entered in text field
  TextEditingController password = TextEditingController();
  TextEditingController confirmpassword = TextEditingController();

  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();

  final _controllerName = new TextEditingController();
  final _controllerSurname = new TextEditingController();
  final _controllerEmail = new TextEditingController();

  bool _flagClearFieldName = false;
  bool _flagClearFieldSurname = false;
  bool _flagClearFieldEmail = false;

  // This function is triggered when the clear buttion is pressed
  void _clearFieldName() {
    // Clear everything in the text field
    _controllerName.clear();
    // Call setState to update the UI
    setState(() {});
  }

  void _clearFieldSurname() {
    // Clear everything in the text field
    _controllerSurname.clear();
    // Call setState to update the UI
    setState(() {});
  }

  void _clearFieldEmail() {
    // Clear everything in the text field
    _controllerEmail.clear();
    // Call setState to update the UI
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Registrati",
            style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.orange.shade200,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Form(
            key: _formkey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 15,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15, top: 15, left: 10,right: 10),
                  child: TextFormField(
                    controller: _controllerName,
                    keyboardType: TextInputType.text,
                    onChanged: (value) {
                      // Call setState to update the UI
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      labelText: 'Nome',
                      hintText: 'Inserisci nome utente',
                      border: OutlineInputBorder(),
                      icon: Icon(Icons.account_circle),
                      suffixIcon: _controllerName.text.length == 0
                        ?  null
                        : IconButton(
                        onPressed: _clearFieldName,
                          icon: Icon(Icons.clear),
                        ),
                    ),
                    validator: (value){
                      if(value == "")
                      {
                        return 'Il campo non può essere vuoto';
                      }
                      return null;
                    },
                    onSaved: (value){
                      name = value;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15,left: 10,right: 10),
                  child: TextFormField(
                    controller: _controllerSurname,
                    keyboardType: TextInputType.text,
                    onChanged: (value) {
                      // Call setState to update the UI
                      setState(() {});
                    },
                    decoration: InputDecoration(
                        labelText: 'Cognome',
                        hintText: 'Inserisci cognome utente',
                        border: OutlineInputBorder(),
                        icon: Icon(Icons.account_circle),
                        suffixIcon: _controllerSurname.text.length == 0
                            ?  null
                            : IconButton(
                          onPressed: _clearFieldSurname,
                          icon: Icon(Icons.clear),
                        ),
                    ),
                    validator: (value){
                      if(value == "")
                      {
                        return 'Il campo non può essere vuoto';
                      }
                      return null;
                    },
                    onSaved: (value){
                      name = value;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15,left: 10,right: 10),
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
                            ?  null
                            : IconButton(
                          onPressed: _clearFieldEmail,
                          icon: Icon(Icons.clear),
                        ),
                    ),
                    validator: (value){
                      if(value == "")
                      {
                        return 'Il campo non può essere vuoto';
                      }
                      if(!RegExp("^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+.[a-z]").hasMatch(value!)){
                        return 'Indirizzo e-mail non valido';
                      }
                      return null;
                    },
                    onSaved: (value){
                      email = value;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15,left: 10,right: 10),
                  child: TextFormField(
                    controller: password,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Inserisci password',
                        border: OutlineInputBorder(),
                        icon: Icon(Icons.lock)
                    ),
                    validator: (value){
                      if(value == "")
                      {
                        return 'Il campo non può essere vuoto';
                      }
                      return null;
                    },

                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 15,left: 10,right: 10),
                  child: TextFormField(
                    controller: confirmpassword,
                    obscureText: true,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                        labelText: 'Conferma password',
                        hintText: 'Ripeti password',
                        border: OutlineInputBorder(),
                        icon: Icon(Icons.lock)
                    ),
                    validator: (value){
                      if(value == "")
                      {
                        return 'Reinserisci la password';
                      }
                      print(password.text);

                      print(confirmpassword.text);

                      if(password.text!=confirmpassword.text){
                        return "Password non corrispondenti";
                      }

                      return null;
                    },

                  ),
                ),

                SizedBox(
                  width: 200,
                  height: 50,
                  child: FlatButton(
                    color: Colors.blue,
                    onPressed: (){

                      if(_formkey.currentState!.validate())
                      {
                        print("successful");

                        return;
                      }else{
                        print("UnSuccessfull");
                      }
                    },
                    textColor:Colors.white,child: Text("Registrati"),

                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
  /*final _controllerName = new TextEditingController();
  final _controllerSurname = new TextEditingController();
  final _controllerEmail = new TextEditingController();

  // Form
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final _controllerPassword = new TextEditingController();
  final _controllerConfirmPassword = new TextEditingController();

  // Initially password is obscure
  bool _obscureText = true;

  static const String _email = 'fredrik.eilertsen@gail.com';
  bool _isValid = EmailValidator.validate(_email);

  // Toggles the password show status
  void _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  bool _flagStartAppName = false;
  bool _flagStartAppSurname = false;
  bool _flagStartAppEmail = false;
  bool _flagStartAppPassword = false;
  bool _flagClearFieldName = false;
  bool _flagClearFieldSurname = false;
  bool _flagClearFieldEmail = false;
  bool _flagShowPassword = false;

  // dispose it when the widget is unmounted
  @override
  void dispose() {
    _controllerPassword.dispose();
    _controllerEmail.dispose();
    _controllerSurname.dispose();
    _controllerName.dispose();
    super.dispose();
  }

  //Controllo campo password
  String? get _errorText {
    // at any time, we can get the text from _controller.value.text
    final text = _controllerPassword.value.text;
    // Note: you can do your own custom validation here
    // Move this logic this outside the widget for more testable code
    //Se il campo di testo è vuoto, mostro il messaggio di errore
    if (text.isEmpty) {
      _flagShowPassword = false;
      return 'Il campo non può essere vuoto';
    }
    if (text.length < 4) {
      return 'Password troppo corta';
    }

    _flagShowPassword = true;
    // return null if the text is valid
    return null;
  }

  //Controllo campo email
  String? get _errorEmailText{
    final emailText = _controllerEmail.value.text;
    if(emailText.isEmpty && _flagStartAppEmail){
      _flagClearFieldEmail = false;
      return "Il campo non può essere vuoto";
    }else{
      _flagClearFieldEmail = true;
    }

    //Se l'email è verificata ed è nel formato corretto, ritorna null, altrimenti ritorna il messaggio di errore
    if(_isValid && _flagStartAppEmail){
      return null;
    }else{
      return 'Indirizzo e-mail non valido';
    }
  }

  //Controllo campi nome
  String? get _errorTextName{
    final nameText = _controllerName.value.text;

    if(nameText.isEmpty && _flagStartAppName){
      _flagClearFieldName = false;
      return "Il campo non può essere vuoto";
    }else{
      _flagClearFieldName = true;
    }
  }

  //Controllo campi cognome
  String? get _errorTextSurname{
    final surnameText = _controllerSurname.value.text;

    if(surnameText.isEmpty && _flagStartAppSurname){
      _flagClearFieldSurname = false;
      return "Il campo non può essere vuoto";
    }else{
      _flagClearFieldSurname = true;
    }
  }

  // In the state class
  var _text = '';

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text("Registrati"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left:15.0,right: 15.0,top:60,bottom: 0),
             // padding: EdgeInsets.symmetric(horizontal: 30),
              child: TextField(
                controller: _controllerName,
                decoration: InputDecoration(
                    border: _flagStartAppName ? OutlineInputBorder() : null,
                    errorText: _flagStartAppName ? _errorTextName : null,
                    labelText: 'Nome',
                    hintText: 'Inserisci il nome',
                    suffixIcon: IconButton(
                    onPressed: _controllerName.clear,
                    icon: Icon(_flagClearFieldName ? Icons.clear : null),
                  ),
                ),
                onChanged: (text) => {
                  setState((){
                    _flagStartAppName = true;
                  })
                }
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 0),
              //padding: EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                controller: _controllerSurname,
                decoration: InputDecoration(
                    border: _flagStartAppSurname ? OutlineInputBorder() : null,
                    errorText: _flagStartAppSurname ? _errorTextSurname : null,
                    labelText: 'Cognome',
                    hintText: 'Inserisci il cognome',
                    suffixIcon: IconButton(
                    onPressed: _controllerSurname.clear,
                    icon: Icon(_flagClearFieldSurname ? Icons.clear : null),
                  ),
                ),
                onChanged: (text) => {
                  setState((){
                    _flagStartAppSurname = true;
                  })
                }
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 0),
              //padding: EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                /*Compare la X nel campo di testo e al suo click, si svuota il campo*/
                  controller: _controllerEmail,
                  decoration: InputDecoration(
                    border: _flagStartAppEmail ? OutlineInputBorder() : null,
                    errorText: _flagStartAppEmail ? _errorEmailText : null,
                    labelText: 'Indirizzo e-mail',
                    hintText: 'Inserisci indirizzo e-mail',
                    suffixIcon: IconButton(
                      onPressed: _controllerEmail.clear,
                      icon: Icon(_flagClearFieldEmail ? Icons.clear : null),
                    ),
                  ),
                  onChanged: (text) => {
                    setState((){
                      _flagStartAppEmail = true;
                      _text;
                      //.replaceAll(RegExp(r"\s+"), "") equivale a .trim() in javascript
                      _isValid = EmailValidator.validate(text.replaceAll(RegExp(r"\s+"), ""));
                    })
                  }
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 0),
                //Se _flagShowPassword è true, mostro l'icona per visualizzare la password
                child: _flagShowPassword ?
                TextField(
                  controller: _controllerPassword,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    labelText: 'Inserisci password',
                    border:  _flagStartAppPassword ? OutlineInputBorder() : null,
                    // use the getter variable defined above
                    errorText:  _flagStartAppPassword ? _errorText : null,
                    suffixIcon: IconButton(
                      onPressed: _toggle,
                      icon: Icon(
                          _obscureText ? Icons.remove_red_eye : Icons.remove_red_eye_outlined
                      ), //Icons.remove_red_eye
                    ),
                  ),
                  // this will cause the widget to rebuild whenever the text changes
                  onChanged: (text) => {
                    setState((){
                      _text;
                      _flagStartAppPassword = true;
                    })},
                ) :
                //Se _flagShowPassword è false, non mostro l'icona per visualizzare la password
                TextField(
                  controller: _controllerPassword,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    labelText: 'Inserisci password',
                    border:  _flagStartAppPassword ? OutlineInputBorder() : null,
                    // use the getter variable defined above
                    errorText:  _flagStartAppPassword ? _errorText : null,
                  ),
                  // this will cause the widget to rebuild whenever the text changes
                  onChanged: (text) => {
                    setState((){
                      _text;
                      _flagStartAppPassword = true;
                    })},
                )
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15.0, top: 15, bottom: 0),
              //padding: EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                controller: _controllerPassword,
                obscureText: true,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Conferma password',
                    hintText: 'Reinserisci la password per confermare',
                    suffixIcon: IconButton(
                    onPressed: _controllerPassword.clear,
                    icon: Icon(Icons.clear),
                  ),
                ),
              ),
            ),
            Container(
              height: 50,
              width: 250,
              margin: const EdgeInsets.only(top: 40.0),
              decoration: BoxDecoration(
                  color: Colors.blue, borderRadius: BorderRadius.circular(20)),
              child: FlatButton(
                onPressed: () {
                  //Manda i dati al server
                },
                child: Text(
                  'Registrati',
                  style: TextStyle(color: Colors.white, fontSize: 25),
                ),
              ),
            ),
          ]
        )
      )
    );
  }*/
}