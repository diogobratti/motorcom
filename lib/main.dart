import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:motorcom/signaling.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Motorcom',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Signaling signaling = Signaling();
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  String? roomId;
  TextEditingController textEditingController = TextEditingController(text: '');
  String scannedCandidates = "";
  List<dynamic> candidates = [];
  String udpMessage = "";
  final config = FlutterBackgroundAndroidConfig(
    notificationTitle: 'flutter_background example app',
    notificationText:
        'Background notification for keeping the example app running in the background',
    notificationIcon: AndroidResource(name: 'background_icon'),
    notificationImportance: AndroidNotificationImportance.Default,
    enableWifiLock: true,
    showBadge: true,
  );

  void addCandidate(RTCIceCandidate candidate) {
    print('Got candidate: ${candidate.toMap()}');
    candidates.add(candidate.toMap());
    setState(() {});
  }

  void calleeMessage(String message) {
    udpMessage = message;
    setState(() {});
  }

  @override
  void initState() {
    _localRenderer.initialize();
    _remoteRenderer.initialize();

    signaling.onAddRemoteStream = ((stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Motorcom"),
      ),
      body: Column(
        children: [
          SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ElevatedButton(
              onPressed: () {
                FlutterBackground.enableBackgroundExecution();
                signaling.openUserMedia(_localRenderer, _remoteRenderer);
              },
              child: Text("Open camera & microphone"),
            ),
            SizedBox(
              width: 8,
            ),
            ElevatedButton(
              onPressed: () async {
                await signaling.createRoom(_remoteRenderer, addCandidate);
                // textEditingController.text = roomId!;
                textEditingController.text = jsonEncode(candidates);
                // candidates = roomId!;
                setState(() {});
              },
              child: Text("Create room"),
            ),
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
              width: 8,
            ),
            ElevatedButton(
              onPressed: () {
                // Add roomId
                signaling.joinRoom(
                  textEditingController.text.trim(),
                  _remoteRenderer,
                );
              },
              child: Text("Join room"),
            ),
            SizedBox(
              width: 8,
            ),
            ElevatedButton(
              onPressed: () {
                FlutterBackground.disableBackgroundExecution();
                signaling.hangUp(_localRenderer);
              },
              child: Text("Hangup"),
            ),
            SizedBox(
              width: 8,
            ),
          ]),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {},
                child: Text("UDP $udpMessage"),
              )
            ],
          ),
          SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(child: RTCVideoView(_localRenderer, mirror: true)),
                  Expanded(child: RTCVideoView(_remoteRenderer)),
                ],
              ),
            ),
          ),
          SizedBox(height: 8)
        ],
      ),
    );
  }
}
