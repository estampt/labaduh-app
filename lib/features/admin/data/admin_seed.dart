import 'admin_models.dart';

final seedOrders = <AdminOrder>[
  AdminOrder(id: '1024', customerName: 'Rehnee', vendorName: 'Sparkle Laundry', total: 418, createdAt: 'Today 10:05', status: AdminOrderStatus.matched, distanceKm: 1.2),
  AdminOrder(id: '1023', customerName: 'Miguel', vendorName: 'QuickWash', total: 309, createdAt: 'Today 09:12', status: AdminOrderStatus.washing, distanceKm: 2.8),
  AdminOrder(id: '1022', customerName: 'Aya', vendorName: 'Sparkle Laundry', total: 520, createdAt: 'Yesterday', status: AdminOrderStatus.completed, distanceKm: 0.9),
];

final seedVendors = <AdminVendor>[
  AdminVendor(id: 'v001', name: 'Sparkle Laundry', city: 'Quezon City', rating: 4.8, activeOrders: 3, subscriptionTier: 'Pro'),
  AdminVendor(id: 'v002', name: 'QuickWash', city: 'Makati', rating: 4.6, activeOrders: 2, subscriptionTier: 'Free'),
  AdminVendor(id: 'v003', name: 'Bubbles Cleaners', city: 'Pasig', rating: 4.9, activeOrders: 1, subscriptionTier: 'Elite'),
];

final seedUsers = <AdminUser>[
  AdminUser(id: 'u001', name: 'Rehnee', city: 'Quezon City', createdAt: '2026-01-05'),
  AdminUser(id: 'u002', name: 'Miguel', city: 'Makati', createdAt: '2026-01-02'),
  AdminUser(id: 'u003', name: 'Aya', city: 'Pasig', createdAt: '2025-12-21'),
];

final seedPricing = <PricingRow>[
  PricingRow(serviceId: 'wash_fold', serviceName: 'Wash & Fold', baseKg: 6, basePrice: 299, excessPerKg: 45),
  PricingRow(serviceId: 'wash_iron', serviceName: 'Wash & Iron', baseKg: 6, basePrice: 399, excessPerKg: 55),
  PricingRow(serviceId: 'dry_clean', serviceName: 'Dry Wash', baseKg: 6, basePrice: 499, excessPerKg: 75),
  PricingRow(serviceId: 'blankets', serviceName: 'Blankets', baseKg: 1, basePrice: 199, excessPerKg: 150),
];
