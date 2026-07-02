// WHAT THIS FILE DOES:
// The "Source of Truth" for a live 1v1 match.

import 'package:cloud_firestore/cloud_firestore.dart';

class GameRoomModel {
  final String roomId;
  final String roomCode;
  final String status;
  final Map<String, dynamic> player1;
  final Map<String, dynamic>? player2;
  final List<dynamic> questions;
  final int currentQuestionIndex;
  final DateTime? questionStartedAt;
  final String? winnerId;
  final List<String> claimedRewards;
  final String? player1Emoji;
  final String? player2Emoji;
  final List<String> rematchRequests;
  final String? nextMatchId;
  final int? categoryId;
  final String categoryName;

  // Arena Breaker Fields
  final bool isArenaBreaker;
  final Map<String, dynamic>? arenaBreakerQuestion;
  final Map<String, dynamic> arenaBreakerSubmissions;
  final bool isArenaBreakerWin;
  final String? arenaBreakerStatusMessage;

  // Disconnect & Forfeit Fields
  final Map<String, dynamic> presence;
  final String? forfeitWinnerId;

  GameRoomModel({
    required this.roomId,
    this.roomCode = '',
    required this.status,
    required this.player1,
    this.player2,
    required this.questions,
    this.currentQuestionIndex = 0,
    this.questionStartedAt,
    this.winnerId,
    this.claimedRewards = const [],
    this.player1Emoji,
    this.player2Emoji,
    this.rematchRequests = const [],
    this.nextMatchId,
    this.categoryId,
    this.categoryName = 'Mixed / Random',
    this.isArenaBreaker = false,
    this.arenaBreakerQuestion,
    this.arenaBreakerSubmissions = const {},
    this.isArenaBreakerWin = false,
    this.arenaBreakerStatusMessage,
    this.presence = const {},
    this.forfeitWinnerId,
  });

  factory GameRoomModel.fromJson(Map<String, dynamic> json) {
    return GameRoomModel(
      roomId: json['roomId'] ?? '',
      roomCode: json['roomCode'] ?? '',
      status: json['status'] ?? 'waiting',
      player1: Map<String, dynamic>.from(json['player1'] ?? {}),
      player2: json['player2'] != null ? Map<String, dynamic>.from(json['player2']) : null,
      questions: List<dynamic>.from(json['questions'] ?? []),
      currentQuestionIndex: json['currentQuestionIndex'] ?? 0,
      questionStartedAt: json['questionStartedAt'] != null
          ? (json['questionStartedAt'] is Timestamp
              ? (json['questionStartedAt'] as Timestamp).toDate()
              : DateTime.tryParse(json['questionStartedAt'].toString()))
          : null,
      winnerId: json['winnerId'],
      claimedRewards: List<String>.from(json['claimedRewards'] ?? []),
      player1Emoji: json['player1Emoji'],
      player2Emoji: json['player2Emoji'],
      rematchRequests: List<String>.from(json['rematchRequests'] ?? []),
      nextMatchId: json['nextMatchId'],
      categoryId: json['categoryId'],
      categoryName: json['categoryName'] ?? 'Mixed / Random',
      isArenaBreaker: json['isArenaBreaker'] ?? false,
      arenaBreakerQuestion: json['arenaBreakerQuestion'],
      arenaBreakerSubmissions: Map<String, dynamic>.from(json['arenaBreakerSubmissions'] ?? {}),
      isArenaBreakerWin: json['isArenaBreakerWin'] ?? false,
      arenaBreakerStatusMessage: json['arenaBreakerStatusMessage'],
      presence: Map<String, dynamic>.from(json['presence'] ?? {}),
      forfeitWinnerId: json['forfeitWinnerId'],
    );
  }

  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        'roomCode': roomCode,
        'status': status,
        'player1': player1,
        'player2': player2,
        'questions': questions,
        'currentQuestionIndex': currentQuestionIndex,
        'questionStartedAt': questionStartedAt != null ? Timestamp.fromDate(questionStartedAt!) : null,
        'winnerId': winnerId,
        'claimedRewards': claimedRewards,
        'player1Emoji': player1Emoji,
        'player2Emoji': player2Emoji,
        'rematchRequests': rematchRequests,
        'nextMatchId': nextMatchId,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'isArenaBreaker': isArenaBreaker,
        'arenaBreakerQuestion': arenaBreakerQuestion,
        'arenaBreakerSubmissions': arenaBreakerSubmissions,
        'isArenaBreakerWin': isArenaBreakerWin,
        'arenaBreakerStatusMessage': arenaBreakerStatusMessage,
        'presence': presence,
        'forfeitWinnerId': forfeitWinnerId,
      };

  GameRoomModel copyWith({
    String? status,
    Map<String, dynamic>? player1,
    Map<String, dynamic>? player2,
    int? currentQuestionIndex,
    DateTime? questionStartedAt,
    String? winnerId,
    bool? isArenaBreaker,
    Map<String, dynamic>? arenaBreakerQuestion,
    Map<String, dynamic>? arenaBreakerSubmissions,
    bool? isArenaBreakerWin,
    String? player1Emoji,
    String? player2Emoji,
    List<String>? rematchRequests,
    String? nextMatchId,
    String? forfeitWinnerId,
  }) {
    return GameRoomModel(
      roomId: roomId,
      roomCode: roomCode,
      status: status ?? this.status,
      player1: player1 ?? this.player1,
      player2: player2 ?? this.player2,
      questions: questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      questionStartedAt: questionStartedAt ?? this.questionStartedAt,
      winnerId: winnerId ?? this.winnerId,
      claimedRewards: claimedRewards,
      player1Emoji: player1Emoji ?? this.player1Emoji,
      player2Emoji: player2Emoji ?? this.player2Emoji,
      rematchRequests: rematchRequests ?? this.rematchRequests,
      nextMatchId: nextMatchId ?? this.nextMatchId,
      categoryId: categoryId,
      categoryName: categoryName,
      isArenaBreaker: isArenaBreaker ?? this.isArenaBreaker,
      arenaBreakerQuestion: arenaBreakerQuestion ?? this.arenaBreakerQuestion,
      arenaBreakerSubmissions: arenaBreakerSubmissions ?? this.arenaBreakerSubmissions,
      isArenaBreakerWin: isArenaBreakerWin ?? this.isArenaBreakerWin,
      arenaBreakerStatusMessage: arenaBreakerStatusMessage,
      presence: presence,
      forfeitWinnerId: forfeitWinnerId ?? this.forfeitWinnerId,
    );
  }
}
