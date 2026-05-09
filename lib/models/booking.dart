import 'package:uuid/uuid.dart';

enum PaymentType { cod, prepaid }

class Booking {
  final String id;
  final String consignmentNumber;
  final String customerName;
  final String mobileNumber;
  final double weight;
  final double chargedAmount;
  final double costAmount;
  final PaymentType paymentType;
  final double codAmount;
  final String courierName;
  final DateTime createdAt;

  Booking({
    String? id,
    required this.consignmentNumber,
    required this.customerName,
    required this.mobileNumber,
    required this.weight,
    required this.chargedAmount,
    required this.costAmount,
    required this.paymentType,
    required this.codAmount,
    required this.courierName,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  double get profit => chargedAmount - costAmount;

  // Convert to map for Supabase
  Map<String, dynamic> toMap() => {
        'id': id,
        'consignmentNumber': consignmentNumber,
        'customerName': customerName,
        'mobileNumber': mobileNumber,
        'weight': weight,
        'chargedAmount': chargedAmount,
        'costAmount': costAmount,
        'paymentType': paymentType == PaymentType.cod ? 'cod' : 'prepaid',
        'codAmount': codAmount,
        'courierName': courierName,
        'createdAt': createdAt.toIso8601String(),
      };

  // Create from Supabase map
  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] as String,
      consignmentNumber: map['consignmentNumber'] as String,
      customerName: map['customerName'] as String,
      mobileNumber: map['mobileNumber'] as String,
      weight: (map['weight'] as num).toDouble(),
      chargedAmount: (map['chargedAmount'] as num).toDouble(),
      costAmount: (map['costAmount'] as num).toDouble(),
      paymentType: (map['paymentType'] as String) == 'prepaid'
          ? PaymentType.prepaid
          : PaymentType.cod,
      codAmount: (map['codAmount'] as num).toDouble(),
      courierName: map['courierName'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
