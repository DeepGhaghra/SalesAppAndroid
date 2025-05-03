class PartyInfo {
  final String partyName;
  final String id;

  PartyInfo({required this.partyName, required this.id});

  // Convert JSON to PartyInfo instance
  factory PartyInfo.fromJson(Map<String, dynamic> json) {
    return PartyInfo(
      partyName: json['partyname'].toString(),
      id: json['id'].toString(),
    );
  }
}
