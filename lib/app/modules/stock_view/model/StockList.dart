class StockList {
  final String designNo;
  final String id;
  final String locationid;
  final String location;
  final String qtyAtLocation;
  final String folderName;

  StockList({
    required this.designNo,
    required this.id,
    required this.locationid,
    required this.location,
    required this.qtyAtLocation,
    required this.folderName,
  });

  // Convert JSON to Stocklist instance
  factory StockList.fromJson(Map<String, dynamic> json) {
    final productsDesign = json['products_design'];
    final locations = json['locations'];
    final productHead =
        productsDesign != null ? productsDesign['product_head'] : null;
    final folder = productHead != null ? productHead['folder'] : null;

    return StockList(
      designNo:
          (productsDesign != null && productsDesign['design_no'] != null)
              ? productsDesign['design_no'].toString()
              : 'N/A',
      id: json['id'].toString(),
      locationid: json['location_id'].toString(),
      location:
          (locations != null && locations['name'] != null)
              ? locations['name'].toString()
              : 'Unknown',
      qtyAtLocation: json['quantity'].toString(),
      folderName:
          (folder != null && folder['folder_name'] != null)
              ? folder['folder_name'].toString()
              : 'N/A',
    );
  }
}
