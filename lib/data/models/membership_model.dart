import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum MembershipPlanType {
  monthly,
  yearly,
}

enum MembershipStatus {
  active,
  expired,
  cancelled,
}

class MembershipModel extends Equatable {
  final String id;
  final String userId;
  final MembershipPlanType planType;
  final int amount;
  final String paymentKey;
  final String orderId;
  final DateTime startDate;
  final DateTime endDate;
  final MembershipStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MembershipModel({
    required this.id,
    required this.userId,
    required this.planType,
    required this.amount,
    required this.paymentKey,
    required this.orderId,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MembershipModel.fromJson(Map<String, dynamic> json) {
    return MembershipModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      planType: MembershipPlanType.values.firstWhere(
        (e) => e.name == json['planType'],
        orElse: () => MembershipPlanType.monthly,
      ),
      amount: json['amount'] as int,
      paymentKey: json['paymentKey'] as String,
      orderId: json['orderId'] as String,
      startDate: (json['startDate'] as Timestamp).toDate(),
      endDate: (json['endDate'] as Timestamp).toDate(),
      status: MembershipStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MembershipStatus.expired,
      ),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'planType': planType.name,
      'amount': amount,
      'paymentKey': paymentKey,
      'orderId': orderId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  MembershipModel copyWith({
    String? id,
    String? userId,
    MembershipPlanType? planType,
    int? amount,
    String? paymentKey,
    String? orderId,
    DateTime? startDate,
    DateTime? endDate,
    MembershipStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MembershipModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planType: planType ?? this.planType,
      amount: amount ?? this.amount,
      paymentKey: paymentKey ?? this.paymentKey,
      orderId: orderId ?? this.orderId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isActive => status == MembershipStatus.active;
  
  bool get isExpired => endDate.isBefore(DateTime.now());
  
  int get remainingDays {
    if (isExpired) return 0;
    return endDate.difference(DateTime.now()).inDays;
  }

  String get planTypeDisplayName {
    switch (planType) {
      case MembershipPlanType.monthly:
        return '월간 멤버십';
      case MembershipPlanType.yearly:
        return '연간 멤버십';
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        planType,
        amount,
        paymentKey,
        orderId,
        startDate,
        endDate,
        status,
        createdAt,
        updatedAt,
      ];
}


