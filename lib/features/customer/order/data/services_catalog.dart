import '../domain/order_models.dart';

final servicesCatalog = <LaundryService>[
  LaundryService(id: 'wash_fold', name: 'Wash & Fold', baseQty: 6, unitType: UnitType.kilo, basePrice: 299, excessPerUnit: 45, icon: '🧺'),
  LaundryService(id: 'whites', name: 'All Whites', baseQty: 6, unitType: UnitType.kilo, basePrice: 319, excessPerUnit: 50, icon: '⚪️'),
  LaundryService(id: 'colored', name: 'Colored', baseQty: 6, unitType: UnitType.kilo, basePrice: 309, excessPerUnit: 48, icon: '🎨'),
  LaundryService(id: 'delicates', name: 'Delicates', baseQty: 3, unitType: UnitType.kilo, basePrice: 249, excessPerUnit: 55, icon: '🧼'),
  LaundryService(id: 'blankets', name: 'Blankets', baseQty: 1, unitType: UnitType.piece, basePrice: 199, excessPerUnit: 150, icon: '🛏️'),
];
