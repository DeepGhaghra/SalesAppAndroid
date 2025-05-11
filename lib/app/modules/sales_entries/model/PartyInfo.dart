class PartyInfo {
  final String partyName;
  final String id;
  bool isSelected ;


  PartyInfo({required this.partyName, required this.id, this.isSelected = false});

  // Convert JSON to PartyInfo instance
  factory PartyInfo.fromJson(Map<String, dynamic> json) {
    return PartyInfo(
      partyName: json['partyname'].toString(),
      id: json['id'].toString(),
    );
  }
}
