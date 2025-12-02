// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserSettingsAdapter extends TypeAdapter<UserSettings> {
  @override
  final int typeId = 3;

  @override
  UserSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSettings(
      name: fields[0] as String,
      email: fields[1] as String,
      monthlySalary: fields[2] as double,
      emergencyFundGoal: fields[3] as double?,
      budgetAllocations: (fields[4] as Map?)?.cast<String, double>(),
      currency: fields[5] as String,
      biometricEnabled: fields[6] as bool,
      backupEnabled: fields[7] as bool,
      lastBackupDate: fields[8] as DateTime?,
      customRules: (fields[9] as Map?)?.cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, UserSettings obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.monthlySalary)
      ..writeByte(3)
      ..write(obj.emergencyFundGoal)
      ..writeByte(4)
      ..write(obj.budgetAllocations)
      ..writeByte(5)
      ..write(obj.currency)
      ..writeByte(6)
      ..write(obj.biometricEnabled)
      ..writeByte(7)
      ..write(obj.backupEnabled)
      ..writeByte(8)
      ..write(obj.lastBackupDate)
      ..writeByte(9)
      ..write(obj.customRules);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
