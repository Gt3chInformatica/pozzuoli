// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:convert';
//import 'dart:html';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'HistoricalReports.dart';
import 'HistoricalReportsList.dart';
import 'HomeAfterLogin.dart';
import 'Login.dart';
import 'StartApp.dart';
import 'sql_helper.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_static_maps_controller/google_static_maps_controller.dart'
as static_map;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:async';
import 'Survey.dart';
import 'package:location/location.dart' as loc;
import 'package:path/path.dart' as pathp;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:flutter/widgets.dart';

void main() => runApp(MyAppMap(data: Data(user_id: 0, cognome_nome: "", tokenSend: "")));

class MyAppMap extends StatelessWidget {
  final Data data;
  MyAppMap({required this.data});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false, home: MyStaticMap(data: data, value: this.data.user_id)
      // home: MyStaticMap(value: User(userID: 0)),
    );
  }
}

class MyStaticMap extends StatefulWidget {
  int value;
  Data data;

  MyStaticMap({Key? key, required this.data, required this.value})
      : super(key: key);
  /*final User value;
  var pippo = User(userID: 0);

  MyStaticMap({Key? key, required this.value}) : super(key: key); */

  @override
  _MyStaticMapState createState() => _MyStaticMapState();
}

class _MyStaticMapState extends State<MyStaticMap> {
  double lat = 0.0;
  double lon = 0.0;
  String datetime = "";
  String? address = "";
  int check_sending_report = 0;
  int id = 0;
  int? user_id;
  int id_app = 0;
  // int user_id = 0; //0 è utente guest

  int user_type = 0;

  String datetime_read = "";

  //Se questi dati sono = 0, vuol dire che il questionario non è stato compilato
  int intensita_odore = 0, durata = 0, offensivita = 0, tipo_odore = 0;

  LatLng? _center;
  geo.Position? currentLocation;

  String api_server_connection = "http://192.168.1.95:8081/"; //locale
  String api_server_connection2 = "http://95.110.130.12:8080/olysislogin/"; //server

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

