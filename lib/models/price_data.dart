class PriceData {
  final DateTime timestamp;
  final double price;
  final String area = 'FI';

  PriceData({required this.timestamp, required this.price});
  factory PriceData.fromJson(Map<String, dynamic> json) {
    return PriceData(
      timestamp: DateTime.parse(json['aikaleima_suomi']),
      price: (json['hinta'] as num).toDouble(),
    );
  }
}
