class VoucherModel {
  final String code;
  final String type; // 'percentage', 'fixed', 'shipping'
  final dynamic value; // double untuk percentage, int untuk fixed
  final int? maxDiscount;
  final int minPurchase;
  final String description;
  final bool isActive;

  VoucherModel({
    required this.code,
    required this.type,
    required this.value,
    this.maxDiscount,
    required this.minPurchase,
    required this.description,
    required this.isActive,
  });

  factory VoucherModel.fromFirestore(Map<String, dynamic> data) {
    return VoucherModel(
      code: data['code'] ?? '',
      type: data['type'] ?? 'fixed',
      value: data['value'],
      maxDiscount: data['max_discount'],
      minPurchase: data['min_purchase'] ?? 0,
      description: data['description'] ?? '',
      isActive: data['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'type': type,
      'value': value,
      'max_discount': maxDiscount,
      'min_purchase': minPurchase,
      'description': description,
      'is_active': isActive,
    };
  }
}