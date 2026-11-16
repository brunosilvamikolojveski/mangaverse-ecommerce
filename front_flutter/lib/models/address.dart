class Address {
  const Address({required this.id, required this.values});
  factory Address.fromJson(Map<String, dynamic> json) =>
      Address(id: json['id'] as int, values: Map.of(json)..remove('id'));
  final int id;
  final Map<String, dynamic> values;
  String get label => values['label'] as String;
  String get recipient => values['recipient_name'] as String;
  bool get isDefault => values['is_default'] == true;
  String get streetLine =>
      '${values['street']}, ${values['number']}${values['complement'] == null ? '' : ' · ${values['complement']}'}';
  String get cityLine =>
      '${values['neighborhood']} · ${values['city']} / ${values['state']}';
}
