import 'package:sales_app/app/core/common/search_drop_down.dart';

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

class PartyInfo {
  final String partyName;
  final String id;
  bool isSelected;

  PartyInfo({
    required this.partyName,
    required this.id,
    this.isSelected = false,
  });

  // Convert JSON to PartyInfo instance
  factory PartyInfo.fromJson(Map<String, dynamic> json) {
    return PartyInfo(
      partyName: json['partyname'].toString(),
      id: json['id'].toString(),
    );
  }
    Item toDropdownItem() => Item(id: id, name: partyName);

}
