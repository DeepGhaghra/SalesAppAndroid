class Purchaselist {
final int id;
  
  final String invoiceNo;
  final int? partyId;
  final int? productId;
  final int? designId;
  final int qty;
  
Purchaselist({
    required this.id,
    required this.invoiceNo,
    required this.partyId,
    required this.productId,
    required this.designId,
    required this.qty,
  });

  // Convert JSON to Purchaselist instance
  factory Purchaselist.fromJson(Map<String, dynamic> json) {
    return Purchaselist(
      id: json['id'] as int,
      invoiceNo: json['invoice_no'] as String,
      partyId: json['party_id'] as int?,
      productId: json['product_id'] as int?,
      designId: json['design_id'] as int?,
      qty: json['qty'] as int,
    );
  }
}