class SalesInvoiceGroup {
  final String date;
  final String invoiceNo;
  final String partyName;
  final int totalQty;

  SalesInvoiceGroup({
    required this.date,
    required this.invoiceNo,
    required this.partyName,
    required this.totalQty,
  });

  factory SalesInvoiceGroup.fromJson(Map<String, dynamic> json) {
    return SalesInvoiceGroup(
      date: json['date'],
      invoiceNo: json['invoiceno'],
      partyName: json['party_name'],
      totalQty: json['total_qty'],
    );
  }
}

class SalesListFilter {
  final String? partyName;
  final String fromDate;
  final String toDate;
  //final int shopId;

  SalesListFilter({
    this.partyName,
    required this.fromDate,
    required this.toDate,
    //required this.shopId,
  });

  Map<String, dynamic> toJson() {
    return {
      'party_name': partyName,
      'from_date': fromDate,
      'to_date': toDate,
      //'shop_id': shopId,
    };
  }
}
