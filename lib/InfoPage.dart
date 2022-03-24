import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class InfoPage extends StatefulWidget {
  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => true,
        child: Scaffold(
            appBar: AppBar(
              title:
                  Text("Informazioni", style: TextStyle(color: Colors.black)),
              backgroundColor: Colors.orange.shade200,
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
                          height: 100,
                          child: Image.asset('asset/images/logo_OLYSIS_trasp.png',
                              width: MediaQuery.of(context).size.width)),
                    ),
                  ),
                  Padding(
                      //padding: const EdgeInsets.only(left:15.0,right: 15.0,top:0,bottom: 0),
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: Text(
                          "Sistema integrato di monitoraggio e controllo dell’impatto olfattivo del territorio comunale di Pozzuoli, basato sul coinvolgimento partecipativo della popolazione.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20))),
                  SizedBox(height: 40),
                  Padding(
                    //padding: const EdgeInsets.only(left:15.0,right: 15.0,top:0,bottom: 0),
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: Text("Proprietà di:",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20))),
                  Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Container(
                      width: 200,
                      height: 100,
                      child: Image.asset('asset/images/LOGO_TA.png',
                          width: MediaQuery.of(context).size.width)),
                ),
                  SizedBox(height: 20),
                  Padding(
                      //padding: const EdgeInsets.only(left:15.0,right: 15.0,top:0,bottom: 0),
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: Text("Sviluppata da:",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20))),
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 0, left: 20, right: 20),
                    child: Center(
                      child: Container(
                          width: 200,
                          height: 100,
                          child: Image.asset(
                              'asset/images/logo_warmpiesoft_wps250.png',
                              width: MediaQuery.of(context).size.width)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Center(
                      child: Container(
                          child: Text(
                        "Sede legale e operativa: C.da Baione snc zona industriale - 70043 Monopoli (BA), ITALY \n Tel. (+39)0802256911 \n Fax (+39)0802256912 \n E-mail: info@warmpiesoft.com",
                        textAlign: TextAlign.center,
                      )),
                    ),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    //padding: const EdgeInsets.only(left:15.0,right: 15.0,top:0,bottom: 0),
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: Text("Sviluppata per il Comune di Pozzuoli:",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20))),
                  Padding(
                    padding:
                    const EdgeInsets.only(top: 0, left: 20, right: 20),
                    child: Center(
                      child: Container(
                          width: 200,
                          height: 100,
                          child: Image.asset(
                              'asset/images/Pozzuoli.png',
                              width: MediaQuery.of(context).size.width)),
                    ),
                  ),
                ],
              ),
            )));
  }
}
