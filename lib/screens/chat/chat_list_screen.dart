import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:paper_tracker/blocs/auth/auth_bloc.dart';
import 'package:paper_tracker/blocs/auth/auth_state.dart';
import 'package:paper_tracker/blocs/chat_list/chat_list_bloc.dart';
import 'package:paper_tracker/blocs/chat_list/chat_list_event.dart';
import 'package:paper_tracker/blocs/chat_list/chat_list_state.dart';
import 'package:paper_tracker/config/theme.dart';
import 'package:paper_tracker/models/user_model.dart';
import 'package:paper_tracker/repositories/chat_repository.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late String currentUserId;
  late String currentUserName;

  @override
  void initState() {
    super.initState();
    final authBloc = context.read<AuthBloc>();
    final user = (authBloc.state as AuthAuthenticated).user;
    currentUserId = user.uid;
    currentUserName = user.displayName ?? user.email ?? 'Unknown';

    context.read<ChatListBloc>().add(LoadChatsRequested(currentUserId));
  }

  void _showNewChatDialog() async {
    final chatRepo = context.read<ChatRepository>();
    final users = await chatRepo.getAllUsers();
    
    // Filter out current user
    final otherUsers = users.where((u) => u.uid != currentUserId).toList();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'New Chat',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: otherUsers.length,
                    itemBuilder: (context, index) {
                      final user = otherUsers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                          child: Text(
                            user.displayName.isNotEmpty
                                ? user.displayName[0].toUpperCase()
                                : user.email[0].toUpperCase(),
                            style: const TextStyle(color: AppTheme.primaryColor),
                          ),
                        ),
                        title: Text(user.displayName.isNotEmpty ? user.displayName : user.email),
                        subtitle: Text(user.email, style: TextStyle(color: AppTheme.textSecondary)),
                        onTap: () {
                          Navigator.pop(context);
                          context.read<ChatListBloc>().add(
                            CreateChatRequested(
                              currentUserId: currentUserId,
                              otherUserId: user.uid,
                              currentUserName: currentUserName,
                              otherUserName: user.displayName.isNotEmpty ? user.displayName : user.email,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatListBloc, ChatListState>(
      listener: (context, state) {
        if (state is ChatCreationSuccess) {
          context.push('/chat/${state.chat.id}');
        } else if (state is ChatListError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chats'),
        ),
        body: BlocBuilder<ChatListBloc, ChatListState>(
          builder: (context, state) {
            if (state is ChatListLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ChatListLoaded) {
              if (state.chats.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 64, color: AppTheme.textSecondary),
                      const SizedBox(height: 16),
                      Text(
                        'No ongoing chats.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _showNewChatDialog,
                        child: const Text('Start Chat'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: state.chats.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final chat = state.chats[index];
                  final otherUserName = chat.getOtherUserName(currentUserId);
                  final timeObj = chat.lastMessageTime;
                  final timeStr = DateFormat.jm().format(timeObj);

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                      radius: 24,
                      child: Text(
                        otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
                        style: const TextStyle(color: AppTheme.primaryColor, fontSize: 18),
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            otherUserName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          timeStr,
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        chat.lastMessage.isNotEmpty ? chat.lastMessage : 'Say hello...',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                    onTap: () => context.push('/chat/${chat.id}'),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showNewChatDialog,
          child: const Icon(Icons.add_comment),
        ),
      ),
    );
  }
}
