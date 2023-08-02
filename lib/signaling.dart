import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:motorcom/communicating.dart';

typedef void StreamStateCallback(MediaStream stream);

class Signaling {
  Map<String, dynamic> configuration = {'iceServers': []};

  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  String? roomId;
  String? currentRoomText;
  StreamStateCallback? onAddRemoteStream;

  List<dynamic> callerCandidates = [];
  List<dynamic> calleeCandidates = [];

  bool keepSendingCallerCandidate = true;
  bool keepSendingCalleeCandidate = true;
  bool keepSendingOffer = true;
  bool keepSendingAnswer = true;
  static const sleepSeconds = 30;

  Future<void> createRoom(RTCVideoRenderer remoteRenderer,
      Function(RTCIceCandidate) addMyCandidate) async {
    // print('Create PeerConnection with configuration: $configuration');

    peerConnection = await createPeerConnection(configuration);

    registerPeerConnectionListeners();

    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    // Code for collecting ICE candidates below

    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) async {
      callerCandidates.add(candidate.toMap());
      while (keepSendingCallerCandidate) {
        Communicating.sendMessage(
            {'type': 'callerCandidates', 'data': candidate.toMap()});
        await Future.delayed(const Duration(seconds: sleepSeconds));
      }
    };
    // Finish Code for collecting ICE candidate

    // Add code for creating a room
    RTCSessionDescription offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);
    // print('Created offer: $offer');

    Map<String, dynamic> roomWithOffer = {'offer': offer.toMap()};

    // Created a Room

    peerConnection?.onTrack = (RTCTrackEvent event) {
      // print('Got remote track: ${event.streams[0]}');

      event.streams[0].getTracks().forEach((track) {
        // print('Add a track to the remoteStream $track');
        remoteStream?.addTrack(track);
      });
    };

    Communicating.listenForMessage((responseMessage) async {
      var data = responseMessage['data'];
      switch (responseMessage['type']) {
        // Listening for remote session description below
        case 'offer':
          if (peerConnection?.getRemoteDescription() != null &&
              data['answer'] != null) {
            var answer = RTCSessionDescription(
              data['answer']['sdp'],
              data['answer']['type'],
            );

            // print("Someone tried to connect");
            await peerConnection?.setRemoteDescription(answer);

            Communicating.sendMessage({'type': 'answerReceived', 'data': null});
          }
          break;
        // Listening for remote session description above
        // Listen for remote Ice candidates below
        case 'calleeCandidates':
          peerConnection!.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
          Communicating.sendMessage(
              {'type': 'calleeCandidateReceived', 'data': null});
          break;
        // Listen for remote ICE candidates above

        case 'offerReceived':
          keepSendingOffer = false;
          break;
        case 'callerCandidateReceived':
          keepSendingCallerCandidate = false;
          break;
        default:
      }
    });

    while (keepSendingOffer) {
      Communicating.sendMessage({'type': 'offer', 'data': roomWithOffer});
      await Future.delayed(const Duration(seconds: sleepSeconds));
    }
  }

  Future<void> joinRoom(String roomId, RTCVideoRenderer remoteVideo) async {
    // print('Create PeerConnection with configuration: $configuration');
    peerConnection = await createPeerConnection(configuration);

    registerPeerConnectionListeners();

    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    // Code for collecting ICE candidates below
    peerConnection!.onIceCandidate = (RTCIceCandidate? candidate) async {
      if (candidate == null) {
        // print('onIceCandidate: complete!');
        return;
      }
      while (keepSendingCalleeCandidate) {
        Communicating.sendMessage(
            {'type': 'calleeCandidates', 'data': candidate.toMap()});

        await Future.delayed(const Duration(seconds: sleepSeconds));
      }
      calleeCandidates.add(candidate.toMap());
      // addMyCandidate(candidate.toMap());
    };
    // Code for collecting ICE candidate above

    peerConnection?.onTrack = (RTCTrackEvent event) {
      // print('Got remote track: ${event.streams[0]}');
      event.streams[0].getTracks().forEach((track) {
        // print('Add a track to the remoteStream: $track');
        remoteStream?.addTrack(track);
      });
    };

    Communicating.listenForMessage((responseMessage) async {
      var data = responseMessage['data'];
      switch (responseMessage['type']) {
        // Code for creating SDP answer below
        case 'offer':
          Communicating.sendMessage({'type': 'offerReceived', 'data': null});
          // print('Got offer $data');
          var offer = data['offer'];
          await peerConnection?.setRemoteDescription(
            RTCSessionDescription(offer['sdp'], offer['type']),
          );
          var answer = await peerConnection!.createAnswer();
          // print('Created Answer $answer');

          await peerConnection!.setLocalDescription(answer);

          Map<String, dynamic> roomWithAnswer = {
            'answer': {'type': answer.type, 'sdp': answer.sdp}
          };

          while (keepSendingAnswer) {
            Communicating.sendMessage(
                {'type': 'offer', 'data': roomWithAnswer});
            await Future.delayed(const Duration(seconds: sleepSeconds));
          }
          // Finished creating SDP answer
          break;
        case 'callerCandidates':
          peerConnection!.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
          Communicating.sendMessage(
              {'type': 'callerCandidateReceived', 'data': null});
          break;
        // Listen for remote Ice candidates below
        case 'answerReceived':
          keepSendingAnswer = false;
          break;
        case 'calleeCandidateReceived':
          keepSendingCalleeCandidate = false;
          break;
        default:
      }
    });
  }

  Future<void> openUserMedia(
    RTCVideoRenderer localVideo,
    RTCVideoRenderer remoteVideo,
  ) async {
    var stream = await navigator.mediaDevices
        .getUserMedia({'video': true, 'audio': false});

    localVideo.srcObject = stream;
    localStream = stream;

    remoteVideo.srcObject = await createLocalMediaStream('key');
  }

  Future<void> hangUp(RTCVideoRenderer localVideo) async {
    List<MediaStreamTrack> tracks = localVideo.srcObject!.getTracks();
    tracks.forEach((track) {
      track.stop();
    });

    if (remoteStream != null) {
      remoteStream!.getTracks().forEach((track) => track.stop());
    }
    if (peerConnection != null) peerConnection!.close();

    localStream!.dispose();
    remoteStream?.dispose();
  }

  void registerPeerConnectionListeners() {
    // peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
    //   print('ICE gathering state changed: $state');
    // };

    // peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
    //   print('Connection state change: $state');
    //   //TODO: apagar isso abaixo
    //   print(json.encode(callerCandidates));
    //   print(json.encode(calleeCandidates));
    // };

    // peerConnection?.onSignalingState = (RTCSignalingState state) {
    //   print('Signaling state change: $state');
    // };

    // peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
    //   print('ICE connection state change: $state');
    // };

    peerConnection?.onAddStream = (MediaStream stream) {
      onAddRemoteStream?.call(stream);
      remoteStream = stream;
    };
  }
}