  @override
  void initState() {

    String jwtToken = widget.data.tokenSend.toString();
    String token = jwtToken;
    super.initState();
    _refreshJournals();
    setState(() {
      if (widget.value == "" || widget.value == null || widget.value == 0) {
        user_id = 0;
      } else {
        user_id = widget.value;
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    print("user_id _onItemTapped in sendingReport: " + user_id.toString());
    print("widget.value _onItemTapped in sendingReport: " +
        widget.value.toString());

    if (user_id != 0 && _selectedIndex == 0) {
      Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
          builder: (context) =>
              HomeAfterLogin(data: Data(user_id: widget.data.user_id, cognome_nome: widget.data.cognome_nome, tokenSend: widget.data.tokenSend.toString()))));
    } else if (user_id == 0 && _selectedIndex == 0) {
      Navigator.of(context, rootNavigator: true)
          .push(MaterialPageRoute(builder: (_) => StartApp()));
    }

    if (_selectedIndex != 0) {
      Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
          builder: (context) => HistoricalReportsList(data: widget.data, user_id: widget.value)));
    }
  }

  Future<String> getLocation() async {
    try {
      Object checkPermission = await _determinePosition();
      String address = "";
      if (checkPermission == "permissionOk") {
        geo.Position position = await geo.Geolocator.getCurrentPosition(
            desiredAccuracy: geo.LocationAccuracy.high);
        address = await GetAddressFromLatLong(position) as String;
        lat = position.latitude;
        lon = position.longitude;
        setState(() {
          // lat = position.latitude;
          // lon = position.longitude;
        });
      }
      return address;
    } catch (e) {
      await Future.delayed(Duration(milliseconds: 60000));
      try {
        Object checkPermission = await _determinePosition();
        String address = "";
        if (checkPermission == "permissionOk") {
          geo.Position position = await geo.Geolocator.getCurrentPosition(
              desiredAccuracy: geo.LocationAccuracy.high);
          address = await GetAddressFromLatLong(position) as String;
          lat = position.latitude;
          lon = position.longitude;
          setState(() {
            // lat = position.latitude;
            // lon = position.longitude;
          });
        }
        return address;
      } catch (error) {
        return "errorr";
      }

      //print("erroreeeee: "+e.toString());
      return "null";
    }
  }

  Future<String> GetAddressFromLatLong(geo.Position position) async {
    List<Placemark> placemarks =
    await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark place = placemarks[0];
    var address =
        "${place.street} ${place.locality} ${place.postalCode} ${place.country}";
    setState(() {});
    return address;
  }

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<Object> _determinePosition() async {
    bool serviceEnabled;
    geo.LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Widget okButton = TextButton(
        child: Text("OK"),
        onPressed: () {
          if (user_id == 0) {
            Navigator.of(context, rootNavigator: true)
                .push(MaterialPageRoute(builder: (_) => StartApp()));
          } else {
            Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
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
                    'I servizi di localizzazione sono disabilitati. Attivare GPS.'),
                actions: [okButton]);
          });
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) {
        Widget okButton = TextButton(
          child: Text("OK"),
          onPressed: () {
            if (user_id == 0) {
              Navigator.of(context, rootNavigator: true)
                  .push(MaterialPageRoute(builder: (_) => StartApp()));
            } else {
              Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
                  builder: (_) => HomeAfterLogin(
                      data: widget.data)));
            }
          },
        );
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                  title: Text("Attenzione!"),
                  content: Text(
                      'Le autorizzazioni di posizione sono negate. Consentire le autorizzazioni di posizione.'),
                  actions: [okButton]);
            });
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == geo.LocationPermission.deniedForever) {
      Widget okButton = TextButton(
        child: Text("OK"),
        onPressed: () {
          if (user_id == 0) {
            Navigator.of(context, rootNavigator: true)
                .push(MaterialPageRoute(builder: (_) => StartApp()));
          } else {
            Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
                builder: (_) => HomeAfterLogin(
                    data: widget.data)));
          }
        },
      );
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
                title: Text("Attenzione!"),
                content: Text(
                    'Le autorizzazioni alla posizione sono negate in modo permanente, non possiamo richiedere autorizzazioni.'),
                actions: [okButton]);
          });
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    String permissionOk = "";

    if (permission == geo.LocationPermission.whileInUse) {
      permissionOk = "permissionOk";
      //return await Geolocator.getCurrentPosition();
    }

    if (permission == geo.LocationPermission.always) {
      permissionOk = "permissionOk";
      //return await Geolocator.getCurrentPosition();
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    //getLocation();
    return permissionOk;
    //return await Geolocator.getCurrentPosition();
  }

  List<Map<String, dynamic>> _journals = [];

  void _refreshJournals() async {
    final db = await SQLHelper.db();
    SQLHelper.createTables(db);
    print("in refreshjourna da init sending report");

    //Recupero i dati da SQLita
    final data = await SQLHelper.getItems();
    print("sono data in refresh sending report: "+data.toString());
    /*final db = await SQLHelper.db();
     SQLHelper.onUpgrade(db);*/

    //SQLHelper.deleteItem2();
    //SQLHelper.deleteItem(51);
   // SQLHelper.update('18-03-2022 9:31:11');

    //Se ci sono i dati in SQLite
    if (data.isNotEmpty) {
      print("data sqlite: " + data.toString());
      setState(() {
        _journals = data;
        // _isLoading = false;
      });
      print("sono user id in sending report: "+user_id.toString());

      //Se sono un utente loggato:
      //if(user_id != 0){
        //Recupero l'ultimo id della segnalazione inviata sulla base dell'userID in questione
        int last_id = await getLastId(user_id);
        id_app = last_id;

          print("sono last_id in refreshJournals sending report: " + last_id.toString());

          //Recupero nome e cognome dell'utente loggato
          cognome_nome = await getUserData(user_id);
          print("sono cognome_nome in refreshJournals sending report: " + cognome_nome.toString());

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
                print("ooh datetime_read: " + datetime_read);
              }//end for

              //Incremento la variabile id_app a seconda del fatto che è stata inviata 1 o n segnalazioni al server
              if (checkSendingReportRead == 1) {
                check_sending_report = checkSendingReportRead!;
              }else{
                check_sending_report = 0;
              }
            }//end if (user_id == element['userID'])
          }//end for (Map<String, dynamic> element in _journals)

          if(id_app != 0 && datetime_read == ""){
            //recupero datetime dal db del server
            datetime_read = await getDatetime(user_id);
            check_sending_report = 1;
          }
        //Se sono utente loggato
      /*}else{
        id_app = 0;
        check_sending_report = 0;
      }*/

      //Se non ci sono dati in SQLite
    } else {
      if(id_app != 0){
        check_sending_report = 1;
      }else{
        check_sending_report = 0;
        id_app = 0;
      }
    }
  }

  Future<int> getLastId(user_id) async {
    //Richiesta get al server
    final response = await http.get(
        Uri.parse(
            api_server_connection2+'pozzuoli/getLastId?userid=${user_id}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization':  widget.data.tokenSend.toString(),
          'jwt': widget.data.tokenSend.toString()
        });

    int id_app = 0;
    if (response.statusCode == 200) {
      id_app = int.parse(response.body);
    }
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
        Uri.parse(api_server_connection2+'user/getName?userid=${user_id}'),
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

    print("flag_check_sending_report: " + check_sending_report.toString());
    print("complete_date_now: " + complete_datetime_now);
    print("complete_date_written: " + datetime);

    print("hh_written: " + hh_written.toString());
    print("hh_now: " + hh_now.toString());

    print("check_sending_report: " + check_sending_report.toString());

    //Eseguo il controllo sulle fasce orarie
    //Se il flag check_sending_report è 1 e la data scritta nel file e quella attuale sono uguali:
    if ((check_sending_report == 1)) {
      //Dichiaro la variabile per l'orario consentito
      String allowed_time = "";

      print("date_now: " + date_now.toString());
      print("complete_date_written: " + complete_date_written.toString());
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
                        builder: (_) => HomeAfterLogin(
                            data: widget.data)));
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
            (hh_now >= 21 && hh_now < 03) &&
            (complete_date_written == date_now)) {
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
                        builder: (_) => HomeAfterLogin(
                            data: widget.data)));
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
            (hh_now >= 03 && hh_now < 09) &&
            (complete_date_written == date_now)) {
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
                        builder: (_) => HomeAfterLogin(
                            data: widget.data)));
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

  bool _isLoading = false;
  // This function will be triggered when the button is pressed
  void _startLoading() async {
    setState(() {
      _isLoading = true;
    });
  }

  //Questa funzione viene richiamata quando si vuole inviare una segnalazione
  void makePostRequest(datetime, jsonData) {
    _startLoading();
    print("sono user id in makepostrequest: "+user_id.toString());
    //Mettere controllo su obbligo del questionario se utente è loggato
    if (user_id != 0) {
      Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
          builder: (context) => Survey(
              title: 'Questionario',
              jsonData: jsonData,
              check_sending_report: check_sending_report,
              user_id: widget.data.user_id,
              data: widget.data
          )));
    } else {
      widget.data.tokenSend = "Bearer eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJndWVzdEBzZWduYWxhemlvbmkuaXQiLCJleHAiOjE3MDM5NzcyMDAsImlhdCI6MTY0NTcwNjY4NSwiYXV0aG9yaXRpZXMiOlsiUk9MRV9udWxsIl19.Vu5peQ01Ja2QYuewjf_FssdX4aYN3N0oaH78Xu_2yGqJLcjhiBEHkcBtvRvgAVGSg-Hs1vDJrtj0wDOqEJ67kA";
      //Se l'utente decide di compilare il questionario, cliccando su SI viene rimandato alla schermata del wizard
      Widget siButton = TextButton(
        child: Text("SI"),
        onPressed: () {
          Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
              builder: (context) => Survey(
                  title: 'Questionario',
                  jsonData: jsonData,
                  check_sending_report: check_sending_report,
                  user_id: user_id!,
                  data: widget.data
              )));
        },
      );

      //Se l'utente decide di non voler compilare il questionario, viene richiamata la funzione makePostRequestNoSurvey(datetime, jsonData)
      Widget noButton = TextButton(
        child: Text("NO"),
        onPressed: () {
          makePostRequestNoSurvey(datetime, jsonData);
          Navigator.of(context, rootNavigator: true).pop();
        },
      );

      //Popup di scelta per l'utente per compilazione questionario
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
                title: Text("Attenzione!"),
                content: Text(
                    "Desideri compilare il questionario aggiungendo ulteriori osservazioni circa l'evento odorigeno?"),
                actions: [siButton, noButton]);
          });
    }
  }

  //Questa funzione viene richiamata quando si vuole inviare una segnalazione senza compilare il questionario
  Future<void> makePostRequestNoSurvey(datetime, jsonData) async {
    if(widget.data.tokenSend.toString() == "")
      widget.data.tokenSend = "Bearer eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJndWVzdEBzZWduYWxhemlvbmkuaXQiLCJleHAiOjE3MDM5NzcyMDAsImlhdCI6MTY0NTcwNjY4NSwiYXV0aG9yaXRpZXMiOlsiUk9MRV9udWxsIl19.Vu5peQ01Ja2QYuewjf_FssdX4aYN3N0oaH78Xu_2yGqJLcjhiBEHkcBtvRvgAVGSg-Hs1vDJrtj0wDOqEJ67kA";

    final headers = {
      "Content-type": "application/json",
      "Authorization":  widget.data.tokenSend.toString()
    };
    try {
      //Decodifico il json ricevuto in input
      Map<String, dynamic> responseJson = json.decode(jsonData);

      //Richiesta post al server
      final response = await http.post(
          Uri.parse(
              Uri.encodeFull(api_server_connection2+'pozzuoli/insert')),
          headers: headers,
          body: jsonEncode(responseJson));
      print('Status code: ${response.statusCode}');

      //Se l'invio al server è andato a buon fine
      if (response.statusCode == 200) {
        setState(() async {
          check_sending_report = 1;
          _addItem();
          //chiamare la write?
          //  writeContent(datetime);
          //saveDatetime(datetime, jsonData);
          print("sent");

          //Compare il popup di segnalazione inviata con successo
          Widget okButton = TextButton(
            child: Text("OK"),
            onPressed: () {
              if (user_id == 0) {
                Navigator.of(context, rootNavigator: true)
                    .push(MaterialPageRoute(builder: (_) => StartApp()));
              } else {
                Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(
                        builder: (_) => HomeAfterLogin(
                            data: widget.data)));
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
      } else {
        print("error, not sent");

        //Compare il popup di segnalazione inviata con successo
        Widget okButton = TextButton(
          child: Text("OK"),
          onPressed: () {
            if (user_id == 0) {
              Navigator.of(context, rootNavigator: true)
                  .push(MaterialPageRoute(builder: (_) => StartApp()));
            } else {
              Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
                  builder: (_) => HomeAfterLogin(
                      data: widget.data)));
            }
          },
        );
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                  title: Text("Attenzione!"),
                  content: Text(
                      "Errore nell'inviare la segnalazione, problemi di connessione al server. Contattare l'amministratore del sistema."),
                  actions: [okButton]);
            });
      }
    } catch (e) {
      print("catch " + e.toString());
      return null;
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
              Uri.encodeFull(api_server_connection2+'user/delete2')),
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

    if(user_id! != 0){
      return WillPopScope(
          onWillPop: () async => true,
          child: Scaffold(
              appBar: AppBar(
                title: Text('Invia segnalazione',
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
                    color: Colors.black //change your color here
                ),
              ),
              bottomNavigationBar: BottomNavigationBar(
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Dashoboard',
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
              body: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
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
                          //label: "A",
                          locations: [
                            /// Provide locations for markers of a defined style
                            //static_map.Location(lat, lon),
                              static_map.Location(lat, lon)
                          ],
                        ),
                      ],
                    ),
                  ),
                  /*Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: Text(widget.value.toString())
                ),*/
                  Padding(
                      padding: const EdgeInsets.only(
                          left: 0, right: 0, top: 0, bottom: 0),
                      child: FutureBuilder<String>(
                          future: getLocation(), //getLocation(),
                          builder: (BuildContext context,
                              AsyncSnapshot<String> snapshot) {
                            List<Widget> children;
                            if (snapshot.hasData) {
                              children = <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 15.0,
                                      right: 15.0,
                                      top: 15,
                                      bottom: 0),
                                  child: Text(setTime() + ' ${snapshot.data}'),
                                ),
                                Padding(
                                    padding: const EdgeInsets.only(
                                        left: 15.0,
                                        right: 15.0,
                                        top: 100,
                                        bottom: 0),
                                    child: SizedBox(
                                      width: 200,
                                      height: 50,
                                      child: RaisedButton.icon(
                                        shape: RoundedRectangleBorder(
                                          // set the value to a very big number like 100, 1000...
                                            borderRadius: BorderRadius.circular(100)
                                        ),
                                        color: Colors.blue,
                                        icon: _isLoading
                                            ? CircularProgressIndicator()
                                            : Icon(Icons.send, color: Colors.white),
                                        label: Text(
                                          _isLoading ? 'Caricamento...' : 'Invia',
                                          style: TextStyle(fontSize: 15, color: Colors.white),
                                        ),
                                        onPressed: () async {
                                          // print(widget.pippo.toString());
                                          _isLoading ? null : _startLoading;
                                          datetime = setTime();
                                          address = snapshot.data;
                                          // check_sending_report = 1;

                                          final jsonData = {
                                            "latitude": lat,
                                            "longitude": lon,
                                            "datetime": datetime,
                                            "address": address,
                                            "user_type": user_type,
                                            "user_id": user_id,
                                            "intensita": intensita_odore,
                                            "durata": durata,
                                            "offensivita": offensivita,
                                            "tipo_odore": tipo_odore,
                                            "check_sending_report":
                                            check_sending_report,
                                            'id_app': id_app
                                          };
                                          print("json: " + jsonEncode(jsonData));

                                          print("prima di sending");
                                          print("check: " +
                                              check_sending_report.toString());
                                          print("IDAPP: " + id_app.toString());
                                          print("datetime_read: " +
                                              datetime_read.toString());

                                          /*if(datetime_read == ""){
                                            datetime_read = datetime;
                                          }*/

                                          if(check_sending_report == 0 &&
                                              id_app == 0){
                                            makePostRequest(
                                                datetime, jsonEncode(jsonData));
                                          }else if (check_sending_report == 1 &&
                                              id_app > 0) {
                                            saveDatetime(datetime_read,
                                                check_sending_report, jsonData);
                                            /*if((datetime_read == "")){
                                              makePostRequest(
                                                  datetime, jsonEncode(jsonData));
                                            }else{
                                              saveDatetime(datetime_read,
                                                  check_sending_report, jsonData);
                                            }*/
                                          }else if(check_sending_report == 1 &&
                                              id_app == 0){
                                            saveDatetime(datetime_read,
                                                check_sending_report, jsonData);
                                          }
                                        },
                                      ),
                                    ))
                              ];
                            } else if (snapshot.hasError) {
                              children = <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Text(
                                      'Indirizzo non trovato: ${snapshot.error}'),
                                )
                              ];
                            } else {
                              children = const <Widget>[
                                SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: CircularProgressIndicator(),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(top: 16),
                                  child: Text('Caricamento indirizzo...'),
                                )
                              ];
                            }
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: children,
                              ),
                            );
                          })),
                ],
              )));
    }else{
      return WillPopScope(
          onWillPop: () async => true,
          child: Scaffold(
              appBar: AppBar(
                title: Text('Invia segnalazione',
                    style: TextStyle(color: Colors.black)),
                backgroundColor: Colors.orange.shade200,
                iconTheme: IconThemeData(
                    color: Colors.black //change your color here
                ),
              ),
              bottomNavigationBar: BottomNavigationBar(
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Dashoboard',
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
              body: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
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
                            static_map.Location(lat, lon)
                          ],
                        ),
                      ],
                    ),
                  ),
                  /*Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: Text(widget.value.toString())
                ),*/
                  Padding(
                      padding: const EdgeInsets.only(
                          left: 0, right: 0, top: 0, bottom: 0),
                      child: FutureBuilder<String>(
                          future: getLocation(), //getLocation(),
                          builder: (BuildContext context,
                              AsyncSnapshot<String> snapshot) {
                            List<Widget> children;
                            if (snapshot.hasData) {
                              children = <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 15.0,
                                      right: 15.0,
                                      top: 15,
                                      bottom: 0),
                                  child: Text(setTime() + ' ${snapshot.data}'),
                                ),
                                Padding(
                                    padding: const EdgeInsets.only(
                                        left: 15.0,
                                        right: 15.0,
                                        top: 100,
                                        bottom: 0),
                                    child: SizedBox(
                                      width: 250,
                                      height: 50,
                                      child: RaisedButton.icon(
                                        color: Colors.blue,
                                        shape: RoundedRectangleBorder(
                                          // set the value to a very big number like 100, 1000...
                                            borderRadius: BorderRadius.circular(100)
                                        ),
                                        icon: _isLoading
                                            ? CircularProgressIndicator()
                                            : Icon(Icons.send, color: Colors.white),
                                        label: Text(
                                          _isLoading ? 'Caricamento...' : 'Invia',
                                          style: TextStyle(fontSize: 15, color: Colors.white),
                                        ),
                                        onPressed: () async {
                                          // print(widget.pippo.toString());
                                          _isLoading ? null : _startLoading;
                                          datetime = setTime();
                                          address = snapshot.data;
                                          // check_sending_report = 1;

                                          final jsonData = {
                                            "latitude": lat,
                                            "longitude": lon,
                                            "datetime": datetime,
                                            "address": address,
                                            "user_type": user_type,
                                            "user_id": user_id,
                                            "intensita": intensita_odore,
                                            "durata": durata,
                                            "offensivita": offensivita,
                                            "tipo_odore": tipo_odore,
                                            "check_sending_report":
                                            check_sending_report,
                                            'id_app': id_app
                                          };
                                          print("json: " + jsonEncode(jsonData));

                                          print("prima di sending");
                                          print("check: " +
                                              check_sending_report.toString());
                                          print("IDAPP: " + id_app.toString());
                                          print("datetime_read: " +
                                              datetime_read.toString());

                                          if (check_sending_report == 0 &&
                                              id_app == 0) {
                                            makePostRequest(
                                                datetime, jsonEncode(jsonData));
                                          }else if(check_sending_report == 0 &&
                                              id_app > 0){
                                            makePostRequest(
                                                datetime, jsonEncode(jsonData));
                                          }else if (check_sending_report == 1 &&
                                              id_app != 0) {
                                            saveDatetime(datetime_read,
                                                check_sending_report, jsonData);
                                          }else if(check_sending_report == 1 &&
                                              id_app == 0){
                                            saveDatetime(datetime_read,
                                                check_sending_report, jsonData);
                                          }
                                        },
                                      ),
                                    ))
                              ];
                            } else if (snapshot.hasError) {
                              children = <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Text(
                                      'Indirizzo non trovato: ${snapshot.error}'),
                                )
                              ];
                            } else {
                              children = const <Widget>[
                                SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: CircularProgressIndicator(),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(top: 16),
                                  child: Text('Caricamento indirizzo...'),
                                )
                              ];
                            }
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: children,
                              ),
                            );
                          })),
                ],
              )));
    }


  }

  // Insert a new journal to the database

  Future<void> _addItem() async {
    final db = await SQLHelper.db();
    //SQLHelper.createTables(db);
    await SQLHelper.createItem(
        datetime,
        address!,
        lat,
        lon,
        check_sending_report,
        user_id!,
        intensita_odore,
        durata,
        offensivita,
        tipo_odore,
        id_app);
    _refreshJournals();
  }
}
