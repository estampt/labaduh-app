class Address {
  Address({
    required this.id,
    required this.label,
    required this.line1,
    this.line2,
    required this.city,
    required this.notes,
  });

  final String id;
  final String label;
  final String line1;
  final String? line2;
  final String city;
  final String notes;
}
