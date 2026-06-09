import 'dart:io';
import 'dart:convert';
import 'package:bonsoir/bonsoir.dart';
import 'encryption_service.dart';
import 'models.dart';

class MeshService {
  BonsoirService? _service;
  BonsoirBroadcast? _broadcast;
  ServerSocket? _server;
  
  // 1. Start Server to LISTEN for messages from other phones
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

  // 2. Broadcast your presence so others can find you offline
  Future<void> startBroadcasting(String userName) async {
    try {
      _service = BonsoirService(
        name: userName, 
        type: '_meshchat._tcp', 
        port: 4545,
      );
      _broadcast = BonsoirBroadcast(service: _service!);
      await _broadcast!.ready();
      await _broadcast!.start();
    } catch (e) {
      print("Broadcasting error: $e");
    }
  }

  // 3. Scan for other users in the room
  Future<List<BonsoirService>> discoverPeers() async {
    try {
      BonsoirDiscovery discovery = BonsoirDiscovery(type: '_meshchat._tcp');
      await discovery.ready();
      
      List<BonsoirService> foundPeers = [];
      
      // FIXED: Added ?. to handle null safety
      discovery.eventStream?.listen((event) {
        if (event.type == BonsoirDiscoveryEvent.serviceFound && event.service != null) {
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

  // 4. Send an encrypted message directly to another phone
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
