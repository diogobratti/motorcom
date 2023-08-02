import 'dart:io';
import 'dart:convert';
import 'package:uuid/uuid.dart';

class Communicating {
  static final myUID = const Uuid().v1();
  void testUdp(Function(String) messageReceived) async {
    var destinationAddress = InternetAddress("255.255.255.255");

    RawDatagramSocket.bind(InternetAddress.anyIPv4, 8889)
        .then((RawDatagramSocket udpSocket) {
      udpSocket.broadcastEnabled = true;
      udpSocket.listen((e) {
        Datagram? dg = udpSocket.receive();
        if (dg != null) {
          print("received ${dg.data}");
          messageReceived("received ${dg.data}");
        }
      });
      List<int> data = utf8.encode('TESTddd');
      udpSocket.send(data, destinationAddress, 8889);
    });
  }

  static void sendMessage(dynamic senderMessage) async {
    var destinationAddress = InternetAddress("255.255.255.255");
    int destinationPort = 8889;
    RawDatagramSocket.bind(InternetAddress.anyIPv4, destinationPort)
        .then((RawDatagramSocket udpSocket) {
      udpSocket.broadcastEnabled = true;
      var senderObject = {'sender': myUID, 'message': senderMessage};
      List<int> senderData = utf8.encode(jsonEncode(senderObject));
      udpSocket.send(senderData, destinationAddress, destinationPort);
    });
  }

  static void listenForMessage(
      Function(dynamic responseMessage) listener) async {
    int port = 8889;
    RawDatagramSocket.bind(InternetAddress.anyIPv4, port)
        .then((RawDatagramSocket udpSocket) {
      udpSocket.broadcastEnabled = true;
      udpSocket.listen((e) async {
        Datagram? datagram = udpSocket.receive();
        if (datagram != null) {
          var objectResponse = jsonDecode(String.fromCharCodes(datagram.data));
          if (objectResponse['sender'] != myUID) {
            dynamic responseMessage = objectResponse['message'];
            print("received $responseMessage");
            await listener(responseMessage);
          }
        }
      });
    });
  }
}
