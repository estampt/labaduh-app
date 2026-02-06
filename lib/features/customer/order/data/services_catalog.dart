import '../domain/order_models.dart';

const servicesCatalog = <ServiceCatalogItem>[
  ServiceCatalogItem(
    id: 1,
    name: 'Wash & Fold',
    icon: '🧺',
    baseQty: 5,
    unitType: UnitType.kilo,
    basePrice: 60,
    excessPerUnit: 10,
  ),
  ServiceCatalogItem(
    id: 2,
    name: 'Dry Clean',
    icon: '🧼',
    baseQty: 3,
    unitType: UnitType.piece,
    basePrice: 90,
    excessPerUnit: 15,
  ),
  ServiceCatalogItem(
    id: 3,
    name: 'Wash Only',
    icon: '💧',
    baseQty: 5,
    unitType: UnitType.kilo,
    basePrice: 50,
    excessPerUnit: 8,
  ),
];
