enum UserRole { customer, vendor, admin }

extension UserRoleX on UserRole {
  String get label => switch (this) {
        UserRole.customer => 'Customer',
        UserRole.vendor => 'Vendor',
        UserRole.admin => 'Admin',
      };

  String get key => switch (this) {
        UserRole.customer => 'customer',
        UserRole.vendor => 'vendor',
        UserRole.admin => 'admin',
      };
}

enum VendorApprovalStatus { pending, approved, rejected, suspended }

extension VendorApprovalStatusX on VendorApprovalStatus {
  String get label => switch (this) {
        VendorApprovalStatus.pending => 'Pending',
        VendorApprovalStatus.approved => 'Approved',
        VendorApprovalStatus.rejected => 'Rejected',
        VendorApprovalStatus.suspended => 'Suspended',
      };
}
