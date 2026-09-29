import 'package:audira_receipt/core/constants/app_constants.dart';

class ThermalPrinter {
  final int? id;
  final String name;
  final String macAddress;
  final String paperSize;
  final bool isDefault;
  final DateTime createdAt;
  final bool isConnected;
  final bool isBonded;

  ThermalPrinter({
    this.id,
    required this.name,
    required this.macAddress,
    this.paperSize = AppConstants.paper58mm,
    this.isDefault = false,
    DateTime? createdAt,
    this.isConnected = false,
    this.isBonded = true,
  }) : createdAt = createdAt ?? DateTime.now();

  ThermalPrinter copyWith({
    int? id,
    String? name,
    String? macAddress,
    String? paperSize,
    bool? isDefault,
    DateTime? createdAt,
    bool? isConnected,
    bool? isBonded,
  }) {
    return ThermalPrinter(
      id: id ?? this.id,
      name: name ?? this.name,
      macAddress: macAddress ?? this.macAddress,
      paperSize: paperSize ?? this.paperSize,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      isConnected: isConnected ?? this.isConnected,
      isBonded: isBonded ?? this.isBonded,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'mac_address': macAddress,
      'paper_size': paperSize,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ThermalPrinter.fromMap(Map<String, dynamic> map) {
    return ThermalPrinter(
      id: map['id'] as int?,
      name: map['name'] as String? ?? 'Bluetooth Printer',
      macAddress: map['mac_address'] as String,
      paperSize: map['paper_size'] as String? ?? AppConstants.paper58mm,
      isDefault: (map['is_default'] as int? ?? 0) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }
}
