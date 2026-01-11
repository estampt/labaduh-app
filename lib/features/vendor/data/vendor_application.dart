import '../../../core/models/user_role.dart';

class VendorApplication {
  VendorApplication({
    required this.id,
    required this.ownerName,
    required this.shopName,
    required this.city,
    required this.mobile,
    required this.email,
    required this.createdAtLabel,
    this.status = VendorApprovalStatus.pending,
    this.adminNote,
  });

  final String id;
  final String ownerName;
  final String shopName;
  final String city;
  final String mobile;
  final String email;
  final String createdAtLabel;

  final VendorApprovalStatus status;
  final String? adminNote;

  VendorApplication copyWith({VendorApprovalStatus? status, String? adminNote}) {
    return VendorApplication(
      id: id,
      ownerName: ownerName,
      shopName: shopName,
      city: city,
      mobile: mobile,
      email: email,
      createdAtLabel: createdAtLabel,
      status: status ?? this.status,
      adminNote: adminNote ?? this.adminNote,
    );
  }
}
