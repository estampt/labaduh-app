import 'package:flutter/material.dart';

class ServiceIconItem {
  const ServiceIconItem(this.key, this.icon, this.label);
  final String key;
  final IconData icon;
  final String label;
}

class ServiceIcons {
  static const items = <ServiceIconItem>[
  // Core laundry
  ServiceIconItem('wash_fold', Icons.local_laundry_service, 'Wash & Fold'),
  ServiceIconItem('wash_iron', Icons.iron, 'Wash & Iron'),
  ServiceIconItem('dry_cleaning', Icons.dry_cleaning, 'Dry Cleaning'),
  ServiceIconItem('iron_only', Icons.iron, 'Iron Only'),
  ServiceIconItem('wash_only', Icons.water_drop, 'Wash Only'),
  ServiceIconItem('fold_only', Icons.inventory_2, 'Fold Only'),
  ServiceIconItem('steam_press', Icons.whatshot, 'Steam / Press'),
  ServiceIconItem('hand_wash', Icons.back_hand, 'Hand Wash'),

  // Clothing categories
  ServiceIconItem('shirts', Icons.checkroom, 'Shirts'),
  ServiceIconItem('pants', Icons.checkroom, 'Pants / Jeans'),
  ServiceIconItem('uniforms', Icons.badge, 'Uniforms'),
  ServiceIconItem('delicates', Icons.auto_awesome, 'Delicates'),
  ServiceIconItem('kids_wear', Icons.child_care, 'Kids Wear'),
  ServiceIconItem('outerwear', Icons.cloud, 'Jackets / Coats'),
  ServiceIconItem('sportswear', Icons.sports_soccer, 'Sportswear'),

  // Home textiles
  ServiceIconItem('beddings', Icons.bed, 'Beddings'),
  ServiceIconItem('blankets', Icons.bedroom_baby, 'Blankets'),
  ServiceIconItem('pillows', Icons.bedtime, 'Pillows'),
  ServiceIconItem('comforter', Icons.king_bed, 'Comforter'),
  ServiceIconItem('towels', Icons.beach_access, 'Towels'),
  ServiceIconItem('curtains', Icons.curtains, 'Curtains'),
  ServiceIconItem('carpets', Icons.grid_view, 'Carpets / Rugs'),
  ServiceIconItem('sofa_covers', Icons.chair, 'Sofa Covers'),

  // Special items
  ServiceIconItem('stuffed_toys', Icons.toys, 'Stuffed Toys'),
  ServiceIconItem('shoes', Icons.hiking, 'Shoes'),
  ServiceIconItem('bags', Icons.shopping_bag, 'Bags'),
  ServiceIconItem('leather', Icons.style, 'Leather Care'),
  ServiceIconItem('sneakers', Icons.directions_run, 'Sneakers'),
  ServiceIconItem('caps', Icons.emoji_people, 'Caps / Hats'),
  ServiceIconItem('helmets', Icons.sports_motorsports, 'Helmet'),
  ServiceIconItem('wedding_dress', Icons.favorite, 'Gown / Formal'),
  ServiceIconItem('pets', Icons.pets, 'Pet Items'),

  // Cleaning & add-ons
  ServiceIconItem('sanitize', Icons.sanitizer, 'Sanitize'),
  ServiceIconItem('stain_removal', Icons.cleaning_services, 'Stain Removal'),
  ServiceIconItem('deep_clean', Icons.bubble_chart, 'Deep Clean'),
  ServiceIconItem('whitening', Icons.light_mode, 'Whitening'),
  ServiceIconItem('deodorize', Icons.air, 'Deodorize'),
  ServiceIconItem('fragrance', Icons.spa, 'Fragrance'),
  ServiceIconItem('eco', Icons.eco, 'Eco Wash'),
  ServiceIconItem('anti_bacterial', Icons.health_and_safety, 'Anti-bacterial'),
  ServiceIconItem('waterproof', Icons.umbrella, 'Waterproofing'),
  ServiceIconItem('repair', Icons.build, 'Minor Repair'),
  ServiceIconItem('buttons_zip', Icons.hardware, 'Buttons / Zipper'),

  // Speed / priority
  ServiceIconItem('express', Icons.bolt, 'Express'),
  ServiceIconItem('priority', Icons.star, 'Priority'),
  ServiceIconItem('premium', Icons.workspace_premium, 'Premium'),

  // Logistics / operations
  ServiceIconItem('pickup_delivery', Icons.local_shipping, 'Pickup & Delivery'),
  ServiceIconItem('pickup_only', Icons.store_mall_directory, 'Pickup Only'),
  ServiceIconItem('delivery_only', Icons.delivery_dining, 'Delivery Only'),
  ServiceIconItem('scheduled', Icons.schedule, 'Scheduled'),
  ServiceIconItem('same_day', Icons.today, 'Same-day'),
  ServiceIconItem('tracking', Icons.location_on, 'Tracking'),

  // Pricing types / misc useful
  ServiceIconItem('per_kg', Icons.scale, 'Per KG'),
  ServiceIconItem('per_piece', Icons.category, 'Per Piece'),
  ServiceIconItem('bundle', Icons.all_inbox, 'Bundle'),
  ServiceIconItem('discount', Icons.local_offer, 'Discount'),
  ServiceIconItem('subscription', Icons.card_membership, 'Subscription'),

  // Generic fallback
  ServiceIconItem('laundry', Icons.local_laundry_service, 'Laundry (Generic)'),
];


  static IconData resolve(String? key) {
    if (key == null || key.isEmpty) return Icons.local_laundry_service;
    return items.firstWhere((e) => e.key == key, orElse: () => items.last).icon;
  }
}
