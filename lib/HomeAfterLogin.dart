import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'HistoricalReportsList.dart';
import 'Login.dart';
import 'SendingReport.dart';
import 'StartApp.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MyAppMap extends StatelessWidget {
  final Data data;
  MyAppMap({required this.data});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomeAfterLogin(data: data));
  }
}

class HomeAfterLogin extends StatefulWidget {

  Data data;

  HomeAfterLogin({Key? key, required this.data})
      : super(key: key);

  @override
  _HomeAfterLoginState createState() => _HomeAfterLoginState();
}

class _HomeAfterLoginState extends State<HomeAfterLogin> {

  String cognome_nome = "";

  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  Map<String, dynamic> responseJson = new Map<String, dynamic>();

  @override
  void initState() {
    super.initState();
    initConnectivity();

    String jwtToken =  widget.data.tokenSend.toString();

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);

      _getUserData();

    print("sono cognmo: " + widget.data.cognome_nome);
  }

  void _getUserData() async {
    String prova = await getUserData(widget.data.user_id);
    cognome_nome = prova;
   // cognome_nome =  responseJson['response'];
    print("cognome: "+cognome_nome);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void showToast() {
    if (_connectionStatus.toString() == "ConnectivityResult.none") {
      Fluttertoast.showToast(
          msg: "Connessione a Internet disattivata",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 2,
          backgroundColor: Colors.black38,
          textColor: Colors.white);
    } else if (_connectionStatus.toString() == "ConnectivityResult.wifi") {
      Fluttertoast.showToast(
          msg: "Connessione a Internet attivata",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 2,
          backgroundColor: Colors.black38,
          textColor: Colors.white);
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initConnectivity() async {
    ConnectivityResult result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print('Couldn\'t check connectivity status: $e');
      return;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    setState(() {
      _connectionStatus = result;
      //print(_connectionStatus);
      showToast();
    });
  }

  Future<String> getUserData(user_id) async {
    print("user_id in getUserData: "+user_id.toString());
    //Richiesta get al server
    final response = await http.get(
        //Uri.parse('http://192.168.1.95:8081/user/getName?userid=${user_id}'),
        Uri.parse('http://95.110.130.12:8080/olysislogin/user/getName?userid=${user_id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': widget.data.tokenSend.toString(),
          'jwt':  widget.data.tokenSend.toString()
        });

    print("response.statusCode; "+response.statusCode.toString());
    String userData = "";
    if (response.statusCode == 200) {
      userData = response.body;
    }

    cognome_nome = userData;
    responseJson = json.decode(cognome_nome);
    String cogn_nome = responseJson['response'];
    print("sono questo cognome: "+cogn_nome);
    return cogn_nome;
  }

  void _goToSettingPage() async{
    final headers = {
      "Content-type": "application/json",
      "Authorization":  widget.data.tokenSend.toString()
    };
    try {

      //Richiesta post al server per cancellazione account
      final response = await http.post(
          Uri.parse(
              Uri.encodeFull('http://95.110.130.12:8080/olysislogin/user/delete2')),
          headers: headers,
          body: '${widget.data.user_id}');
      print('Status code: ${response.statusCode}');

      //Se l'invio al server è andato a buon fine
      if (response.statusCode == 200) {
        setState(() {
          print("sent disable account");

          //Compare il popup di segnalazione inviata con successo
          Widget okButton = TextButton(
            child: Text("OK"),
            onPressed: () {
              //Navigator.of(context, rootNavigator: true).pop();
              _logout();
            },
          );

          Widget noButton = TextButton(
            child: Text("Annulla"),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
            },
          );

          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                    title: Text("Attenzione!"),
                    content: Text(
                        "Sei sicuro di voler cancellare il tuo account? L\'azione è irreversibile."),
                    actions: [okButton, noButton]);
              });
        });
      } else {
        print("error, not sent");

        //Compare il popup di segnalazione inviata con successo
        Widget okButton = TextButton(
          child: Text("OK"),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
          },
        );
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                  title: Text("Attenzione!"),
                  content: Text(
                      "Errore nell'inviare la richiesta di cancellazione account, problemi di connessione al server. Contattare l'amministratore del sistema."),
                  actions: [okButton]);
            });
      }
    } catch (e) {
      print("catch " + e.toString());
      return null;
    }
  }

  void _logout() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userPreference');
    await Future.delayed(Duration(seconds: 2));

    Navigator.of(context).pushAndRemoveUntil(
      // the new route
      MaterialPageRoute(
        builder: (BuildContext context) => StartApp(),
      ),

      // this function should return true when we're done removing routes
      // but because we want to remove all other screens, we make it
      // always return false
          (Route route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => true,
        child: Scaffold(
            appBar: AppBar(
                title: Text("Dashboard", style: TextStyle(color: Colors.black)),
                backgroundColor: Colors.orange.shade200,
                automaticallyImplyLeading:
                false,//nascondo la freccia per tornare alla schermata successiva
                actions: <Widget>[IconButton(
                    icon: Icon(Icons.delete_forever),
                    onPressed: _goToSettingPage
                ),
                  IconButton(
                      icon: Icon(Icons.logout),
                      onPressed: _logout
                  )],
                iconTheme: IconThemeData(
                    color: Colors.black //change your color here
                )
            ),
            body: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Center(
                      child: Container(
                          width: 200,
                          height: 100,
                          child: Image.asset(
                              'asset/images/logo_OLYSIS_trasp.png',
                              width: MediaQuery.of(context).size.width
                          )
                      ),
                    ),
                  ),
                  Padding(
                    //padding: const EdgeInsets.only(left:15.0,right: 15.0,top:0,bottom: 0),
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: Text('Benvenuto ${widget.data.cognome_nome}', textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15
                        )),
                  ),
                  SizedBox(
                      height: 40
                  ),
                  SizedBox(
                    width: 200,
                    height: 50,
                    child: RaisedButton(
                      color: Colors.blue,
                      shape: RoundedRectangleBorder(
                        // set the value to a very big number like 100, 1000...
                          borderRadius: BorderRadius.circular(100)
                      ),
                      onPressed: (){
                        if(_connectionStatus.toString() == "ConnectivityResult.none"){
                          showToast();
                        }else{
                          Navigator.push(context, MaterialPageRoute(builder: (_) => MyStaticMap(data: Data(user_id: widget.data.user_id, cognome_nome: widget.data.cognome_nome, tokenSend: widget.data.tokenSend.toString()), value: widget.data.user_id)));
                        }

                      },
                      textColor:Colors.white,child: Text("Invia segnalazione"),
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: 200,
                    height: 50,
                    child: RaisedButton(
                      color: Colors.blue,
                      shape: RoundedRectangleBorder(
                        // set the value to a very big number like 100, 1000...
                          borderRadius: BorderRadius.circular(100)
                      ),
                      onPressed: (){
                        if(_connectionStatus.toString() == "ConnectivityResult.none"){
                          showToast();
                        }else{
                          Navigator.push(context, MaterialPageRoute(builder: (_) => HistoricalReportsList(data: widget.data, user_id: widget.data.user_id)));
                        }

                      },
                      textColor:Colors.white,child: Text("Storico segnalazioni"),
                    ),
                  ),
                ],
              ),
            )));
  }
}
