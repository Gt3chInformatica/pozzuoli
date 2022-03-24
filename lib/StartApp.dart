import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'InfoPage.dart';
import 'Login.dart';
import 'SendingReport.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

void main() async {
  /*runApp(
    MaterialApp(
      home: MyApp(),
    ),
  );*/
  runApp(MyApp());
}

class Data {
  int user_id;
  String cognome_nome;
  String tokenSend = '';
  Data(
      {required this.user_id,
      required this.cognome_nome,
      required this.tokenSend});
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: StartApp());
  }
}

class StartApp extends StatefulWidget {
  final data = Data(user_id: 0, cognome_nome: "", tokenSend: "");
  @override
  _StartAppState createState() => _StartAppState();
}

class _StartAppState extends State<StartApp> {
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  String _authStatus = 'Unknown';
  @override
  void initState() {
    super.initState();
    initConnectivity();

    print("qua: "+widget.data.tokenSend.toString());

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);

    // Can't show a dialog in initState, delaying initialization
    WidgetsBinding.instance!.addPostFrameCallback((_) => initPlugin());

  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlugin() async {
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      final TrackingStatus status =
      await AppTrackingTransparency.trackingAuthorizationStatus;
      setState(() => _authStatus = '$status');
      // If the system can show an authorization request dialog
      if (status == TrackingStatus.notDetermined) {
        // Show a custom explainer dialog before the system dialog
        if (await showCustomTrackingDialog(context)) {
          // Wait for dialog popping animation
          await Future.delayed(const Duration(milliseconds: 200));
          // Request system's tracking authorization dialog
          final TrackingStatus status =
          await AppTrackingTransparency.requestTrackingAuthorization();
          setState(() => _authStatus = '$status');
        }
      }
    } on PlatformException {
      setState(() => _authStatus = 'PlatformException was thrown');
    }

    final uuid = await AppTrackingTransparency.getAdvertisingIdentifier();
    print("UUID: $uuid");
  }

  Future<bool> showCustomTrackingDialog(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Caro utente'),
          content: const Text(
            'Abbiamo a cuore la tua privacy e la sicurezza dei dati. Manteniamo questa app gratuita mostrando annunci. '
                'Possiamo continuare a utilizzare i tuoi dati per personalizzare gli annunci per te?\n\nPuoi modificare la tua scelta in qualsiasi momento nelle impostazioni dell\'app.'
            'I nostri partner raccoglieranno dati e utilizzeranno un identificatore univoco sul tuo dispositivo per mostrarti annunci.',
          ),
          actions: [
           /* TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("I'll decide later"),
            ),*/
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continua'),
            ),
          ],
        ),
      ) ??
          false;

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

  void _goToInfoPage() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => InfoPage()));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => true,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text("Benvenuto in Olysis!",
                style: TextStyle(color: Colors.black)),
            automaticallyImplyLeading:
                false, //inibisco la possibilità di tornare indietro scorrendo o cliccando sul pulsante freccia posto in alto a sx della schermata
            backgroundColor: Colors.orange.shade200,
            actions: <Widget>[
              IconButton(
                  icon: Icon(Icons.info), // The "-" icon
                  onPressed: _goToInfoPage)
            ],
            iconTheme:
                IconThemeData(color: Colors.black //change your color here
                    ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Center(
                    child: Container(
                        width: 200,
                        height: 150,
                        child: Image.asset('asset/images/logo_OLYSIS_trasp.png',
                            width: MediaQuery.of(context).size.width)),
                  ),
                ),
                Padding(
                    //padding: const EdgeInsets.only(left:15.0,right: 15.0,top:0,bottom: 0),
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: Text(
                        "Mobile app di Citizens Science per la raccolta e la gestione delle segnalazioni.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20))),
                SizedBox(height: 80),
                Column(children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    //ROW 1
                    children: [
                      SizedBox(
                        width: 200,
                        height: 50,
                        child: RaisedButton(
                          color: Colors.blue,
                          shape: RoundedRectangleBorder(
                              // set the value to a very big number like 100, 1000...
                              borderRadius: BorderRadius.circular(100)),
                          onPressed: () {
                            if (_connectionStatus.toString() ==
                                "ConnectivityResult.none") {
                              showToast();
                            }else{
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          LoginApp(data: widget.data)));
                            } /*else if (_connectionStatus.toString() ==
                                "ConnectivityResult.wifi") {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          LoginApp(data: widget.data)));
                            }*/
                          },
                          textColor: Colors.white,
                          child: Text("Login"),
                        ),
                      )
                    ],
                  ),
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
                        if (_connectionStatus.toString() ==
                            "ConnectivityResult.none") {
                          showToast();
                        } else {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => MyAppMap(data: widget.data)));
                        }
                      },
                      textColor: Colors.white,
                      child: Text("Invia segnalazione"),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ));
   /* return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title:
            Text("Benvenuto in Olysis!", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.orange.shade200,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(10.0),
              child: Center(
                child: Container(
                    width: 200,
                    height: 150,
                    /*decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(50.0)),*/
                    child: Image.asset('asset/images/oly_Logo.png',
                        width: MediaQuery.of(context).size.width)),
              ),
            ),
            Padding(
                //padding: const EdgeInsets.only(left:15.0,right: 15.0,top:0,bottom: 0),
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Text(
                    "Mobile app di Citizens Science per la raccolta e la gestione delle segnalazioni.",
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 20))),
            SizedBox(height: 80),
            Column(children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                //ROW 1
                children: [
                  SizedBox(
                    width: 200,
                    height: 50,
                    child: RaisedButton(
                      color: Colors.blue,
                      shape: RoundedRectangleBorder(
                          // set the value to a very big number like 100, 1000...
                          borderRadius: BorderRadius.circular(100)),
                      onPressed: () {
                        if (_connectionStatus.toString() ==
                            "ConnectivityResult.none") {
                          showToast();
                        } else if (_connectionStatus.toString() ==
                            "ConnectivityResult.wifi") {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => LoginApp(data: widget.data)));
                        }
                      },
                      textColor: Colors.white,
                      child: Text("Login"),
                    ),
                  )
                ],
              ),
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
                    if (_connectionStatus.toString() ==
                        "ConnectivityResult.none") {
                      showToast();
                    } else if (_connectionStatus.toString() ==
                        "ConnectivityResult.wifi") {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => MyAppMap(data: widget.data)));
                    }
                  },
                  textColor: Colors.white,
                  child: Text("Invia segnalazione"),
                ),
              ),
            ]),
          ],
        ),
      ),
    ); */
  }
}
