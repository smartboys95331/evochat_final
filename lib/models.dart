class User {
  final String id;
  final String name;
  final String ip;

  User({required this.id, required this.name, required this.ip});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'ip': ip};
  factory User.fromMap(Map<String, dynamic> map) => User(id: map['id'], name: map['name'], ip: map['ip']);
}

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final bool isFromMe;

  Message({required this.id, required this.senderId, required this.receiverId, required this.text, required this.timestamp, required this.isFromMe});

  Map<String, dynamic> toMap() => {
    'id': id, 'senderId': senderId, 'receiverId': receiverId, 
    'text': text, 'timestamp': timestamp.toIso8601String(),
  };

  factory Message.fromMap(Map<String, dynamic> map, bool isFromMe) => Message(
    id: map['id'], senderId: map['senderId'], receiverId: map['receiverId'],
    text: map['text'], timestamp: DateTime.parse(map['timestamp']), isFromMe: isFromMe,
  );
}