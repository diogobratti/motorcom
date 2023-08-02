import 'dart:io';
import 'dart:convert';
import 'package:uuid/uuid.dart';

class Communicating {
  static final myUID = const Uuid().v1();
  static const port = 8889;

  static void sendMessage(dynamic senderMessage) async {
    var destinationAddress = InternetAddress("255.255.255.255");
    RawDatagramSocket.bind(InternetAddress.anyIPv4, port)
        .then((RawDatagramSocket udpSocket) {
      udpSocket.broadcastEnabled = true;
      var senderObject = {'sender': myUID, 'message': senderMessage};
      List<int> senderData = utf8.encode(jsonEncode(senderObject));
      udpSocket.send(senderData, destinationAddress, port);
    });
  }

  static void listenForMessage(
      Function(dynamic responseMessage) listener) async {
    RawDatagramSocket.bind(InternetAddress.anyIPv4, port)
        .then((RawDatagramSocket udpSocket) {
      udpSocket.broadcastEnabled = true;
      udpSocket.listen((e) async {
        Datagram? datagram = udpSocket.receive();
        if (datagram != null) {
          var objectResponse = jsonDecode(String.fromCharCodes(datagram.data));
          if (objectResponse['sender'] != myUID) {
            dynamic responseMessage = objectResponse['message'];
            await listener(responseMessage);
          }
        }
      });
    });
  }
}
