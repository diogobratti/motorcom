import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:motorcom/communicating.dart';

typedef StreamStateCallback = void Function(MediaStream stream);

class Signaling {
  Map<String, dynamic> configuration = {'iceServers': []};

  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  StreamStateCallback? onAddRemoteStream;

  bool keepSendingCallerCandidate = true;
  bool keepSendingCalleeCandidate = true;
  bool keepSendingOffer = true;
  bool keepSendingAnswer = true;
  static const sleepSeconds = 10;

  Future<void> createRoom(RTCVideoRenderer remoteRenderer) async {
    // debugPrint('Create PeerConnection with configuration: $configuration');

    peerConnection = await createPeerConnection(configuration);

    registerPeerConnectionListeners();

    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    // Code for collecting ICE candidates below

    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) async {
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
    // debugPrint('Created offer: $offer');

    Map<String, dynamic> roomWithOffer = {'offer': offer.toMap()};

    // Created a Room

    peerConnection?.onTrack = (RTCTrackEvent event) {
      // debugPrint('Got remote track: ${event.streams[0]}');

      event.streams[0].getTracks().forEach((track) {
        // debugPrint('Add a track to the remoteStream $track');
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

            // debugPrint("Someone tried to connect");
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

  Future<void> joinRoom(RTCVideoRenderer remoteVideo) async {
    // debugPrint('Create PeerConnection with configuration: $configuration');
    peerConnection = await createPeerConnection(configuration);

    registerPeerConnectionListeners();

    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    // Code for collecting ICE candidates below
    peerConnection!.onIceCandidate = (RTCIceCandidate? candidate) async {
      if (candidate == null) {
        // debugPrint('onIceCandidate: complete!');
        return;
      }
      while (keepSendingCalleeCandidate) {
        Communicating.sendMessage(
            {'type': 'calleeCandidates', 'data': candidate.toMap()});

        await Future.delayed(const Duration(seconds: sleepSeconds));
      }
    };
    // Code for collecting ICE candidate above

    peerConnection?.onTrack = (RTCTrackEvent event) {
      // debugPrint('Got remote track: ${event.streams[0]}');
      event.streams[0].getTracks().forEach((track) {
        // debugPrint('Add a track to the remoteStream: $track');
        remoteStream?.addTrack(track);
      });
    };

    Communicating.listenForMessage((responseMessage) async {
      var data = responseMessage['data'];
      switch (responseMessage['type']) {
        // Code for creating SDP answer below
        case 'offer':
          Communicating.sendMessage({'type': 'offerReceived', 'data': null});
          // debugPrint('Got offer $data');
          var offer = data['offer'];
          await peerConnection?.setRemoteDescription(
            RTCSessionDescription(offer['sdp'], offer['type']),
          );
          var answer = await peerConnection!.createAnswer();
          // debugPrint('Created Answer $answer');

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
    for (var track in tracks) {
      track.stop();
    }

    if (remoteStream != null) {
      remoteStream!.getTracks().forEach((track) => track.stop());
    }
    if (peerConnection != null) peerConnection!.close();

    localStream!.dispose();
    remoteStream?.dispose();
  }

  void registerPeerConnectionListeners() {
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      debugPrint('ICE gathering state changed: $state');
    };

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint('Connection state change: $state');
    };

    peerConnection?.onSignalingState = (RTCSignalingState state) {
      debugPrint('Signaling state change: $state');
    };

    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {
      debugPrint('ICE connection state change: $state');
      debugPrint('ICE ');
    };

    peerConnection?.onAddStream = (MediaStream stream) {
      onAddRemoteStream?.call(stream);
      remoteStream = stream;
    };

    peerConnection?.onRemoveStream = (MediaStream stream) {
      debugPrint('ICE ');
    };
    peerConnection?.onAddTrack = (MediaStream stream, MediaStreamTrack track) {
      debugPrint('ICE ');
    };
    peerConnection?.onRemoveTrack =
        (MediaStream stream, MediaStreamTrack track) {
      debugPrint('ICE ');
    };
    peerConnection?.onDataChannel = (RTCDataChannel channel) {
      debugPrint('ICE ');
    };
    peerConnection?.onRenegotiationNeeded = () {
      debugPrint('ICE ');
    };
  }
}
