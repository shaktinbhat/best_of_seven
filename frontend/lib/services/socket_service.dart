import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/card_model.dart';

class SocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  bool isConnected = false;

  // Chat State
  List chatMessages = [];
  int unreadChatCount = 0;
  bool isChatOpen = false;

  // Declaration callback
  Function(Map<String, dynamic>)? onDeclareResult;

  // Game & Table State
  Map<String, dynamic>? gameState;
  List<CardModel> myHand = [];
  CardModel? topDiscard;
  Map<String, dynamic>? wildJokerInfo;
  String? currentTurnPlayerId;
  int currentDeal = 1;
  bool isDoubleDeal = false;

  // Identity & Lobby State
  String? myPlayerId;
  String? myPlayerName;
  String? currentRoomId;
  String? hostAddress;

  bool isMeHost = false;
  bool isMeReady = false;
  bool canStart = false;
  int countdownSeconds = 0;
  List<dynamic> players = [];

  void connect({
    required String host,
    required String roomId,
    required String playerId,
    required String playerName,
  }) {
    if (isConnected && currentRoomId == roomId && myPlayerId == playerId) {
      return;
    }

    disconnect();

    myPlayerId = playerId;
    myPlayerName = playerName;
    currentRoomId = roomId;
    hostAddress = host;

    final uri = Uri.parse(
      'ws://$host:8000/ws/$roomId/$playerId?player_name=${Uri.encodeComponent(playerName)}',
    );

    try {
      _channel = WebSocketChannel.connect(uri);
      isConnected = true;
      notifyListeners();

      _channel!.stream.listen(
        (message) {
          _handleIncomingMessage(message);
        },
        onError: (error) {
          isConnected = false;
          notifyListeners();
        },
        onDone: () {
          isConnected = false;
          notifyListeners();
        },
      );
    } catch (e) {
      isConnected = false;
      notifyListeners();
    }
  }

  void _handleIncomingMessage(dynamic rawMessage) {
    try {
      final decoded = jsonDecode(rawMessage as String) as Map<String, dynamic>;
      final type = decoded['type'];

      if (type == 'STATE_UPDATE') {
        _updateState(decoded['data'] as Map<String, dynamic>);
      } else if (type == 'DECLARE_RESULT') {
        final resultData = decoded['data'] as Map<String, dynamic>;
        if (onDeclareResult != null) {
          onDeclareResult!(resultData);
        }
      } else if (type == 'CHAT_MESSAGE') {
        final msgData = decoded['data'] as Map<String, dynamic>;
        // Avoid duplicate message if sender is self
        if (msgData['sender_id'] != myPlayerId) {
          chatMessages.add(msgData);
          if (!isChatOpen) {
            unreadChatCount++;
          }
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error decoding message: $e');
    }
  }

  void _updateState(Map<String, dynamic> data) {
    gameState = data;
    currentDeal = data['deal_number'] ?? 1;
    isDoubleDeal = data['is_double_points_deal'] ?? false;
    currentTurnPlayerId = data['current_turn_player_id'];
    isMeHost = data['is_me_host'] ?? false;
    isMeReady = data['is_me_ready'] ?? false;
    canStart = data['can_start'] ?? false;
    countdownSeconds = data['countdown_seconds'] ?? 0;
    players = data['players'] ?? [];

    if (data['top_discard'] != null) {
      topDiscard = CardModel.fromJson(data['top_discard']);
    } else {
      topDiscard = null;
    }

    wildJokerInfo = data['wild_joker'];

    if (data['my_hand'] != null) {
      final List<dynamic> cardsJson = data['my_hand'];
      myHand = cardsJson.map((c) => CardModel.fromJson(c)).toList();
    }

    notifyListeners();
  }

  // --- Hand Arrangement & Game Actions ---

  void reorderHand(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= myHand.length) return;
    if (newIndex < 0 || newIndex > myHand.length) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final card = myHand.removeAt(oldIndex);
    myHand.insert(newIndex, card);
    notifyListeners();
  }

  void drawCard(String source) {
    _sendAction('DRAW', {'source': source});
  }

  void discardCard(String cardUid) {
    _sendAction('DISCARD', {'card_uid': cardUid});
  }

  void declareHand(String finishCardUid, List<List<String>> groupsUids) {
    _sendAction('DECLARE', {
      'finish_card_uid': finishCardUid,
      'groups': groupsUids,
    });
  }

  void toggleReady() {
    _sendAction('TOGGLE_READY', {});
  }

  void startGame() {
    _sendAction('START_GAME', {});
  }

  void nextDeal() {
    _sendAction('NEXT_DEAL', {});
  }

  // --- Chat Actions ---

  void sendChatMessage(String text) {
    if (text.trim().isEmpty) return;

    final String timeStr =
        '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}';

    final localMessage = {
      'sender_id': myPlayerId ?? '',
      'sender_name': myPlayerName ?? 'You',
      'text': text.trim(),
      'timestamp': timeStr,
    };

    // 1. Immediately push locally for instant response
    chatMessages.add(localMessage);
    notifyListeners();

    // 2. Broadcast to room via WebSocket
    _sendAction('CHAT_MESSAGE', {
      'text': text.trim(),
      'timestamp': timeStr,
    });
  }

  void setChatOpen(bool open) {
    isChatOpen = open;
    if (open) {
      unreadChatCount = 0;
    }
    notifyListeners();
  }

  void _sendAction(String action, Map<String, dynamic> payload) {
    if (_channel != null && isConnected) {
      final msg = jsonEncode({
        'action': action,
        'payload': payload,
      });
      _channel!.sink.add(msg);
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    isConnected = false;
    myHand.clear();
    topDiscard = null;
    wildJokerInfo = null;
    gameState = null;
    chatMessages.clear();
    unreadChatCount = 0;
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
} 