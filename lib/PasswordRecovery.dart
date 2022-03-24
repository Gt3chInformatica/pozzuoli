import 'package:flutter/material.dart';
import 'package:flutter/src/material/icons.dart';
import 'package:flutter/src/widgets/editable_text.dart';
import 'package:email_validator/email_validator.dart';

class RecoveryPassword extends StatefulWidget{
  @override
  _RecoveryPassword createState() => _RecoveryPassword();
}
final TextEditingController _controller = new TextEditingController();

class _RecoveryPassword extends State<RecoveryPassword>{

  static const String _email = 'fredrik.eilertsen@gail.com';
  bool _isValid = EmailValidator.validate(_email);

  bool _flagStartApp = false;
  bool _flagClearField = false;

  // dispose it when the widget is unmounted
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  //Controllo campo email
  String? get _errorEmailText{
    final emailText = _controller.value.text;
    if(emailText.isEmpty && _flagStartApp){
      _flagClearField = false;
      return "Il campo non può essere vuoto";
    }else{
      _flagClearField = true;
    }

    //Se l'email è verificata ed è nel formato corretto, ritorna null, altrimenti ritorna il messaggio di errore
    if(_isValid && _flagStartApp){
      return null;
    }else{
      return 'Indirizzo e-mail non valido';
    }
  }

  void _submit() {
    final emailText = _controller.value.text;

    if(emailText == ""){
      Widget okButton = TextButton(
        child: Text("OK"),
        onPressed: () {
          Navigator.pop(context);
        },
      );
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
                title: Text("Attenzione!"),
                content: Text("Impossibile Recuperare la password! Indirizzo e-mail non inserito!"),
                actions: [
                  okButton,
                ]
            );
          }
      );
    }else if(emailText != ""){
        //mettere codice per inviare l'indirizzo email al server per recuperare la password
    }
  }


  // In the state class
  var _text = '';

  @override
  Widget build(BuildContext context){
    return Scaffold(
        appBar: AppBar(
          title: Text("Recupera password"),
        ),
        body: SingleChildScrollView(
            child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left:15.0,right: 15.0,top:60,bottom: 0),
                    // padding: EdgeInsets.symmetric(horizontal: 30),
                    child: TextField(
                      /*Compare la X nel campo di testo e al suo click, si svuota il campo*/
                      controller: _controller,
                      decoration: InputDecoration(
                          border: _flagStartApp ? OutlineInputBorder() : null,
                          errorText: _flagStartApp ? _errorEmailText : null,
                          labelText: 'Indirizzo e-mail',
                          hintText: 'Inserisci indirizzo e-mail',
                          suffixIcon: IconButton(
                            onPressed: _controller.clear,
                            icon: Icon(_flagClearField ? Icons.clear : null),
                          ),
                      ),
                      onChanged: (text) => {
                        setState((){
                          _flagStartApp = true;
                          _text;
                          //.replaceAll(RegExp(r"\s+"), "") equivale a .trim() in javascript
                          _isValid = EmailValidator.validate(text.replaceAll(RegExp(r"\s+"), ""));
                        })
                      }
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
                        _submit();
                      },
                      child: Text(
                        'Recupera',
                        style: TextStyle(color: Colors.white, fontSize: 25),
                      ),
                    ),
                  ),
                ]
            )
        )
    );
  }
}