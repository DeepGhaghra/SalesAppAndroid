class Purchaselist {
  final int? id;
  final String? date;
  final int? partyId;
  final int? designId;
  final int? quantity;
  final String? designNo;
  final int? locationId;
  final String? locationName;

  Purchaselist({
    this.id,
    required this.date,
    this.partyId,
    this.designId,
    required this.quantity,
    required this.designNo,
    this.locationId,
    this.locationName,
  });

  factory Purchaselist.fromJson(Map<String, dynamic> json) {
    return Purchaselist(
      id: json['id'] as int?,
      date: json['date'] as String?,
      partyId: json['party_id'] as int?,
      designId: json['design_id'] as int?,
      quantity: json['qty'] as int?,
      designNo: json['design_no'] as String? ?? '',
      locationId: json['location_id'] as int?,
      locationName: json['name'] as String?,
    );
  }
}
