class SelectedLocation {
  final String formattedAddress; // what user sees
  final String addressLine1;      // street + number (best-effort)
  final String? addressLine2;     // unit/building/etc (optional)
  final String? postalCode;
  final String? city;
  final String? stateProvince;
  final String? countryName;
  final String? countryISO;       // "SG", "PH", etc.
  final double latitude;
  final double longitude;
  final String? placeId;          // if provider supports it

  const SelectedLocation({
    required this.formattedAddress,
    required this.addressLine1,
    this.addressLine2,
    this.postalCode,
    this.city,
    this.stateProvince,
    this.countryName,
    this.countryISO,
    required this.latitude,
    required this.longitude,
    this.placeId,
  });

  Map<String, dynamic> toApiJson() => {
        "address_line1": addressLine1,
        "address_line2": addressLine2,
        "postal_code": postalCode,
        "city": city,
        "state_province": stateProvince,
        "country_name": countryName,
        "country_ISO": countryISO,
        "latitude": latitude,
        "longitude": longitude,
        "place_id": placeId,
        "formatted_address": formattedAddress,
      };
}
