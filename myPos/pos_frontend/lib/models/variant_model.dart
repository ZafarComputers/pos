class Variant {
  String name;
  String values;
  DateTime createdDate; // DateTime instead of String
  bool status;          // bool instead of String

  Variant({
    required this.name,
    required this.values,
    required this.createdDate,
    required this.status,
  });
}
