import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';
import 'mesh_service.dart';
import 'database_service.dart';

void main() => runApp(MaterialApp(home: UserSetupScreen(), theme: ThemeData.dark()));

class UserSetupScreen extends StatelessWidget {
  final TextEditingController _nameController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Create Your Identity", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              TextField(controller: _nameController, decoration: InputDecoration(labelText: "Enter Name")),
              SizedBox(height: 20),
              ElevatedButton(onPressed: () {
                String id = Uuid().v4();
                Navigator.push(context, MaterialPageRoute(builder: (c) => HomeScreen(userId: id, userName: _nameController.text)));
              }, child: Text("Start Messaging"))
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String userId;
  final String userName;
  HomeScreen({required this.userId, required this.userName});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MeshService _mesh = MeshService();
  DatabaseService _db = DatabaseService();
  List<BonsoirService> _peers = [];

  @override
  void initState() {
    super.initState();
    _mesh.startBroadcasting(widget.userName);
    _mesh.startListening(widget.userId, (senderId, text) {
      _db.saveMessage(Message(id: Uuid().v4(), senderId: senderId, receiverId: widget.userId, text: text, timestamp: DateTime.now(), isFromMe: false));
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Freedom Chat: ${widget.userName}")),
      body: Column(
        children: [
          ElevatedButton(onPressed: () async {
            var found = await _mesh.discoverPeers();
            setState(() => _peers = found);
          }, child: Text("Scan for Nearby People")),
          Expanded(
            child: ListView.builder(
              itemCount: _peers.length,
              itemBuilder: (c, i) => ListTile(
                title: Text(_peers[i].name),
                subtitle: Text(_peers[i].host),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ChatRoom(myId: widget.userId, peer: _peers[i], db: _db, mesh: _mesh))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatRoom extends StatefulWidget {
  final String myId;
  final BonsoirService peer;
  final DatabaseService db;
  final MeshService mesh;
  ChatRoom({required this.myId, required this.peer, required this.db, required this.mesh});
  @override
  _ChatRoomState createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  final TextEditingController _msgController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.peer.name)),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Message>>(
              future: widget.db.getMessages(widget.peer.name, widget.myId),
              builder: (c, snap) {
                if (!snap.hasData) return Center(child: CircularProgressIndicator());
                return ListView.builder(
                  itemCount: snap.data!.length,
                  itemBuilder: (c, i) {
                    var m = snap.data![i];
                    return Align(
                      alignment: m.isFromMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.all(10),
                        margin: EdgeInsets.all(5),
                        decoration: BoxDecoration(color: m.isFromMe ? Colors.deepPurple : Colors.grey, borderRadius: BorderRadius.circular(10)),
                        child: Text(m.text),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _msgController)),
                IconButton(icon: Icon(Icons.send), onPressed: () async {
                  await widget.mesh.sendMessage(widget.peer.host, widget.myId, _msgController.text);
                  await widget.db.saveMessage(Message(id: Uuid().v4(), senderId: widget.myId, receiverId: widget.peer.name, text: _msgController.text, timestamp: DateTime.now(), isFromMe: true));
                  _msgController.clear();
                  setState(() {});
                })
              ],
            ),
          )
        ],
      ),
    );
  }
}