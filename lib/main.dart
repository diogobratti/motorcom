import 'package:flutter/material.dart';
import 'package:motorcom/about_us.dart';
import 'package:motorcom/chat.dart';
import 'package:motorcom/help.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Motorcom',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('es'), // Spanish
        Locale('pt'), // Portuguese
      ],
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyMainfulWidget(),
    );
  }
}

class MyMainfulWidget extends StatefulWidget {
  const MyMainfulWidget({super.key});

  @override
  State<MyMainfulWidget> createState() => _MyMainfulWidgetState();
}

class _MyMainfulWidgetState extends State<MyMainfulWidget> {
  int _selectedIndex = 0;
  static const List<Widget> _widgetOptions = <Widget>[
    Chat(),
    Help(),
    AboutUs(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Motorcom"),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.call),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.help),
            label: 'Ajuda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Autores',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
