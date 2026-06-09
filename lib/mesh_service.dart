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
    try {
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, 4545);
      _server!.listen((Socket client) {
        client.listen((data) {
          try {
            String decrypted = EncryptionService.decryptText(utf8.decode(data));
            var parts = decrypted.split('|');
            if (parts.length >= 2) {
              callback(parts[0], parts[1]);
            }
          } catch (e) {
            print("Decryption error: $e");
          }
        });
      });
    } catch (e) {
      print("Server bind error: $e");
    }
  }

  Future<void> startBroadcasting(String userName) async {
    try {
      _service = BonsoirService(
        name: userName, 
        type: '_meshchat._tcp', 
        port: 4545,
      );
      _broadcast = BonsoirBroadcast(service: _service!);
      await _broadcast!.start();
    } catch (e) {
      print("Broadcasting error: $e");
    }
  }

  Future<List<BonsoirService>> discoverPeers() async {
    try {
      BonsoirDiscovery discovery = BonsoirDiscovery(type: '_meshchat._tcp');
      List<BonsoirService> foundPeers = [];
      
      discovery.eventStream?.listen((event) {
        // VERSION-PROOF: We just check if a service was found regardless of the event name
        if (event.service != null) {
          foundPeers.add(event.service!);
        }
      });

      await discovery.start();
      await Future.delayed(Duration(seconds: 5));
      await discovery.stop();
      
      return foundPeers;
    } catch (e) {
      print("Discovery error: $e");
      return [];
    }
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
