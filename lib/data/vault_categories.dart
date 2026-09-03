import 'package:flutter/material.dart';

import '../app/theme/color_tokens.dart';
import 'models/vault_category.dart';

/// Static, non-mock definitions for YAAD's vault category taxonomy.
///
/// Counts are omitted here (defaulting to 0) and computed dynamically
/// from real stored memories in SQLite.
const List<VaultCategory> defaultVaultCategories = [
  VaultCategory(
    key: 'ids',
    title: 'IDs',
    description: 'Aadhaar · PAN · DL · Voter ID',
    icon: Icons.badge_outlined,
    backgroundColor: YaadColors.categoryIds,
    iconColor: YaadColors.categoryIdsIcon,
  ),
  VaultCategory(
    key: 'bills',
    title: 'Bills & Payments',
    description: 'Electricity · Internet · Mobile · Water',
    icon: Icons.receipt_long_outlined,
    backgroundColor: YaadColors.categoryBills,
    iconColor: YaadColors.categoryBillsIcon,
  ),
  VaultCategory(
    key: 'vehicles',
    title: 'Vehicles',
    description: 'RC · Insurance · PUC · Challans',
    icon: Icons.directions_car_outlined,
    backgroundColor: YaadColors.categoryVehicles,
    iconColor: YaadColors.categoryVehiclesIcon,
  ),
  VaultCategory(
    key: 'medical',
    title: 'Medical',
    description: 'Prescriptions · Reports · Medicines',
    icon: Icons.health_and_safety_outlined,
    backgroundColor: YaadColors.categoryMedical,
    iconColor: YaadColors.categoryMedicalIcon,
  ),
  VaultCategory(
    key: 'warranties',
    title: 'Warranties',
    description: 'Electronics · Appliances',
    icon: Icons.verified_outlined,
    backgroundColor: YaadColors.categoryWarranties,
    iconColor: YaadColors.categoryWarrantiesIcon,
  ),
  VaultCategory(
    key: 'education',
    title: 'Education & Jobs',
    description: 'Certificates · Applications · Offers',
    icon: Icons.school_outlined,
    backgroundColor: YaadColors.categoryEducation,
    iconColor: YaadColors.categoryEducationIcon,
  ),
];
