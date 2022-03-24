import 'package:flutter/material.dart';
import 'HistoricalReportsList.dart';
import 'HomeAfterLogin.dart';
import 'Login.dart';
import 'SendingReport.dart';
import 'StartApp.dart';
import 'package:google_static_maps_controller/google_static_maps_controller.dart'
as static_map;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'item_model.dart';
import 'package:cool_stepper/cool_stepper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

/// Widget for displaying detailed info of [ItemModel]
class ReportDetailsPage extends StatefulWidget {
  final Data data;

  final ItemModel model;
  var dataArray = [];

  ReportDetailsPage(this.model, this.dataArray, this.data,  {Key? key}) : super(key: key);

  @override
  _ReportDetailsPageState createState() => _ReportDetailsPageState();
}

class _ReportDetailsPageState extends State<ReportDetailsPage> {

  late Data data;

  int _selectedIndex = 0;

  int intensita_odore = 0;
  int _value = 0;
  String intensita_odore_text = '';
  int durata_odore = 0;
  String durata_odore_text = '';
  int offensivita_odore = 0;
  String offensivita_odore_text = '';
  int tipo_odore = 0;
  String tipo_odore_text = '';

  int user_id = 0;

  String cognome_nome = "";



  static const TextStyle optionStyle =
  TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static const List<Widget> _widgetOptions = <Widget>[
    Text(
      'Dashboard',
      style: optionStyle,
    ),
    Text(
      'Invia segnalazione',
      style: optionStyle,
    ),
  ];

  @override
  void initState() {
    String token = widget.data.tokenSend;
    String jwtToken = widget.data.tokenSend;
    super.initState();
    setState(() {
      if (widget.model.description == "" ||
          widget.model.description == null ||
          widget.model.description == 0) {
        user_id = 0;
      } else {
        user_id = int.parse(widget.model.description);
      }
    });
  }

  void getUserDatas() async {
    //Recupero nome e cognome dell'utente loggato
    if (user_id != 0) {
      cognome_nome = await getUserData(user_id);
    }
  }

