import 'dart:io';
import 'dart:convert';
import 'package:bonsoir/bonsoir.dart';
import 'encryption_service.dart';
import 'models.dart';

class MeshService {
  BonsoirService? _service;
  BonsoirBroadcast? _broadcast;
  ServerSocket? _server;
  
  Future<void> startListening(String myId, Function(String, String) callback) async {
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, 4545);
    _server!.listen((Socket client) {
      client.listen((data) {
        String decrypted = EncryptionService.decryptText(utf8.decode(data));
        var parts = decrypted.split('|');
        callback(parts[0], parts[1]);
      });
    });
  }

  Future<void> startBroadcasting(String userName) async {
    _service = BonsoirService(name: userName, type: '_meshchat._tcp', port: 4545);
    _broadcast = BonsoirBroadcast(service: _service!);
    await _broadcast!.ready();
    await _broadcast!.start();
  }

  Future<List<BonsoirService>> discoverPeers() async {
    BonsoirDiscovery discovery = BonsoirDiscovery(type: '_meshchat._tcp');
    await discovery.ready();
    List<BonsoirService> foundPeers = [];
    discovery.eventStream().listen((event) {
      if (event.type == BonsoirDiscoveryEvent.serviceFound) foundPeers.add(event.service!);
    });
    await discovery.start();
    await Future.delayed(Duration(seconds: 5));
    await discovery.stop();
    return foundPeers;
  }

  Future<void> sendMessage(String ip, String myId, String text) async {
    try {
      Socket socket = await Socket.connect(ip, 4545, timeout: Duration(seconds: 5));
      String encrypted = EncryptionService.encryptText("$myId|$text");
      socket.write(utf8.encode(encrypted));
      await socket.flush();
      await socket.close();
    } catch (e) {
      print("Send Error: $e");
    }
  }
}