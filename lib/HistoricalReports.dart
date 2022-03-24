import 'package:flutter/material.dart';
import 'SendingReport.dart';
import 'StartApp.dart';

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
      home: HistoricalReports(data: data ,user_id: 0),
    );
  }
}

class HistoricalReports extends StatefulWidget {
  Data data;
  int user_id = 0;
  HistoricalReports({Key? key, required this.data, required this.user_id}) : super(key: key);

  @override
  _HistoricalReportsState createState() => _HistoricalReportsState();
}

class _HistoricalReportsState extends State<HistoricalReports> {
  int _counter = 0; // Number of taps on + button.

  int _selectedIndex = 0;
  static const TextStyle optionStyle =
  TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static const List<Widget> _widgetOptions = <Widget>[
    Text(
      'Invia segnalazione',
      style: optionStyle,
    ),
    Text(
      'Storico segnalazioni',
      style: optionStyle,
    )
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if(_selectedIndex == 0){
      Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (context)=>MyStaticMap(data: widget.data, value: widget.user_id)));
    }
  }

  void _incrementCounter() { // Increase number of taps and update UI by calling setState().
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Page widget.
      appBar: AppBar( // Page app bar with title and back button if user can return to previous screen.
          title: Text(
              'Storico segnalazioni',
              style: TextStyle(color: Colors.black)
          ), // Text to display page title.
          backgroundColor: Colors.orange.shade200
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
      body: Center( // Widget to center child widget.
        child: Column( // Display children widgets in column.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text( // Static text.
              'You have pushed the button this many times:',
            ),
            Text( // Text with our taps number.
              '$_counter', // $ sign allows us to use variables inside a string.
              style: Theme.of(context).textTheme.headline4,// Style of the text, “Theme.of(context)” takes our context and allows us to access our global app theme.
            ),
          ],
        ),
      ),
      // Floating action button to increment _counter number.
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }

}