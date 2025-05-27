class PriceListModel {
  final int id;
  final int? productId;
  final int? partyId;
  final int? price;
  PriceListModel({required this.id, this.productId, this.partyId, this.price});
  factory PriceListModel.fromJson(Map<String, dynamic> json) {
    return PriceListModel(
      id: json['id'] ?? 0,
      productId: json['product_id'],
      partyId: json['party_id'] ?? 0,
      price: json['price'] ?? 0,
    );
  }
}
