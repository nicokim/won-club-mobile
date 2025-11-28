class Debt {
  final String id;
  final double amount;
  final String description;
  final String status; // 'pending', 'paid'
  final DateTime createdAt;

  Debt({
    required this.id,
    required this.amount,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
