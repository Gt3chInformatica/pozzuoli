import 'package:flutter/material.dart';
import 'HomeAfterLogin.dart';
import 'Login.dart';
import 'ReportsDetailsPage.dart';
import 'SendingReport.dart';
import 'StartApp.dart';
import 'item_model.dart';
import 'sql_helper.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MyApp extends StatelessWidget {
  final Data data;
  MyApp({required this.data});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Storico segnalazioni',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HistoricalReportsList(data: data, user_id: 0),
    );
  }
}

class HistoricalReportsList extends StatefulWidget {
  Data data;
  int user_id = 0;
  HistoricalReportsList({Key? key, required this.user_id, required this.data}) : super(key: key);

  @override
  _HistoricalReportsListState createState() => _HistoricalReportsListState();
}

class _HistoricalReportsListState extends State<HistoricalReportsList> {
  int user_id = 0;

  int id_segnalazione_sqlite = 0;
  String datetime_sqlite = "";
  String address_sqlite = "";
  double lat_sqlite = 0.0;
  double lon_sqlite = 0.0;
  int check_sending_report_sqlite = 0;
  int user_id_sqlite = 0;
  int intensita_odore_sqlite = 0;
  int durata_sqlite = 0;
  int offensivita_sqlite = 0;
  int tipo_odore_sqlite = 0;
  int id_app_sqlite = 0;

  int array_length = 0;

  List<Map<String, dynamic>> _journals = [];

  List<ItemModel> _items = [];

  var jsonDataRead = {};

  var dataArray = [];

  bool data_is_empty = false;

  String cognome_nome = "";



