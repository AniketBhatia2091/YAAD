import 'package:flutter/material.dart';

import '../../app/theme/color_tokens.dart';
import '../models/memory.dart';
import '../models/vault_category.dart';
import 'memory_repository.dart';

/// Concrete Mock Data Repository supplying realistic demonstration memories for YAAD.
class MockMemoryRepository implements MemoryRepository {
  final List<Memory> _memories = [
    // Attention items
    Memory(
      id: 'mem_1',
      title: 'Electricity Bill',
      documentType: 'Bill',
      categoryKey: 'bills',
      owner: 'Home',
      amount: 1847.0,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      dueDate: DateTime.now().add(const Duration(days: 2)),
      subtitle: '₹1,847 · Due in 2 days',
      actionTitle: 'Pay by Sep 5',
      isAttentionRequired: true,
      extractedText: 'BSES Yamuna Power Limited. Account: 102938475. Amount: ₹1847. Due Date: Sep 5.',
    ),
    Memory(
      id: 'mem_2',
      title: 'Bike Insurance',
      documentType: 'Insurance',
      categoryKey: 'vehicles',
      owner: 'Vehicle',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 30)),
      expiryDate: DateTime.now().add(const Duration(days: 12)),
      subtitle: 'Expires in 12 days',
      actionTitle: 'Renew before Sep 10',
      isAttentionRequired: true,
      extractedText: 'ICICI Lombard Comprehensive Two-Wheeler Policy No: 3005/1829384. Valid till Sep 10.',
    ),
    Memory(
      id: 'mem_3',
      title: "Mom's Medicine",
      documentType: 'Medical',
      categoryKey: 'medical',
      owner: 'Mom',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      subtitle: 'Reminder · 9:00 PM',
      actionTitle: '2 tablets',
      isAttentionRequired: true,
      extractedText: 'Thyronorm 50mcg. Take 2 tablets daily after dinner at 9:00 PM.',
    ),

    // Upcoming items
    Memory(
      id: 'mem_4',
      title: 'Earbuds Warranty',
      documentType: 'Warranty',
      categoryKey: 'warranties',
      owner: 'Self',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      updatedAt: DateTime.now().subtract(const Duration(days: 60)),
      expiryDate: DateTime.now().add(const Duration(days: 18)),
      subtitle: 'Warranty · 18 days remaining',
      actionTitle: 'Claim if needed',
      isAttentionRequired: false,
      extractedText: 'Boat Rockerz 450 Invoice No: INV-92837. 1 Year Warranty expiring soon.',
    ),
    Memory(
      id: 'mem_5',
      title: 'College Certificate',
      documentType: 'Certificate',
      categoryKey: 'education',
      owner: 'Self',
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
      updatedAt: DateTime.now().subtract(const Duration(days: 14)),
      dueDate: DateTime.now().add(const Duration(days: 20)),
      subtitle: 'Deadline · Sep 18',
      actionTitle: 'Submit application',
      isAttentionRequired: false,
      extractedText: 'Bachelor of Technology Degree Certificate Verification Portal deadline Sep 18.',
    ),
    Memory(
      id: 'mem_6',
      title: 'Vehicle PUC',
      documentType: 'PUC',
      categoryKey: 'vehicles',
      owner: 'Vehicle',
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      updatedAt: DateTime.now().subtract(const Duration(days: 90)),
      expiryDate: DateTime.now().add(const Duration(days: 30)),
      subtitle: 'PUC Expiry · Sep 28',
      actionTitle: 'Visit test center',
      isAttentionRequired: false,
      extractedText: 'Pollution Under Control Certificate No: DL01293847. Hero Splendor Plus.',
    ),

    // Recently remembered (IDs, etc.)
    Memory(
      id: 'mem_7',
      title: 'Aadhaar Card',
      documentType: 'ID',
      categoryKey: 'ids',
      owner: 'Self',
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 4)),
      subtitle: 'Government ID · XXXX 8921',
      actionTitle: 'Copy Number',
      isAttentionRequired: false,
      extractedText: 'Unique Identification Authority of India. Aadhaar: XXXX XXXX 8921. DOB: 14/08/1998.',
    ),
    Memory(
      id: 'mem_8',
      title: 'Bike RC',
      documentType: 'Vehicle',
      categoryKey: 'vehicles',
      owner: 'Vehicle',
      createdAt: DateTime.now().subtract(const Duration(hours: 18)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 18)),
      subtitle: 'Registration Certificate · DL 01 AB 1234',
      actionTitle: 'View Details',
      isAttentionRequired: false,
      extractedText: 'Transport Department NCT Delhi. RC: DL01AB1234. Owner: Aniket Bhatia.',
    ),
  ];

  @override
  Future<void> createMemory(Memory memory) async {
    _memories.insert(0, memory);
  }

  @override
  Future<Memory?> getMemoryById(String id) async {
    try {
      return _memories.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Memory>> getAttentionItems() async {
    return _memories.where((m) => m.isAttentionRequired).toList();
  }

  @override
  Future<List<Memory>> getUpcomingItems() async {
    return _memories.where((m) => !m.isAttentionRequired && (m.expiryDate != null || m.dueDate != null)).toList();
  }

  @override
  Future<List<Memory>> getRecentlyRemembered() async {
    final list = List<Memory>.from(_memories);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list.take(4).toList();
  }

  @override
  Future<List<Memory>> getAllMemories() async {
    return List.unmodifiable(_memories);
  }

  @override
  Future<List<VaultCategory>> getVaultCategories() async {
    return [
      VaultCategory(
        key: 'ids',
        title: 'IDs',
        description: 'Aadhaar · PAN · DL · Voter ID',
        icon: Icons.badge_outlined,
        backgroundColor: YaadColors.categoryIds,
        iconColor: YaadColors.categoryIdsIcon,
        count: _memories.where((m) => m.categoryKey == 'ids').length + 3,
      ),
      VaultCategory(
        key: 'bills',
        title: 'Bills & Payments',
        description: 'Electricity · Internet · Mobile · Water',
        icon: Icons.receipt_long_outlined,
        backgroundColor: YaadColors.categoryBills,
        iconColor: YaadColors.categoryBillsIcon,
        count: _memories.where((m) => m.categoryKey == 'bills').length + 5,
      ),
      VaultCategory(
        key: 'vehicles',
        title: 'Vehicles',
        description: 'RC · Insurance · PUC · Challans',
        icon: Icons.directions_car_outlined,
        backgroundColor: YaadColors.categoryVehicles,
        iconColor: YaadColors.categoryVehiclesIcon,
        count: _memories.where((m) => m.categoryKey == 'vehicles').length + 2,
      ),
      VaultCategory(
        key: 'medical',
        title: 'Medical',
        description: 'Prescriptions · Reports · Medicines',
        icon: Icons.health_and_safety_outlined,
        backgroundColor: YaadColors.categoryMedical,
        iconColor: YaadColors.categoryMedicalIcon,
        count: _memories.where((m) => m.categoryKey == 'medical').length + 4,
      ),
      VaultCategory(
        key: 'warranties',
        title: 'Warranties',
        description: 'Electronics · Appliances',
        icon: Icons.verified_outlined,
        backgroundColor: YaadColors.categoryWarranties,
        iconColor: YaadColors.categoryWarrantiesIcon,
        count: _memories.where((m) => m.categoryKey == 'warranties').length + 2,
      ),
      VaultCategory(
        key: 'education',
        title: 'Education & Jobs',
        description: 'Certificates · Applications · Offers',
        icon: Icons.school_outlined,
        backgroundColor: YaadColors.categoryEducation,
        iconColor: YaadColors.categoryEducationIcon,
        count: _memories.where((m) => m.categoryKey == 'education').length + 1,
      ),
    ];
  }

  @override
  Future<List<Memory>> searchMemories(String query) async {
    if (query.trim().isEmpty) return _memories;
    final q = query.toLowerCase();
    return _memories.where((m) {
      return m.title.toLowerCase().contains(q) ||
          m.documentType.toLowerCase().contains(q) ||
          m.owner.toLowerCase().contains(q) ||
          m.categoryKey.toLowerCase().contains(q) ||
          (m.extractedText?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Future<void> deleteMemory(String id) async {
    _memories.removeWhere((m) => m.id == id);
  }
}
