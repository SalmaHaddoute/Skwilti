import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ConversationScreen extends StatefulWidget {
  final String teacherName;
  final String subject;
  final IconData teacherIcon;

  const ConversationScreen({
    super.key,
    required this.teacherName,
    required this.subject,
    required this.teacherIcon,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [
    Message(
      text: 'Bonjour ! Je suis disponible pour répondre à vos questions.',
      isTeacher: true,
      time: '10:30',
    ),
    Message(
      text: 'Merci ! J\'aimerais savoir comment se déroule le prochain contrôle.',
      isTeacher: false,
      time: '10:32',
    ),
    Message(
      text: 'Le contrôle portera sur les chapitres 3 et 4, avec des QCM et des exercices pratiques.',
      isTeacher: true,
      time: '10:33',
    ),
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(Message(
        text: _messageController.text,
        isTeacher: false,
        time: DateTime.now().toString().substring(11, 16),
      ));
    });

    _messageController.clear();

    // Simuler une réponse de l'enseignant
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages.add(Message(
            text: 'Merci pour votre message. Je vous répondrai dès que possible.',
            isTeacher: true,
            time: DateTime.now().toString().substring(11, 16),
          ));
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F0), // Fond orange clair
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1), // Orange très clair
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.teacherIcon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.teacherName,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    widget.subject,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppColors.textSub,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.phone, color: AppColors.primary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(LucideIcons.video, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return MessageBubble(message: message);
              },
            ),
          ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Tapez votre message...',
                        hintStyle: GoogleFonts.nunito(
                          fontSize: 14,
                          color: AppColors.textSub,
                        ),
                        border: InputBorder.none,
                      ),
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: AppColors.text,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary, // Orange
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    icon: const Icon(LucideIcons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Message {
  final String text;
  final bool isTeacher;
  final String time;

  Message({
    required this.text,
    required this.isTeacher,
    required this.time,
  });
}

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isTeacher ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (message.isTeacher) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1), // Orange très clair
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(LucideIcons.user, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isTeacher ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: message.isTeacher ? Colors.white : AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    border: message.isTeacher 
                        ? Border.all(color: AppColors.border, width: 0.5)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: message.isTeacher ? AppColors.text : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message.time,
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    color: AppColors.textSub,
                  ),
                ),
              ],
            ),
          ),
          if (!message.isTeacher) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(LucideIcons.user, size: 16, color: AppColors.green),
            ),
          ],
        ],
      ),
    );
  }
}
