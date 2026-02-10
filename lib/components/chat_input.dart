import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/theme.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSend;

  const ChatInput({super.key, required this.onSend});

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();

  void _handleSend() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onSend(_controller.text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), // Matches px-4 pt-4 pb-8
      decoration: const BoxDecoration(
        color: AppTheme.retroLight,
        border: Border(top: BorderSide(color: AppTheme.retroDark, width: 4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppTheme.retroDark, width: 4),
                boxShadow: const [
                  BoxShadow(color: AppTheme.retroDark, offset: Offset(2, 2)),
                ]
              ),
              child: TextField(
                controller: _controller,
                style: GoogleFonts.pressStart2p(fontSize: 10, color: AppTheme.retroDark), 
                decoration: InputDecoration(
                  hintText: "TYPE HERE...",
                  hintStyle: GoogleFonts.pressStart2p(fontSize: 10, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), 
                  isDense: true,
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 48, 
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.retroSky,
              border: Border.all(color: AppTheme.retroDark, width: 4),
              boxShadow: const [BoxShadow(color: AppTheme.retroDark, offset: Offset(2, 2))] 
            ),
            child: IconButton(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.send, size: 20, color: Colors.white),
              onPressed: _handleSend,
            ),
          ),
        ],
      ),
    );
  }
}
