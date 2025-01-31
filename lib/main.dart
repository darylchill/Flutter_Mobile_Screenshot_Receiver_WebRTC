import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'listviewbuilder.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WebRTCScreenshotScreen(),
    );
  }
}

class WebRTCScreenshotScreen extends StatefulWidget {
  const WebRTCScreenshotScreen({super.key});

  @override
  State createState() => _WebRTCScreenshotScreenState();
}

class _WebRTCScreenshotScreenState extends State<WebRTCScreenshotScreen> {
  late IO.Socket socket;
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  Uint8List? _receivedImage;

  @override
  void initState() {
    super.initState();
    debugPrint("Initializing WebRTCScreenshotScreen");
    _initializeSocket();
  }

  void _initializeSocket() {
    debugPrint("Initializing socket connection");
    socket = IO.io('http://192.168.1.11:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.connect();
    socket.onConnect((_) => debugPrint('Connected to Signaling Server'));

    socket.on('offer', (data) async {
      debugPrint("Received offer");
      var offer = RTCSessionDescription(data['sdp'], data['type']);
      await _peerConnection!.setRemoteDescription(offer);

      var answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      socket.emit('answer', {'sdp': answer.sdp, 'type': answer.type});
    });

    socket.on('answer', (data) async {
      debugPrint("Received answer");
      var answer = RTCSessionDescription(data['sdp'], data['type']);
      await _peerConnection!.setRemoteDescription(answer);
    });

    socket.on('iceCandidate', (data) {
      debugPrint("Received ICE candidate");
      var candidate = RTCIceCandidate(
        data['candidate'],
        data['sdpMid'],
        data['sdpMLineIndex'],
      );
      _peerConnection!.addCandidate(candidate);
    });

    _createPeerConnection();
  }

  Future<void> _createPeerConnection() async {
    debugPrint("Creating PeerConnection");
    Map<String, dynamic> configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'}
      ]
    };

    _peerConnection = await createPeerConnection(configuration);

    _peerConnection!.onIceCandidate = (candidate) {
      debugPrint("Sending ICE candidate");
      socket.emit('iceCandidate', {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    _peerConnection!.onDataChannel = (channel) {
      debugPrint("Data channel received");
      _setupDataChannel(channel);
    };
  }

  void _setupDataChannel(RTCDataChannel channel) {
    debugPrint("Setting up data channel");
    _dataChannel = channel;
    _dataChannel!.onMessage = (RTCDataChannelMessage message) {
      setState(() {
        if (message.isBinary) {
          debugPrint("Received binary data (image)");
          _receivedImage = message.binary;
        } else {
          debugPrint("Received text message: ${message.text}");
        }
      });
    };
  }

  void _endCall() {
    debugPrint("Ending call");
    _dataChannel?.close();
    _peerConnection?.close();
    socket.disconnect();
    setState(() {
      debugPrint("Clearing messages");
    });
  }

  @override
  void dispose() {
    debugPrint("Disposing WebRTCChatScreen");
    _endCall();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("WebRTC Desktop Monitor")),
      body: _receivedImage == null
          ? Center(child: Text("No Image found"),)
          :ListViewBuilder(receivedImage: _receivedImage),
    );
  }
}