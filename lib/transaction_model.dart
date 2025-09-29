class TransactionModel {
  final int? id;
  final String title;
  final int amount;
  final String type; // "income" atau "expense"
  final String
  paymentMethod; // "cash" atau "cashless" (untuk income), "expense" (untuk expense)
  final String date;

  TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    this.paymentMethod = 'cash', // default ke cash
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'payment_method': paymentMethod,
      'date': date,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      title: map['title'] ?? '',
      amount: map['amount'] ?? 0,
      type: map['type'] ?? 'expense',
      paymentMethod: map['payment_method'] ?? 'cash',
      date: map['date'] ?? '',
    );
  }
}
