import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';
import 'package:hexcolor/hexcolor.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> _chatHistory = [];

  Future<void> _sendMessage(String message) async {
    final url = Uri.parse(
        'http://localhost:5000/chat'); // Sesuaikan dengan URL server Python
    final body = jsonEncode({"message": message});

    print("Mengirim pesan: $message"); // Log pesan yang dikirim

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      print("Status Code: ${response.statusCode}"); // Log status code
      print("Respons Body: ${response.body}"); // Log respons body

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _chatHistory.add({"user": message, "buddy": data["response"]});
        });
      } else {
        setState(() {
          _chatHistory
              .add({"user": message, "buddy": "Error: ${response.statusCode}"});
        });
      }
    } catch (e) {
      print("Error: $e"); // Log error
      setState(() {
        _chatHistory.add({"user": message, "buddy": "Error: $e"});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(" Buddy",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(50.0),
                  child: Image.asset(
                    'assets/images/robotLogo.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(height: 8.0),
                Text(
                  "Hai Buddies!",
                  style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue),
                ),
                Text(
                  "Ayok menabung dan beritahu saya target kamu kedepan!",
                  style: TextStyle(fontSize: 14.0, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16.0),
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                final chat = _chatHistory[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.0),
                      margin: EdgeInsets.only(bottom: 8.0),
                      decoration: BoxDecoration(
                        color: HexColor("#62B8FF"),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        "You: ${chat["user"]}",
                        style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: HexColor("#494949")),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(12.0),
                      margin: EdgeInsets.only(bottom: 8.0),
                      decoration: BoxDecoration(
                        color: HexColor("#CADEEF"),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        "Buddy: ${chat["buddy"]}",
                        style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: HexColor("#494949")),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => DashboardScreen()),
                    );
                  },
                  child: Container(
                    padding:
                        EdgeInsets.all(10), // Optional: Menambahkan padding
                    decoration: BoxDecoration(
                      color:
                          Colors.blue, // Ganti dengan warna yang Anda inginkan
                      borderRadius: BorderRadius.circular(
                          5), // Optional: Menambahkan border radius
                    ),
                    child: Text(
                      "Saya Siap Menabung",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: "Ketik pesan Anda...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          filled: true,
                          fillColor: Colors.blue[100],
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 12.0),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.0),
                    CircleAvatar(
                      backgroundColor: Colors.blue,
                      radius: 28,
                      child: IconButton(
                        icon: Icon(Icons.send, color: Colors.white, size: 24),
                        onPressed: () {
                          if (_controller.text.isNotEmpty) {
                            _sendMessage(_controller.text);
                            _controller.clear();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: HexColor("#f7f9f8"),
    );
  }
}
