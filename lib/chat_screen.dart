import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  Future<String> generateResponse(String query) async {
    const apiKey = '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';
    var url = Uri.parse("https://api.openai.com/v1/completions");
    final response = await http.post(
      url,
      headers: {
        "content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      },
      body: json.encode({
        'model': 'text-davinci-003',
        'prompt': query,
        'temperature': 1,
        'max_tokens': 4000,
        'top_p': 1,
        'frequency_penalty': 0.0,
        'presence_penalty': 0.0,
      }),
    );
    final newReponse = jsonDecode(response.body);
    return newReponse['choices'][0]['text'];
  }

  final typeController = TextEditingController();
  final scrollController = ScrollController();
  List<ChatMessage> messages = [];
  SpeechToText speechToText = SpeechToText();
  bool isLoading = false;
  bool isListen = false;

  scrollDown() {
    scrollController.animateTo(scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF343541),
      appBar: AppBar(
        backgroundColor: Colors.greenAccent,
        title: Text(
          'Chat Bot',
          style: TextStyle(color: Colors.black, fontSize: height * 0.031),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
              child: ListView.builder(
            itemCount: messages.length,
            controller: scrollController,
            itemBuilder: (context, index) {
              var msg = messages[index];
              return ChatMessageWidget(
                  text: msg.text, chatMessageType: msg.chatMessageType);
            },
          )),
          Visibility(
            visible: isLoading,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Bot is Typing...',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    cursorColor: Colors.white,
                    style: const TextStyle(color: Colors.white),
                    controller: typeController,
                    decoration: const InputDecoration(
                      hintText: 'type here...',
                      hintStyle: TextStyle(color: Colors.white),
                      fillColor: Color(0xFF444654),
                      filled: true,
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                    ),
                    onFieldSubmitted: (value) {
                      setState(() {
                        value = typeController.text;
                      });
                    },
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Visibility(
                  visible: !isLoading,
                  child: GestureDetector(
                    onTapDown: (details) async {
                      if (!isListen) {
                        var available = await speechToText.initialize();
                        if (available) {
                          setState(() {
                            isListen = true;
                            speechToText.listen(
                              onResult: (result) {
                                typeController.text = result.recognizedWords;
                                print('speecch to text ${typeController.text}');
                              },
                            );
                          });
                        }
                      }
                    },
                    onTapUp: (details) {
                      setState(() {
                        isListen = false;
                      });
                      // speechToText.stop();
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                          color: Color(0xFF44654), shape: BoxShape.circle),
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.mic,
                          color: Color.fromRGBO(142, 142, 160, 1),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Visibility(
                  visible: !isLoading,
                  child: Container(
                    decoration: const BoxDecoration(
                        color: Color(0x0ff44654), shape: BoxShape.circle),
                    child: IconButton(
                      onPressed: () async {
                        setState(() {
                          messages.add(
                            ChatMessage(
                                text: typeController.text,
                                chatMessageType: ChatMessageType.user),
                          );
                          isLoading = true;
                        });
                        var input = typeController.text;
                        typeController.clear();
                        Future.delayed(
                          const Duration(milliseconds: 50),
                        ).then((value) => scrollDown());
                        generateResponse(input).then((value) {
                          setState(() {
                            isLoading = false;
                            messages.add(
                              ChatMessage(
                                  text: value,
                                  chatMessageType: ChatMessageType.bot),
                            );
                          });
                        });
                        typeController.clear();
                        Future.delayed(
                          const Duration(milliseconds: 50),
                        ).then((value) => scrollDown());
                      },
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Color.fromRGBO(142, 142, 160, 1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget ChatMessageWidget(
      {required String text, required ChatMessageType chatMessageType}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(15),
      color: chatMessageType == ChatMessageType.bot
          ? const Color(0xFF444654)
          : const Color(0xFF343541),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          chatMessageType == ChatMessageType.bot
              ? Container(
                  margin: const EdgeInsets.only(right: 15),
                  child: CircleAvatar(
                    backgroundColor: const Color.fromRGBO(16, 163, 127, 1),
                    child: Image.asset('asset/pngwing.com.png'),
                  ),
                )
              : Container(
                  margin: const EdgeInsets.only(right: 15),
                  child: const CircleAvatar(
                    backgroundColor: Color(0xFF444654),
                    child: Icon(CupertinoIcons.person_alt),
                  ),
                ),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  text,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Colors.white),
                ),
              ),
            ],
          )),
        ],
      ),
    );
  }
}
