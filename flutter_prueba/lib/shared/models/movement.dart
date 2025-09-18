class Movement {
  final int? id; // local sqlite id
  final String? serverId; // remote _id (Mongo)
  final String type;
  final double amount;
  final String? description;
  final String accountFrom;
  final String accountTo;
  final String currency;
  final String status; // pending/completed/failed
  final String? reference;
  final DateTime? valueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus; // pending, synced, failed

  Movement({
    this.id,
    this.serverId,
    this.type = 'transfer',
    required this.amount,
    this.description,
    this.accountFrom = 'default',
    this.accountTo = 'default',
    this.currency = 'PEN',
    this.status = 'pending',
    this.reference,
    DateTime? valueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.syncStatus = 'pending',
  })  : valueDate = valueDate,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_id': serverId,
      'type': type,
      'amount': amount,
      'description': description,
      'account_from': accountFrom,
      'account_to': accountTo,
      'currency': currency,
      'status': status,
      'reference': reference,
      'value_date': valueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': syncStatus,
    };
  }

  factory Movement.fromMap(Map<String, dynamic> map) {
    return Movement(
      id: map['id'] as int?,
      serverId: map['server_id'] as String?,
      type: (map['type'] as String?) ?? 'transfer',
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String?,
      accountFrom: (map['account_from'] as String?) ?? 'default',
      accountTo: (map['account_to'] as String?) ?? 'default',
      currency: (map['currency'] as String?) ?? 'PEN',
      status: (map['status'] as String?) ?? 'pending',
      reference: map['reference'] as String?,
      valueDate: map['value_date'] != null ? DateTime.parse(map['value_date'] as String) : null,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : DateTime.now(),
      syncStatus: (map['sync_status'] as String?) ?? 'pending',
    );
  }
}
