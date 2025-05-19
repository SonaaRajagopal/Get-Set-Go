import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:image_picker/image_picker.dart'; // For image picking
import 'dart:io'; // For file handling

class TravelChatbotPage extends StatefulWidget {
  const TravelChatbotPage({super.key});

  @override
  _TravelChatbotPageState createState() => _TravelChatbotPageState();
}

class _TravelChatbotPageState extends State<TravelChatbotPage> {
  final Gemini _gemini = Gemini.instance;
  final List<ChatMessage> _messages = [];
  final ChatUser _currentUser = ChatUser(
    id: '1',
    firstName: 'User',
    lastName: '',
  );
  final ChatUser _bot = ChatUser(
    id: '2',
    firstName: 'Travel Bot',
    lastName: '',
  );

  @override
  void initState() {
    super.initState();
    _addBotMessage(
        "Hello! I'm your travel assistant. How can I help you plan your trip today?");
  }

  // Adding bot message to the chat
  void _addBotMessage(String text) {
    ChatMessage message = ChatMessage(
      user: _bot,
      createdAt: DateTime.now(),
      text: text,
    );
    setState(() {
      _messages.insert(0, message);
    });
  }

  // Handling sending text messages
  void _handleSendPressed(ChatMessage message) {
    setState(() {
      _messages.insert(0, message);
    });
    _getBotResponse(message.text);
  }

  // Fetching bot response using Gemini API
  void _getBotResponse(String message) async {
    try {
      final response = await _gemini.text(
        '''You are a helpful travel assistant. Respond to the following query:
        $message
        Provide concise and helpful travel advice, recommendations, or information.''',
      );

      if (response != null && response.content != null) {
        final botResponse = response.content?.parts?.firstOrNull?.text;
        if (botResponse != null && botResponse.isNotEmpty) {
          _addBotMessage(botResponse);
        } else {
          _addBotMessage(
              "I'm sorry, I couldn't generate a response. Can you try asking in a different way?");
        }
      } else {
        _addBotMessage(
            "I'm sorry, I couldn't process that request. Can you try asking in a different way?");
      }
    } catch (e) {
      print('Error getting response: $e');
      _addBotMessage(
          "I'm having trouble connecting right now. Please try again later.");
    }
  }

  // Picking image from gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      _handleImageMessage(pickedFile.path);
    }
  }

  // Handling sending image messages
  void _handleImageMessage(String imagePath) {
    final File imageFile = File(imagePath);
    final String fileName = imageFile.path.split('/').last;

    ChatMessage message = ChatMessage(
      user: _currentUser,
      createdAt: DateTime.now(),
      medias: [
        ChatMedia(
          url: imagePath,
          fileName: fileName, // Required parameter
          type: MediaType.image,
        ),
      ],
    );
    setState(() {
      _messages.insert(0, message);
    });

    // Simulate a bot response for images
    _addBotMessage("That's a great picture! Let me know if you need more info.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Chatbot'),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo),
            onPressed: _pickImage, // Trigger image picking
          ),
        ],
      ),
      body: DashChat(
        currentUser: _currentUser,
        onSend: _handleSendPressed,
        messages: _messages,
        inputOptions: const InputOptions(),
      ),
    );
  }
}
