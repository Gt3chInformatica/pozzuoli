import 'dart:convert';

import 'package:cool_stepper/cool_stepper.dart';
import 'package:flutter/material.dart';
import 'HistoricalReportsList.dart';
import 'HomeAfterLogin.dart';
import 'Login.dart';
import 'StartApp.dart';
import 'sql_helper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:http/http.dart' as http;

import 'SendingReport.dart';

void main() {
  runApp(SurveyPage(data: Data(user_id: 0, cognome_nome: "", tokenSend: "")));
}

class SurveyPage extends StatelessWidget {
  final Data data;
  SurveyPage({required this.data});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Questionario',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),
      debugShowCheckedModeBanner: false,
      home: Survey(
          title: 'Questionario',
          jsonData: '',
          check_sending_report: 0,
          user_id: 0,
          data: data),
    );
  }
}

class Survey extends StatefulWidget {
  final Data data;

  String jsonData;
  int check_sending_report = 0;
  int user_id = 0;

  Survey(
      {Key? key,
      required this.title,
      required this.jsonData,
      required this.check_sending_report,
      required this.user_id,
      required this.data})
      : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<Survey> {
  String? jsonData;

  final _formKey = GlobalKey<FormState>();
  String? selectedRole = 'Meno 5 minuti';
  String? selectedRole2 = 'Non gradevole';

  int check_sending_report = 0;

  int intensita_odore = 0;
  int durata_evento = 1;
  int offensivita = 1;
  int tipo_odore = 1;

  String dropdownValue = 'Rifiuti';

  String datetime_read = "";

  double _value = 0;

  double lat = 0.0;
  double lon = 0.0;
  String date = "";
  String address = "";
  int user_type = 0;
  int user_id = 0;
  int id_app = 0;

  String api_server_connection = "http://192.168.1.95:8081/"; //locale
  String api_server_connection2 = "http://95.110.130.12:8080/olysislogin/"; //server

  List<Map<String, dynamic>> _journals = [];

  int _selectedIndex = 0;
  String cognome_nome = "";
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static const List<Widget> _widgetOptions = <Widget>[
    Text(
      'Dashboard',
      style: optionStyle,
    ),
    Text(
      'Storico segnalazioni',
      style: optionStyle,
    )
  ];

  void _refreshJournals() async {
    print("in refreshjourna da init survey");
    print(
        "sono user id in refreshjourna da init survey: " + user_id.toString());
    final data = await SQLHelper.getItems();
    print("data sqlite in survey: " + data.toString());

    //Se ci sono i dati in SQLite
    if (data.isNotEmpty) {
      setState(() {
        _journals = data;
        // _isLoading = false;
      });

      //Recupero l'ultimo id della segnalazione inviata sulla base dell'userID in questione
      int last_id = await getLastId(user_id);
      id_app = last_id;
      print("debug last_id in survey: " + last_id.toString());

      //Recupero nome e cognome dell'utente loggato
      cognome_nome = await getUserData(user_id);
      print("cognome_nome in survey: " + cognome_nome.toString());

      //Ciclo sui dati presenti in SQLite
      for (Map<String, dynamic> element in _journals) {

        //Se l'userID preso dal login è uguale all'userID letto dal DB SQLite
        if (user_id == element['userID']) {

          //Recupero il valore di check_sending_report sulla base dell'id recuperato poc'anzi
          final getCheckSendingReport =
          await SQLHelper.getCheckSendingReportByID(user_id);
          int? checkSendingReportRead;

          //Sulla base del valore di checksendingreport preso dal server, recupero da SQLite i valori letti dal file di checksendingreport e datetime
          for (Map<String, dynamic> element in getCheckSendingReport) {
            checkSendingReportRead = element['checkSendingReport'];
            datetime_read = element['datetime'];
            print("QUI datetime_read survey: " + datetime_read);
          }//end for

          //Incremento la variabile id_app a seconda del fatto che è stata inviata 1 o n segnalazioni al server
          if (checkSendingReportRead == 1) {
            check_sending_report = checkSendingReportRead!;
          }else{
            check_sending_report = 0;
          }
        }//end if (user_id == element['userID'])else{


      }//end for (Map<String, dynamic> element in _journals)

      if(id_app != 0 && datetime_read == ""){
        //recupero datetime dal db del server
        datetime_read = await getDatetime(user_id);
        check_sending_report = 1;
      }
    //Se non ci sono dati in SQLite
    }else {
      if(id_app != 0){
        check_sending_report = 1;
      }else{
        check_sending_report = 0;
        id_app = 0;
      }
    }

  }


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (user_id != 0 && _selectedIndex == 0) {
      Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
          builder: (context) => HomeAfterLogin(data: widget.data)));
    } else if (user_id == 0 && _selectedIndex == 0) {
      Navigator.of(context, rootNavigator: true)
          .push(MaterialPageRoute(builder: (_) => StartApp()));
    }

    if (_selectedIndex != 0) {
      Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
          builder: (context) =>
              HistoricalReportsList(data: widget.data, user_id: user_id)));
    }
  }

  Future<int> getLastId(user_id) async {
    print("user id in getlastid survey: " + user_id.toString());
    //Richiesta get al server
    final response = await http.get(
        Uri.parse(
            api_server_connection2+'pozzuoli/getLastId?userid=${user_id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': widget.data.tokenSend.toString(),
          'jwt': widget.data.tokenSend.toString()
        });

    int id_app = 0;
    if (response.statusCode == 200) {
      id_app = int.parse(response.body);
    }
    print("user id in getlastid survey: " + user_id.toString());
    return id_app;
  }

  Future<String> getDatetime(user_id) async {
    //Richiesta get al server
    final response = await http.get(
        Uri.parse(
            api_server_connection2+'pozzuoli/getLastDate?userid=${user_id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization':  widget.data.tokenSend.toString(),
          'jwt': widget.data.tokenSend.toString()
        });

    String datetime = "";
    if (response.statusCode == 200) {
      datetime = response.body;
    }

    List datetime_split = datetime.split(" ");
    var only_date = datetime_split[0];
    var only_time = datetime_split[1];

    List only_date_split = only_date.split("-");
    var year = only_date_split[0];
    var month = only_date_split[1];
    var day = only_date_split[2];

    List only_time_split = only_time.split(".");
    var timeOk = only_time_split[0];

    String dtime = day + "-" + month + "-" + year + " " + timeOk;

    return dtime;
  }

  Future<String> getUserData(user_id) async {
    //Richiesta get al server
    final response = await http.get(
        Uri.parse(
            api_server_connection2+'user/getName?userid=${user_id}'),
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

  @override
  void initState() {
    String jwtToken = widget.data.tokenSend.toString();
    String token = jwtToken;

    print("WIDGERTTT:" +widget.data.tokenSend.toString());

    super.initState();

    if (widget.user_id == "" || widget.user_id == null || widget.user_id == 0) {
      user_id = 0;
    } else {
      user_id = widget.user_id;
    }

    if (widget.check_sending_report == "" ||
        widget.check_sending_report == null ||
        widget.check_sending_report == 0) {
      check_sending_report = 0;
    } else {
      check_sending_report = widget.check_sending_report;
    }

    _refreshJournals(); // Loading the diary when the app starts
  }

  static final DateTime now = DateTime.now();
  static final DateFormat formatter = DateFormat('dd-MM-yyyy');
  final String dateFormatted = formatter.format(now);

  //now.hour.toString() + ":" + now.minute.toString() + ":" + now.second.toString()
  int hour = now.hour;
  int minute = now.minute;
  int second = now.second;

  String setTime() {
    String min, sec;
    if (minute <= 9) {
      min = "0" + minute.toString();
    } else {
      min = minute.toString();
    }

    if (second <= 9) {
      sec = "0" + second.toString();
    } else {
      sec = second.toString();
    }
    return dateFormatted + " " + now.hour.toString() + ":" + min + ":" + sec;
  }

  //Questa funzione viene chiamata quando si clicca sul pulsante invia, per inviare una segnalazione
  //@override
  void saveDatetime(datetime, check_sending_report, jsonData) {
    //riceve in input datetime, check_sending_report e il jsonData (che attualmente non viene utilizzato)

    //eseguo lo split su " " di datetime
    List data_file_split = datetime.split(" ");

    //Dal precedente split, ottengo i valori:
    var complete_date_written = data_file_split[0];
    var complete_hour_written = data_file_split[1];

    //Dall'orario ricavato dal precedente split, eseguo lo split sul carattere : e recupero il valore delle ore
    List hour_written = complete_hour_written.split(":");
    int hh_written = int.parse(hour_written[0]);

    //Recupero il datetime attuale da sistema
    String complete_datetime_now = setTime();

    //Eseguo lo split sul datetime attuale, splittando sul carattere spazio vuoto
    List datetime_now = complete_datetime_now.split(" ");
    //Recupero l'orario attuale (in posizione 1)
    var complete_date_now = datetime_now[1];
    //Recupero la data attuale (in posizione 0)
    var date_now = datetime_now[0];

    //Dell'orario recuperato poc'anzi, eseguo lo split sul carattere : e recupero solo il valore delle ore
    List hour_now = complete_date_now.split(":");
    int hh_now = int.parse(hour_now[0]);

    //Eseguo il controllo sulle fasce orarie
    //Se il flag check_sending_report è 1 e la data scritta nel file e quella attuale sono uguali:
    if ((check_sending_report == 1)) {
      //Dichiaro la variabile per l'orario consentito
      String allowed_time = "";

      //Verifico se la data attuale di sistema e quella letta da sqlite sono uguali
      if (date_now == complete_date_written) {
        //Se il range di entrambi gli orari è entro le 15, setto la variabile dell'orario consentito su 16
        if (((hh_written >= 09 && hh_written < 15) &&
            (hh_now >= 09 && hh_now < 15))) {
          allowed_time = "16:00";
          //... se si verifica che entrambi gli orari rientrano nello stesso range con la stessa data
          //compare il popup di alert
          Widget okButton = TextButton(
            child: Text("OK"),
            onPressed: () {
              if (user_id == 0) {
                Navigator.of(context, rootNavigator: true)
                    .push(MaterialPageRoute(builder: (_) => StartApp()));
              } else {
                Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                        builder: (_) => HomeAfterLogin(data: widget.data)));
              }
            },
          );
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                    title: Text("Attenzione!"),
                    content: Text(
                        'Non puoi inviare più di una segnalazione lo stesso giorno nella stessa fascia oraria! Riprova alle ore: ${allowed_time}.'),
                    actions: [okButton]);
              });
          //Se il range di entrambi gli orari è entro le 21, setto la variabile dell'orario consentito su 22
        } else if ((hh_written >= 15 && hh_written < 21) &&
            (hh_now >= 15 && hh_now < 21)) {
          allowed_time = "22:00";
          //... se si verifica che entrambi gli orari rientrano nello stesso range con la stessa data
          //compare il popup di alert
          Widget okButton = TextButton(
            child: Text("OK"),
            onPressed: () {
              if (user_id == 0) {
                Navigator.of(context, rootNavigator: true)
                    .push(MaterialPageRoute(builder: (_) => StartApp()));
              } else {
                Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                        builder: (_) => HomeAfterLogin(data: widget.data)));
              }
            },
          );
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                    title: Text("Attenzione!"),
                    content: Text(
                        'Non puoi inviare più di una segnalazione lo stesso giorno nella stessa fascia oraria! Riprova alle ore: ${allowed_time}.'),
                    actions: [okButton]);
              });
          //Se il range di entrambi gli orari è entro le 03, setto la variabile dell'orario consentito su 04
        } else if ((hh_written >= 21 && hh_written < 03) &&
            (hh_now >= 21 && hh_now < 03)) {
          allowed_time = "04:00";
          //... se si verifica che entrambi gli orari rientrano nello stesso range con la stessa data
          //compare il popup di alert
          Widget okButton = TextButton(
            child: Text("OK"),
            onPressed: () {
              if (user_id == 0) {
                Navigator.of(context, rootNavigator: true)
                    .push(MaterialPageRoute(builder: (_) => StartApp()));
              } else {
                Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                        builder: (_) => HomeAfterLogin(data: widget.data)));
              }
            },
          );
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                    title: Text("Attenzione!"),
                    content: Text(
                        'Non puoi inviare più di una segnalazione lo stesso giorno nella stessa fascia oraria! Riprova alle ore: ${allowed_time}.'),
                    actions: [okButton]);
              });
          //Se il range di entrambi gli orari è entro le 09, setto la variabile dell'orario consentito su 10
        } else if ((hh_written >= 03 && hh_written < 09) &&
            (hh_now >= 03 && hh_now < 09)) {
          allowed_time = "10:00";
          //... se si verifica che entrambi gli orari rientrano nello stesso range con la stessa data
          //compare il popup di alert
          Widget okButton = TextButton(
            child: Text("OK"),
            onPressed: () {
              if (user_id == 0) {
                Navigator.of(context, rootNavigator: true)
                    .push(MaterialPageRoute(builder: (_) => StartApp()));
              } else {
                Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                        builder: (_) => HomeAfterLogin(data: widget.data)));
              }
            },
          );
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                    title: Text("Attenzione!"),
                    content: Text(
                        'Non puoi inviare più di una segnalazione lo stesso giorno nella stessa fascia oraria! Riprova alle ore: ${allowed_time}.'),
                    actions: [okButton]);
              });
        } else {
          makePostRequest(datetime, jsonEncode(jsonData));
        }
      } else {
        makePostRequest(datetime, jsonEncode(jsonData));
      }
    } else if (check_sending_report == 0) {
      makePostRequest(datetime, jsonEncode(jsonData));
    }
  } //end saveDatetime

  Future<void> makePostRequest(date, data) async {
    final headers = {
      "Content-type": "application/json",
      "Authorization": widget.data.tokenSend.toString()
    };
    print("data prima di invio al server:" + data.toString());
    print("token inviato al server:" + widget.data.tokenSend.toString());
    try {
      final response = await http.post(
          Uri.parse(Uri.encodeFull(
              api_server_connection2+'pozzuoli/insert')),
          headers: headers,
          body: data);
      print('Status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        setState(() {
          check_sending_report = 1;
          _addItem();
          print("sent in survey");
          Widget okButton = TextButton(
            child: Text("OK"),
            onPressed: () {
              if (user_id == 0) {
                Navigator.of(context, rootNavigator: true)
                    .push(MaterialPageRoute(builder: (_) => StartApp()));
              } else {
                Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                        builder: (_) => HomeAfterLogin(data: widget.data)));
              }
            },
          );
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                    title: Text("Perfetto!"),
                    content: Text(
                        "Segnalazione inviata con successo, grazie per il tuo contributo."),
                    actions: [okButton]);
              });
        });
      }
    } catch (e) {
      print(e);
      return null;
    }
  }

  // Insert a new journal to the database
  Future<void> _addItem() async {
    final db = await SQLHelper.db();

    //SQLHelper.createTables(db);
    await SQLHelper.createItem(
        date,
        address,
        lat,
        lon,
        check_sending_report,
        user_id,
        intensita_odore,
        durata_evento,
        offensivita,
        tipo_odore,
        id_app);
    _refreshJournals();
  }

  void _goToSettingPage() async {
    final headers = {
      "Content-type": "application/json",
      "Authorization": widget.data.tokenSend.toString()
    };
    try {
      //Richiesta post al server per cancellazione account
      final response = await http.post(
          Uri.parse(Uri.encodeFull(
              api_server_connection2+'user/delete2')),
          headers: headers,
          body: '${user_id}');

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

  void _logout() async {
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
    final steps = [
      CoolStep(
        title: 'Informazioni di base',
        subtitle:
            'Seleziona un\'intensità di odore per proseguire al prossimo step',
        content: Form(
          key: _formKey,
          child: Column(
            children: [
              SfSlider(
                min: 0,
                max: 90,
                showLabels: true,
                showDividers: true,
                interval: 30,
                value: _value,
                labelPlacement: LabelPlacement.betweenTicks,
                labelFormatterCallback:
                    (dynamic actualValue, String formattedText) {
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
                onChanged: (dynamic newValue) {
                  setState(
                    () {
                      _value = newValue;

                      if (_value > 0 && _value <= 30) {
                        intensita_odore = 1;
                      }

                      if (_value > 30 && _value <= 60) {
                        intensita_odore = 2;
                      }

                      if (_value >= 60) {
                        intensita_odore = 3;
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),
        validation: () {
          if (_value == 0) {
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
                      content: Text("Selezionare un'intensità di odore"),
                      actions: [okButton]);
                });
            return "error";
          } else {
            return null;
          }
        },
      ),
      CoolStep(
        title: 'Informazioni di base',
        subtitle:
            'Selezionare durata avvertimento odore per proseguire al prossimo step',
        content: Column(children: <Widget>[
          Row(
            //ROW 1
            children: [
              _buildSelector(context: context, name: 'Meno 5 minuti'),
            ],
          ),
          SizedBox(height: 20),
          Row(
            //ROW 2
            children: [
              _buildSelector(
                context: context,
                name: 'Più di un\'ora',
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            //ROW 3
            children: [
              _buildSelector(
                context: context,
                name: 'Più di 6 ore',
              )
            ],
          ),
        ]),
        validation: () {
          return null;
        },
      ),
      CoolStep(
        title: 'Informazioni di base',
        subtitle:
            'Selezionare la gravità e il tipo di odore percepito per terminare il questionario',
        content: Column(children: <Widget>[
          Row(
            //ROW 3
            children: [
              Text("Seleziona la gravità dell\'odore percepito:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          SizedBox(height: 20),
          Row(
            //ROW 3
            children: [
              _buildSelectorOffensivita(
                context: context,
                name: 'Non gradevole',
              )
            ],
          ),
          SizedBox(height: 20),
          Row(
            //ROW 3
            children: [
              _buildSelectorOffensivita(
                context: context,
                name: 'Nauseante',
              )
            ],
          ),
          SizedBox(height: 50),
          Row(
            //ROW 3
            children: [
              Text("Seleziona il tipo di odore percepito:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))
            ],
          ),
          Row(
            //ROW 1
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 1),
                child: Container(
                    // width: 310,
                    padding: EdgeInsets.symmetric(vertical: 5),
                    child: DropdownButton<String>(
                      value: dropdownValue,
                      alignment: Alignment.center,
                      icon: const Icon(Icons.arrow_downward),
                      elevation: 16,
                      style: const TextStyle(color: Colors.blue),
                      underline: Container(
                        height: 2,
                        color: Colors.blue,
                        alignment: Alignment.topRight,
                      ),
                      //isExpanded: true,
                      onChanged: (String? newValue) {
                        setState(() {
                          dropdownValue = newValue!;
                          if (dropdownValue == "Rifiuti") {
                            tipo_odore = 0;
                          }
                          if (dropdownValue == "Fognatura") {
                            tipo_odore = 1;
                          }
                          if (dropdownValue == "Plastica") {
                            tipo_odore = 2;
                          }
                          if (dropdownValue == "Traffico veicolare") {
                            tipo_odore = 3;
                          }
                          if (dropdownValue == "Bruciato") {
                            tipo_odore = 4;
                          }
                          if (dropdownValue == "Letame") {
                            tipo_odore = 5;
                          }
                          if (dropdownValue == "Chimico") {
                            tipo_odore = 6;
                          }
                          if (dropdownValue == "Altro odore") {
                            tipo_odore = 7;
                          }
                        });
                      },
                      items: <String>[
                        'Rifiuti',
                        'Fognatura',
                        'Plastica',
                        'Traffico veicolare',
                        'Bruciato',
                        'Letame',
                        'Chimico',
                        'Altro odore'
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                            value: value,
                            child: Container(
                                child: Text(value,
                                    style: TextStyle(fontSize: 16))));
                      }).toList(),
                    )),
              )
            ],
          ),
          SizedBox(height: 20),
        ]),
        validation: () {
          return null;
        },
      ),
    ];

    final stepper = CoolStepper(
      showErrorSnackbar: false,
      onCompleted: () {
        Map<String, dynamic> responseJson = json.decode(widget.jsonData);
        lat = responseJson['latitude'];
        lon = responseJson['longitude'];
        date = responseJson['datetime'];
        address = responseJson['address'];
        if (responseJson['user_type'] == "") {
          user_type = 0;
        } else {
          user_type = responseJson['user_type'];
        }
        if (responseJson['user_id'] == "") {
          user_id = 0;
        } else {
          user_id = responseJson['user_id'];
        }

        final jsonToServer = {
          "latitude": lat,
          "longitude": lon,
          "datetime": date,
          "address": address,
          "user_type": user_type,
          "user_id": user_id,
          "intensita": intensita_odore,
          "durata": durata_evento,
          "offensivita": offensivita,
          "tipo_odore": tipo_odore,
          "check_sending_report": check_sending_report,
          'id_app': id_app
        };
        //makePostRequest(date, jsonEncode(jsonToServer));
        print("jsonToServer survey: " + jsonEncode(jsonToServer));
        print("prima di sending survey");
        print("check survey: " + check_sending_report.toString());
        print("IDAPP survey: " + id_app.toString());
        print("datetime_read survey: " + datetime_read.toString());
        if (check_sending_report == 0 && id_app == 0) {
          makePostRequest(date, jsonEncode(jsonToServer));
        } else if (check_sending_report == 1 && id_app > 0) {
          if((datetime_read == "")){
            makePostRequest(date, jsonEncode(jsonToServer));
          }else{
            saveDatetime(datetime_read, check_sending_report, jsonToServer);
          }
        } else if (check_sending_report == 1 && id_app == 0) {
          saveDatetime(datetime_read, check_sending_report, jsonToServer);
        }
      },
      steps: steps,
      config: CoolStepperConfig(
          backText: 'INDIETRO',
          iconColor: Colors.blue,
          titleTextStyle: TextStyle(color: Colors.blue)),
    );

    if (user_id != 0) {
      return WillPopScope(
          onWillPop: () async => true,
          child: Scaffold(
              appBar: AppBar(
                  title:
                      Text(widget.title, style: TextStyle(color: Colors.black)),
                  backgroundColor: Colors.orange.shade200,
                  automaticallyImplyLeading:
                      false //inibisco la possibilità di tornare indietro scorrendo o cliccando sul pulsante freccia posto in alto a sx della schermata
                  ),
              bottomNavigationBar: BottomNavigationBar(
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Dashboard',
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
              body: Container(
                child: stepper,
              )));
    } else {
      return WillPopScope(
          onWillPop: () async => true,
          child: Scaffold(
              appBar: AppBar(
                  title:
                      Text(widget.title, style: TextStyle(color: Colors.black)),
                  backgroundColor: Colors.orange.shade200,
                  actions: <Widget>[
                    IconButton(
                        icon: Icon(Icons.delete_forever),
                        onPressed: _goToSettingPage),
                    IconButton(icon: Icon(Icons.logout), onPressed: _logout)
                  ],
                  iconTheme:
                      IconThemeData(color: Colors.black //change your color here
                          ),
                  automaticallyImplyLeading:
                      false //inibisco la possibilità di tornare indietro scorrendo o cliccando sul pulsante freccia posto in alto a sx della schermata
                  ),
              bottomNavigationBar: BottomNavigationBar(
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Dashboard',
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
              body: Container(
                child: stepper,
              )));
    }
  }

  Widget _buildTextField({
    String? labelText,
    FormFieldValidator<String>? validator,
    TextEditingController? controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: labelText,
        ),
        validator: validator,
        controller: controller,
      ),
    );
  }

  Widget _buildSelector({BuildContext? context, required String name}) {
    final isActive = name == selectedRole;

    return Expanded(
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context!).primaryColor : null,
          border: Border.all(
            width: 0,
          ),
          borderRadius: BorderRadius.circular(200.0),
        ),
        child: RadioListTile(
          value: name,
          activeColor: Colors.white,
          groupValue: selectedRole,
          onChanged: (String? v) {
            setState(() {
              selectedRole = v;

              if (v == "Meno 5 minuti") {
                durata_evento = 1;
              }

              if (v == "Più di un'ora") {
                durata_evento = 2;
              }

              if (v == "Più di 6 ore") {
                durata_evento = 3;
              }

              if (v == "Non gradevole") {
                offensivita = 1;
              }

              if (v == "Nauseante") {
                offensivita = 2;
              }
            });
          },
          title: Text(
            name,
            style: TextStyle(
              color: isActive ? Colors.white : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorOffensivita(
      {BuildContext? context, required String name}) {
    final isActive = name == selectedRole2;

    return Expanded(
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context!).primaryColor : null,
          border: Border.all(
            width: 0,
          ),
          borderRadius: BorderRadius.circular(200.0),
        ),
        child: RadioListTile(
          value: name,
          activeColor: Colors.white,
          groupValue: selectedRole2,
          onChanged: (String? v) {
            setState(() {
              selectedRole2 = v;

              if (v == "Non gradevole") {
                offensivita = 1;
              }

              if (v == "Nauseante") {
                offensivita = 2;
              }
            });
          },
          title: Text(
            name,
            style: TextStyle(
              color: isActive ? Colors.white : null,
            ),
          ),
        ),
      ),
    );
  }
}