  Future<String> getUserData(user_id) async {
    //Richiesta get al server
    final response = await http.get(
        Uri.parse('http://95.110.130.12:8080/olysislogin/user/getName?userid=${user_id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': widget.data.tokenSend.toString(),
          'jwt': widget.data.tokenSend.toString()
        });

    String userData = "";
    if (response.statusCode == 200) {
      userData = response.body;
    }
    return userData;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    print("_selectedIndex " + _selectedIndex.toString());
    print("user_id in report detail page: " + user_id.toString());
    print("cognome_nome in report detail page: " + cognome_nome.toString());

    if (user_id != 0 && _selectedIndex == 0) {
      Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
          builder: (context) =>
              HomeAfterLogin(data: widget.data)));
    } else if (user_id == 0 && _selectedIndex == 0) {
      Navigator.of(context, rootNavigator: true)
          .push(MaterialPageRoute(builder: (_) => StartApp()));
    }

    if (_selectedIndex != 0) {
      Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(builder: (context) => MyStaticMap(data: widget.data, value: user_id)));
    }
  }

  void _goToSettingPage() async{
    final headers = {
      "Content-type": "application/json",
      "Authorization": widget.data.tokenSend.toString()
    };
    try {

      //Richiesta post al server per cancellazione account
      final response = await http.post(
          Uri.parse(
              Uri.encodeFull('http://95.110.130.12:8080/olysislogin/user/delete2')),
          headers: headers,
          body: '${user_id}');
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
    getUserDatas();

    intensita_odore =
    widget.dataArray[widget.model.id]['intensita_odore_sqlite'];
    if (intensita_odore != 0) {
      if (intensita_odore == 1) {
        _value = 30;
        intensita_odore_text = "debole";
      }
      if (intensita_odore == 2) {
        _value = 60;
        intensita_odore_text = "distinguibile";
      }
      if (intensita_odore == 3) {
        _value = 90;
        intensita_odore_text = "forte";
      }

      durata_odore = widget.dataArray[widget.model.id]['durata_sqlite'];
      if (durata_odore == 1) {
        durata_odore_text = "Meno di 5 minuti";
      }
      if (durata_odore == 2) {
        durata_odore_text = "Più di un\'ora";
      }
      if (durata_odore == 3) {
        durata_odore_text = "Più di 6 ore";
      }

      offensivita_odore =
      widget.dataArray[widget.model.id]['offensivita_sqlite'];
      if (offensivita_odore == 1) {
        offensivita_odore_text = "Non gradevole";
      }
      if (offensivita_odore == 2) {
        offensivita_odore_text = "Nauseante";
      }

      tipo_odore = widget.dataArray[widget.model.id]['tipo_odore_sqlite'];
      if (tipo_odore == 0) {
        tipo_odore_text = "Rifiuti";
      }
      if (tipo_odore == 1) {
        tipo_odore_text = "Fognatura";
      }
      if (tipo_odore == 2) {
        tipo_odore_text = "Plastica";
      }
      if (tipo_odore == 3) {
        tipo_odore_text = "Traffico veicolare";
      }
      if (tipo_odore == 4) {
        tipo_odore_text = "Bruciato";
      }
      if (tipo_odore == 5) {
        tipo_odore_text = "Letame";
      }
      if (tipo_odore == 6) {
        tipo_odore_text = "Chimico";
      }
      if (tipo_odore == 7) {
        tipo_odore_text = "Altro odore";
      }

      if(user_id != 0){
        return WillPopScope(
            onWillPop: () async => true,
            child: Scaffold(
                appBar: AppBar(
                  title: Text('Dettagli',
                      style: TextStyle(color: Colors.black)),
                  backgroundColor: Colors.orange.shade200,
                  actions: <Widget>[IconButton(
                      icon: Icon(Icons.delete_forever),
                      onPressed: _goToSettingPage
                  ),
                    IconButton(
                        icon: Icon(Icons.logout),
                        onPressed: _logout
                    )],
                  iconTheme: IconThemeData(
                    color: Colors.black, //change your color here
                  ),
                  centerTitle: true,
                ),
                bottomNavigationBar: BottomNavigationBar(
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Dashboard',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.send),
                      label: 'Invia segnalazione',
                    ),
                  ],
                  currentIndex: _selectedIndex,
                  selectedItemColor: Colors.amber[800],
                  onTap: _onItemTapped,
                ),
                body: SingleChildScrollView(
                    child: Stack(
                      children: <Widget>[
                        Column(mainAxisAlignment: MainAxisAlignment.start, children: <
                            Widget>[
                          SizedBox(height: 20),
                          Container(
                              color: Colors.white,
                              child: (Row(children: <Widget>[
                                Expanded(
                                    child: Column(children: <Widget>[
                                      SizedBox(height: 5),
                                      Text("Dati segnalazione",
                                          style: TextStyle(
                                              fontSize: 20, fontWeight: FontWeight.bold)),
                                      SizedBox(height: 10),
                                      Text(
                                          "Segnalazione inviata in data: ${widget.dataArray[widget.model.id]['datetime_sqlite']}"),
                                      Text(
                                          "Presso: ${widget.dataArray[widget.model.id]['address_sqlite']}"),
                                      SizedBox(height: 5),
                                    ]))
                              ]))),
                          Container(
                            height: 300,
                            padding: EdgeInsetsDirectional.zero,
                            child: static_map.StaticMap(
                              width: 400,
                              height: 400,
                              scaleToDevicePixelRatio: true,
                              googleApiKey: "AIzaSyAdSnWsRkQ7QZ9u-FwXIy6betoT3xv8Te8",
                              markers: <static_map.Marker>[
                                /// Define marker style
                                static_map.Marker(
                                  color: Colors.lightBlue,
                                  // label: "A",
                                  locations: [
                                    /// Provide locations for markers of a defined style
                                    //static_map.Location(lat, lon),
                                    static_map.Location(
                                        widget.dataArray[widget.model.id]
                                        ['lat_sqlite'],
                                        widget.dataArray[widget.model.id]
                                        ['lon_sqlite'])
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Padding(
                              padding: const EdgeInsets.only(
                                  left: 0, right: 0, top: 0, bottom: 0),
                              child: FutureBuilder<String>(
                                //future: getLocation(),//getLocation(),
                                  builder: (BuildContext context,
                                      AsyncSnapshot<String> snapshot) {
                                    List<Widget> children;
                                    children = <Widget>[
                                      /*  Padding(
                                    padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 15, bottom: 0),
                                    child: Text('${widget.dataArray[widget.model.id]['datetime_sqlite']} ${widget.dataArray[widget.model.id]['address_sqlite']}'),

                                  ),*/
                                    ];
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: children,
                                      ),
                                    );
                                  })),
                          SizedBox(height: 5),
                          Divider(color: Colors.orange.shade200),
                          SizedBox(height: 5),
                          Container(
                            color: Colors.white,
                            child: (Row(
                              children: <Widget>[
                                // ...
                                Expanded(
                                  child: Column(
                                    children: <Widget>[
                                      SizedBox(height: 5),
                                      Text("Dati questionario",
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold)),
                                      SizedBox(height: 10),
                                      Text(
                                          "Hai percepito un'intensità di odore ${intensita_odore_text}:"),
                                      SfSlider(
                                        min: 0,
                                        max: 90,
                                        showLabels: true,
                                        showDividers: true,
                                        interval: 30,
                                        value: _value,
                                        labelPlacement: LabelPlacement.betweenTicks,
                                        labelFormatterCallback: (dynamic actualValue,
                                            String formattedText) {
                                          switch (actualValue) {
                                            case 0:
                                              return 'Debole';
                                            case 30:
                                              return 'Distinguibile';
                                            case 60:
                                              return 'Forte';
                                          }
                                          return actualValue.toString();
                                        },
                                        onChanged: (dynamic newValue) {},
                                      ),
                                      SizedBox(height: 20),
                                      Text(
                                          "Hai avvertito l'odore per una durata pari a:"),
                                      Column(children: <Widget>[
                                        Row(
                                          //ROW 1
                                          children: [
                                            _buildSelector(
                                                context: context,
                                                name: '${durata_odore_text}'),
                                          ],
                                        ),
                                      ]),
                                      SizedBox(height: 20),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 15.0,
                                            right: 15.0,
                                            top: 5,
                                            bottom: 0),
                                        child: Text(
                                            "Il tipo di odore percepito lo hai associato all\'odore di: '${tipo_odore_text}' e lo hai ritenuto '${offensivita_odore_text}'"),
                                        /*Column(
                                      children: <Widget>[
                                        Row(
                                          //ROW 1
                                          children: [
                                            _buildSelectorOffensivita(
                                                context: context,
                                                name: '${offensivita_odore_text}'
                                            ),
                                          ],
                                        ),
                                      ]
                                  ),*/
                                      ),
                                      SizedBox(height: 20),
                                    ],
                                  ),
                                )
                              ],
                            )),
                          )
                        ]),
                      ],
                    ))));
      }else{
        return WillPopScope(
            onWillPop: () async => true,
            child: Scaffold(
                appBar: AppBar(
                  title: Text('Dettagli',
                      style: TextStyle(color: Colors.black)),
                  backgroundColor: Colors.orange.shade200,
                  iconTheme: IconThemeData(
                    color: Colors.black, //change your color here
                  ),
                  centerTitle: true,
                ),
                bottomNavigationBar: BottomNavigationBar(
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Dashboard',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.send),
                      label: 'Invia segnalazione',
                    ),
                  ],
                  currentIndex: _selectedIndex,
                  selectedItemColor: Colors.amber[800],
                  onTap: _onItemTapped,
                ),
                body: SingleChildScrollView(
                    child: Stack(
                      children: <Widget>[
                        Column(mainAxisAlignment: MainAxisAlignment.start, children: <
                            Widget>[
                          SizedBox(height: 20),
                          Container(
                              color: Colors.white,
                              child: (Row(children: <Widget>[
                                Expanded(
                                    child: Column(children: <Widget>[
                                      SizedBox(height: 5),
                                      Text("Dati segnalazione",
                                          style: TextStyle(
                                              fontSize: 20, fontWeight: FontWeight.bold)),
                                      SizedBox(height: 10),
                                      Text(
                                          "Segnalazione inviata in data: ${widget.dataArray[widget.model.id]['datetime_sqlite']}"),
                                      Text(
                                          "Presso: ${widget.dataArray[widget.model.id]['address_sqlite']}"),
                                      SizedBox(height: 5),
                                    ]))
                              ]))),
                          Container(
                            height: 300,
                            padding: EdgeInsetsDirectional.zero,
                            child: static_map.StaticMap(
                              width: 400,
                              height: 400,
                              scaleToDevicePixelRatio: true,
                              googleApiKey: "AIzaSyAdSnWsRkQ7QZ9u-FwXIy6betoT3xv8Te8",
                              markers: <static_map.Marker>[
                                /// Define marker style
                                static_map.Marker(
                                  color: Colors.lightBlue,
                                  label: "A",
                                  locations: [
                                    /// Provide locations for markers of a defined style
                                    //static_map.Location(lat, lon),
                                    static_map.Location(
                                        widget.dataArray[widget.model.id]
                                        ['lat_sqlite'],
                                        widget.dataArray[widget.model.id]
                                        ['lon_sqlite'])
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Padding(
                              padding: const EdgeInsets.only(
                                  left: 0, right: 0, top: 0, bottom: 0),
                              child: FutureBuilder<String>(
                                //future: getLocation(),//getLocation(),
                                  builder: (BuildContext context,
                                      AsyncSnapshot<String> snapshot) {
                                    List<Widget> children;
                                    children = <Widget>[
                                      /*  Padding(
                                    padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 15, bottom: 0),
                                    child: Text('${widget.dataArray[widget.model.id]['datetime_sqlite']} ${widget.dataArray[widget.model.id]['address_sqlite']}'),

                                  ),*/
                                    ];
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: children,
                                      ),
                                    );
                                  })),
                          SizedBox(height: 5),
                          Divider(color: Colors.orange.shade200),
                          SizedBox(height: 5),
                          Container(
                            color: Colors.white,
                            child: (Row(
                              children: <Widget>[
                                // ...
                                Expanded(
                                  child: Column(
                                    children: <Widget>[
                                      SizedBox(height: 5),
                                      Text("Dati questionario",
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold)),
                                      SizedBox(height: 10),
                                      Text(
                                          "Hai percepito un'intensità di odore ${intensita_odore_text}:"),
                                      SfSlider(
                                        min: 0,
                                        max: 90,
                                        showLabels: true,
                                        showDividers: true,
                                        interval: 30,
                                        value: _value,
                                        labelPlacement: LabelPlacement.betweenTicks,
                                        labelFormatterCallback: (dynamic actualValue,
                                            String formattedText) {
                                          switch (actualValue) {
                                            case 0:
                                              return 'Debole';
                                            case 30:
                                              return 'Distinguibile';
                                            case 60:
                                              return 'Forte';
                                          }
                                          return actualValue.toString();
                                        },
                                        onChanged: (dynamic newValue) {},
                                      ),
                                      SizedBox(height: 20),
                                      Text(
                                          "Hai avvertito l'odore per una durata pari a:"),
                                      Column(children: <Widget>[
                                        Row(
                                          //ROW 1
                                          children: [
                                            _buildSelector(
                                                context: context,
                                                name: '${durata_odore_text}'),
                                          ],
                                        ),
                                      ]),
                                      SizedBox(height: 20),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 15.0,
                                            right: 15.0,
                                            top: 5,
                                            bottom: 0),
                                        child: Text(
                                            "Il tipo di odore percepito lo hai associato all\'odore di: '${tipo_odore_text}' e lo hai ritenuto '${offensivita_odore_text}'"),
                                        /*Column(
                                      children: <Widget>[
                                        Row(
                                          //ROW 1
                                          children: [
                                            _buildSelectorOffensivita(
                                                context: context,
                                                name: '${offensivita_odore_text}'
                                            ),
                                          ],
                                        ),
                                      ]
                                  ),*/
                                      ),
                                      SizedBox(height: 20),
                                    ],
                                  ),
                                )
                              ],
                            )),
                          )
                        ]),
                      ],
                    ))));
      }

    } else {
      if(user_id != 0){
        return WillPopScope(
            onWillPop: () async => true,
            child: Scaffold(
                appBar: AppBar(
                  title: Text('Dettagli segnalazione',
                      style: TextStyle(color: Colors.black)),
                  backgroundColor: Colors.orange.shade200,
                ),
                bottomNavigationBar: BottomNavigationBar(
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: Icon(Icons.send),
                      label: 'Invio segnalazione',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.calendar_today),
                      label: 'Storico segnalazioni',
                    ),
                  ],
                  currentIndex: _selectedIndex,
                  selectedItemColor: Colors.amber[800],
                  onTap: _onItemTapped,
                ),
                body: SingleChildScrollView(
                    child: Stack(children: <Widget>[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(height: 20),
                          Container(
                              color: Colors.white,
                              child: (Row(children: <Widget>[
                                Expanded(
                                    child: Column(children: <Widget>[
                                      SizedBox(height: 5),
                                      Text("Dati segnalazione",
                                          style: TextStyle(
                                              fontSize: 20, fontWeight: FontWeight.bold)),
                                      SizedBox(height: 10),
                                      Text(
                                          "Segnalazione inviata in data: ${widget.dataArray[widget.model.id]['datetime_sqlite']}"),
                                      Text(
                                          "Presso: ${widget.dataArray[widget.model.id]['address_sqlite']}"),
                                      SizedBox(height: 5),
                                    ]))
                              ]))),
                          Container(
                            height: 300,
                            padding: EdgeInsetsDirectional.zero,
                            child: static_map.StaticMap(
                              width: 400,
                              height: 400,
                              scaleToDevicePixelRatio: true,
                              googleApiKey: "AIzaSyAdSnWsRkQ7QZ9u-FwXIy6betoT3xv8Te8",
                              markers: <static_map.Marker>[
                                /// Define marker style
                                static_map.Marker(
                                  color: Colors.lightBlue,
                                  label: "A",
                                  locations: [
                                    /// Provide locations for markers of a defined style
                                    //static_map.Location(lat, lon),
                                    static_map.Location(
                                        widget.dataArray[widget.model.id]
                                        ['lat_sqlite'],
                                        widget.dataArray[widget.model.id]
                                        ['lon_sqlite'])
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Padding(
                              padding: const EdgeInsets.only(
                                  left: 0, right: 0, top: 0, bottom: 0),
                              child: FutureBuilder<String>(
                                //future: getLocation(),//getLocation(),
                                  builder: (BuildContext context,
                                      AsyncSnapshot<String> snapshot) {
                                    List<Widget> children;
                                    children = <Widget>[
                                      /*Padding(
                                padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 15, bottom: 0),
                                child: Text('${widget.dataArray[widget.model.id]['datetime_sqlite']} ${widget.dataArray[widget.model.id]['address_sqlite']}'),
                              ),*/
                                    ];
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: children,
                                      ),
                                    );
                                  })),
                          SizedBox(height: 5),
                          Divider(color: Colors.orange.shade200),
                          SizedBox(height: 5),
                          Container(
                              color: Colors.white,
                              child: (Row(children: <Widget>[
                                Expanded(
                                  child: Column(
                                    children: <Widget>[
                                      SizedBox(height: 5),
                                      Text("Dati questionario",
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold)),
                                      SizedBox(height: 10),
                                      Text("Non hai compilato il questionario"),
                                      SizedBox(height: 20),
                                    ],
                                  ),
                                )
                              ])))
                        ],
                      )
                    ]))));
      }else{
        return WillPopScope(
            onWillPop: () async => true,
            child: Scaffold(
                appBar: AppBar(
                  title: Text('Dettagli segnalazione',
                      style: TextStyle(color: Colors.black)),
                  backgroundColor: Colors.orange.shade200,
                  iconTheme: IconThemeData(
                    color: Colors.black, //change your color here
                  ),
                ),
                bottomNavigationBar: BottomNavigationBar(
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: Icon(Icons.send),
                      label: 'Invio segnalazione',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.calendar_today),
                      label: 'Storico segnalazioni',
                    ),
                  ],
                  currentIndex: _selectedIndex,
                  selectedItemColor: Colors.amber[800],
                  onTap: _onItemTapped,
                ),
                body: SingleChildScrollView(
                    child: Stack(children: <Widget>[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(height: 20),
                          Container(
                              color: Colors.white,
                              child: (Row(children: <Widget>[
                                Expanded(
                                    child: Column(children: <Widget>[
                                      SizedBox(height: 5),
                                      Text("Dati segnalazione",
                                          style: TextStyle(
                                              fontSize: 20, fontWeight: FontWeight.bold)),
                                      SizedBox(height: 10),
                                      Text(
                                          "Segnalazione inviata in data: ${widget.dataArray[widget.model.id]['datetime_sqlite']}"),
                                      Text(
                                          "Presso: ${widget.dataArray[widget.model.id]['address_sqlite']}"),
                                      SizedBox(height: 5),
                                    ]))
                              ]))),
                          Container(
                            height: 300,
                            padding: EdgeInsetsDirectional.zero,
                            child: static_map.StaticMap(
                              width: 400,
                              height: 400,
                              scaleToDevicePixelRatio: true,
                              googleApiKey: "AIzaSyAdSnWsRkQ7QZ9u-FwXIy6betoT3xv8Te8",
                              markers: <static_map.Marker>[
                                /// Define marker style
                                static_map.Marker(
                                  color: Colors.lightBlue,
                                  label: "A",
                                  locations: [
                                    /// Provide locations for markers of a defined style
                                    //static_map.Location(lat, lon),
                                    static_map.Location(
                                        widget.dataArray[widget.model.id]
                                        ['lat_sqlite'],
                                        widget.dataArray[widget.model.id]
                                        ['lon_sqlite'])
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Padding(
                              padding: const EdgeInsets.only(
                                  left: 0, right: 0, top: 0, bottom: 0),
                              child: FutureBuilder<String>(
                                //future: getLocation(),//getLocation(),
                                  builder: (BuildContext context,
                                      AsyncSnapshot<String> snapshot) {
                                    List<Widget> children;
                                    children = <Widget>[
                                      /*Padding(
                                padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 15, bottom: 0),
                                child: Text('${widget.dataArray[widget.model.id]['datetime_sqlite']} ${widget.dataArray[widget.model.id]['address_sqlite']}'),
                              ),*/
                                    ];
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: children,
                                      ),
                                    );
                                  })),
                          SizedBox(height: 5),
                          Divider(color: Colors.orange.shade200),
                          SizedBox(height: 5),
                          Container(
                              color: Colors.white,
                              child: (Row(children: <Widget>[
                                Expanded(
                                  child: Column(
                                    children: <Widget>[
                                      SizedBox(height: 5),
                                      Text("Dati questionario",
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold)),
                                      SizedBox(height: 10),
                                      Text("Non hai compilato il questionario"),
                                      SizedBox(height: 20),
                                    ],
                                  ),
                                )
                              ])))
                        ],
                      )
                    ]))));
      }

    }
  }

  Widget _buildSelector({BuildContext? context, required String name}) {
    return Expanded(
        child: Padding(
          padding:
          const EdgeInsets.only(left: 15.0, right: 15.0, top: 15, bottom: 0),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: Theme.of(context!).primaryColor,
              border: Border.all(
                width: 0,
              ),
              borderRadius: BorderRadius.circular(200.0),
            ),
            child: RadioListTile(
              value: name,
              activeColor: Colors.white,
              groupValue: durata_odore_text,
              title: Text(
                "${durata_odore_text}",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              onChanged: (String? value) {},
            ),
          ),
        ));
  }

  Widget _buildSelectorOffensivita(
      {BuildContext? context, required String name}) {
    return Expanded(
        child: Padding(
          padding:
          const EdgeInsets.only(left: 15.0, right: 15.0, top: 15, bottom: 0),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: Theme.of(context!).primaryColor,
              border: Border.all(
                width: 0,
              ),
              borderRadius: BorderRadius.circular(200.0),
            ),
            child: RadioListTile(
              value: name,
              activeColor: Colors.white,
              groupValue: offensivita_odore_text,
              title: Text(
                "${offensivita_odore_text}",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              onChanged: (String? value) {},
            ),
          ),
        ));
  }
}
