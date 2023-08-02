import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:motorcom/signaling.dart';
import 'package:motorcom/background.dart';

class Chat extends StatefulWidget {
  const Chat({Key? key}) : super(key: key);

  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  Signaling signaling = Signaling();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

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
      body: Column(
        children: [
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ElevatedButton(
              onPressed: () async {
                await Background.initialize(context);
                signaling.openUserMedia(_localRenderer, _remoteRenderer);
              },
              child: const Text("Abrir microfone"),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                await signaling.createRoom(_remoteRenderer);
                setState(() {});
              },
              child: const Text("Criar uma sala"),
            ),
          ]),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                signaling.joinRoom(_remoteRenderer);
              },
              child: const Text("Entrar na sala"),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                Background.finish();
                signaling.hangUp(_localRenderer);
              },
              child: const Text("Desligar"),
            ),
            const SizedBox(width: 8),
          ]),
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
          const SizedBox(height: 8)
        ],
      ),
    );
  }
}
