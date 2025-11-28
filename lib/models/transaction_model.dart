class Transaction {
  final String id;
  final double amount;
  final String description;
  final DateTime date;
  final String type; // 'income', 'expense'

  Transaction({
    required this.id,
    required this.amount,
    required this.description,
    required this.date,
    required this.type,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] ?? '',
      date: DateTime.parse(json['date']),
      type: json['type'] ?? 'expense',
    );
  }
}