  int _selectedIndex = 0;
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
    )
  ];

  @override
  void initState() {
    String jwtToken = widget.data.tokenSend.toString();
    String token = jwtToken;
    super.initState();
    _refreshJournals();

    setState(() {
      if (widget.user_id == "" ||
          widget.user_id == null ||
          widget.user_id == 0) {
        user_id = 0;
      } else {
        user_id = widget.user_id;
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

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

//Leggo da sqlite tutte le segnalazioni di un determinato userid
  void _refreshJournals() async {
    final db = await SQLHelper.db();
    SQLHelper.createTables(db);
    final data = await SQLHelper.getItems();

    //Recupero nome e cognome dell'utente loggato
    if (user_id != 0) {
      cognome_nome = await getUserData(user_id);
    }
    print("data.isNotEmpty: "+data.isNotEmpty.toString());
    print("data.isEmpty: "+data.isEmpty.toString());
    if (data.isNotEmpty) {
      data_is_empty = true;
      setState(() {
        _journals = data;
      });

      print("sono userid in historical : " + user_id.toString());

      for (Map<String, dynamic> element in _journals) {
        if (user_id == element['userID']) {
          id_segnalazione_sqlite = element['id'];
          datetime_sqlite = element['datetime'];
          address_sqlite = element['address'];
          lat_sqlite = double.parse(element['lat'].toString());
          lon_sqlite = double.parse(element['lon'].toString());
          check_sending_report_sqlite = element['checkSendingReport'];
          user_id_sqlite = element['userID'];
          intensita_odore_sqlite = element['intensitaOdore'];
          durata_sqlite = element['durata'];
          offensivita_sqlite = element['offensivita'];
          tipo_odore_sqlite = element['tipoOdore'];
          id_app_sqlite = element['IDapp'];
          jsonDataRead = {
            'id_sqlite': id_segnalazione_sqlite,
            'datetime_sqlite': datetime_sqlite,
            'address_sqlite': address_sqlite,
            'lat_sqlite': lat_sqlite,
            'lon_sqlite': lon_sqlite,
            'check_sending_report_sqlite': check_sending_report_sqlite,
            'user_id_sqlite': user_id_sqlite,
            'intensita_odore_sqlite': intensita_odore_sqlite,
            'durata_sqlite': durata_sqlite,
            'offensivita_sqlite': offensivita_sqlite,
            'tipo_odore_sqlite': tipo_odore_sqlite,
            'id_app_sqlite': id_app_sqlite
          };
          dataArray.add(jsonDataRead);
        }
      }

      print("dataArray: " + dataArray.toString());

      for (var k = 0; k < dataArray.length; k++) {
        var datetime = dataArray[k]['datetime_sqlite'];
        _items.add(ItemModel(
            k, Icons.alarm_on, 'Segnalazione del: ${datetime}', '${user_id}'));
      }
    }else{
      data_is_empty = false;
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

    if (data_is_empty) {
      if(user_id!=0){
        return WillPopScope(
            onWillPop: () async => true,
            child: Scaffold(
                appBar: AppBar(
                    title: Text('Storico segnalazioni',
                        style: TextStyle(color: Colors.black)),
                    backgroundColor: Colors.orange.shade200,
                    automaticallyImplyLeading: false, //inibisco la possibilità di tornare indietro scorrendo o cliccando sul pulsante freccia posto in alto a sx della schermata
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
                bottomNavigationBar: BottomNavigationBar(
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Dashoboard',
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
                body: ListView.builder(
                  // Widget which creates [ItemWidget] in scrollable list.
                  itemCount: _items.length, // Number of widget to be created.
                  itemBuilder: (context,
                      itemIndex) => // Builder function for every item with index.
                  ItemWidget(_items[itemIndex], () {
                    _onItemTap(context, itemIndex);
                  }),
                )));
      }else{
        return WillPopScope(
            onWillPop: () async => true,
            child: Scaffold(
                appBar: AppBar(
                    title: Text('Storico segnalazioni',
                        style: TextStyle(color: Colors.black)),
                    backgroundColor: Colors.orange.shade200,
                    automaticallyImplyLeading: false, //inibisco la possibilità di tornare indietro scorrendo o cliccando sul pulsante freccia posto in alto a sx della schermata
                    iconTheme: IconThemeData(
                        color: Colors.black //change your color here
                    )
                ),
                bottomNavigationBar: BottomNavigationBar(
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Dashoboard',
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
                body: ListView.builder(
                  // Widget which creates [ItemWidget] in scrollable list.
                  itemCount: _items.length, // Number of widget to be created.
                  itemBuilder: (context,
                      itemIndex) => // Builder function for every item with index.
                  ItemWidget(_items[itemIndex], () {
                    _onItemTap(context, itemIndex);
                  }),
                )));
      }
    }else{
      if(user_id!=0){
        return WillPopScope(
            onWillPop: () async => true,
            child: Scaffold(
                appBar: AppBar(
                    title: Text('Storico segnalazioni',
                        style: TextStyle(color: Colors.black)),
                    backgroundColor: Colors.orange.shade200,
                    automaticallyImplyLeading: false, //inibisco la possibilità di tornare indietro scorrendo o cliccando sul pulsante freccia posto in alto a sx della schermata
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
                bottomNavigationBar: BottomNavigationBar(
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Dashoboard',
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
                body:
                Padding(
                    padding: const EdgeInsets.only(left:15.0,right: 15.0,top:20,bottom: 0),
                    // padding: EdgeInsets.symmetric(horizontal: 15),
                    child: Text(
                        "Nessuna segnalazione inviata",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15
                        )
                    )
                )));
      }else{
        return WillPopScope(
            onWillPop: () async => true,
            child: Scaffold(
                appBar: AppBar(
                    title: Text('Storico segnalazioni',
                        style: TextStyle(color: Colors.black)),
                    backgroundColor: Colors.orange.shade200,
                    automaticallyImplyLeading: false, //inibisco la possibilità di tornare indietro scorrendo o cliccando sul pulsante freccia posto in alto a sx della schermata
                    iconTheme: IconThemeData(
                        color: Colors.black //change your color here
                    )
                ),
                bottomNavigationBar: BottomNavigationBar(
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Dashoboard',
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
                body: Padding(
                    padding: const EdgeInsets.only(left:15.0,right: 15.0,top:20,bottom: 0),
                    // padding: EdgeInsets.symmetric(horizontal: 15),
                    child: Text(
                        "Nessuna segnalazione inviata",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15
                        )
                    )
                )));
      }
    }

  }

  // Method which uses BuildContext to push (open) new MaterialPageRoute (representation of the screen in Flutter navigation model) with ItemDetailsPage (StateFullWidget with UI for page) in builder.
  _onItemTap(BuildContext context, int itemIndex) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => ReportDetailsPage(_items[itemIndex], dataArray, widget.data)));
  }
}

// StatelessWidget with UI for our ItemModel-s in ListView.
class ItemWidget extends StatelessWidget {
  ItemWidget(this.model, this.onItemTap, {Key? key}) : super(key: key);

  final ItemModel model;
  final VoidCallback onItemTap;
  final jsonDataRead = {};

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // Enables taps for child and add ripple effect when child widget is long pressed.
      onTap: onItemTap,
      child: ListTile(
        // Useful standard widget for displaying something in ListView.
        leading: Icon(model.icon),
        title: Text(model.title),
      ),
    );
  }
}
