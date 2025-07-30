enum SmsType {
  inbox,
  sent,
  draft,
  outbox,
}

enum SmsStatus {
  pending,
  sent,
  delivered,
  failed,
}

class SmsMessage {
  final String id;
  final String address;
  final String body;
  final DateTime timestamp;
  final SmsType type;
  final SmsStatus status;
  final bool isRead;
  final String? threadId;
  final String? simSlot;

  SmsMessage({
    required this.id,
    required this.address,
    required this.body,
    required this.timestamp,
    required this.type,
    this.status = SmsStatus.pending,
    this.isRead = false,
    this.threadId,
    this.simSlot,
  });

  SmsMessage copyWith({
    String? id,
    String? address,
    String? body,
    DateTime? timestamp,
    SmsType? type,
    SmsStatus? status,
    bool? isRead,
    String? threadId,
    String? simSlot,
  }) {
    return SmsMessage(
      id: id ?? this.id,
      address: address ?? this.address,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      status: status ?? this.status,
      isRead: isRead ?? this.isRead,
      threadId: threadId ?? this.threadId,
      simSlot: simSlot ?? this.simSlot,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'address': address,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'status': status.name,
      'isRead': isRead,
      'threadId': threadId,
      'simSlot': simSlot,
    };
  }

  factory SmsMessage.fromJson(Map<String, dynamic> json) {
    return SmsMessage(
      id: json['id'] ?? '',
      address: json['address'] ?? '',
      body: json['body'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      type: SmsType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SmsType.inbox,
      ),
      status: SmsStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SmsStatus.pending,
      ),
      isRead: json['isRead'] ?? false,
      threadId: json['threadId'],
      simSlot: json['simSlot'],
    );
  }
} 