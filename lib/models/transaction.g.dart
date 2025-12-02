// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 0;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaction(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      amount: fields[2] as double,
      description: fields[3] as String,
      merchant: fields[4] as String,
      rawText: fields[5] as String,
      category: fields[6] as TransactionCategory,
      confirmed: fields[7] as bool,
      isIncome: fields[8] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.merchant)
      ..writeByte(5)
      ..write(obj.rawText)
      ..writeByte(6)
      ..write(obj.category)
      ..writeByte(7)
      ..write(obj.confirmed)
      ..writeByte(8)
      ..write(obj.isIncome);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TransactionCategoryAdapter extends TypeAdapter<TransactionCategory> {
  @override
  final int typeId = 1;

  @override
  TransactionCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TransactionCategory.housing;
      case 1:
        return TransactionCategory.groceries;
      case 2:
        return TransactionCategory.utilities;
      case 3:
        return TransactionCategory.transport;
      case 4:
        return TransactionCategory.medical;
      case 5:
        return TransactionCategory.insurance;
      case 6:
        return TransactionCategory.dining;
      case 7:
        return TransactionCategory.entertainment;
      case 8:
        return TransactionCategory.shopping;
      case 9:
        return TransactionCategory.subscriptions;
      case 10:
        return TransactionCategory.travel;
      case 11:
        return TransactionCategory.income;
      case 12:
        return TransactionCategory.investments;
      case 13:
        return TransactionCategory.uncategorized;
      default:
        return TransactionCategory.housing;
    }
  }

  @override
  void write(BinaryWriter writer, TransactionCategory obj) {
    switch (obj) {
      case TransactionCategory.housing:
        writer.writeByte(0);
        break;
      case TransactionCategory.groceries:
        writer.writeByte(1);
        break;
      case TransactionCategory.utilities:
        writer.writeByte(2);
        break;
      case TransactionCategory.transport:
        writer.writeByte(3);
        break;
      case TransactionCategory.medical:
        writer.writeByte(4);
        break;
      case TransactionCategory.insurance:
        writer.writeByte(5);
        break;
      case TransactionCategory.dining:
        writer.writeByte(6);
        break;
      case TransactionCategory.entertainment:
        writer.writeByte(7);
        break;
      case TransactionCategory.shopping:
        writer.writeByte(8);
        break;
      case TransactionCategory.subscriptions:
        writer.writeByte(9);
        break;
      case TransactionCategory.travel:
        writer.writeByte(10);
        break;
      case TransactionCategory.income:
        writer.writeByte(11);
        break;
      case TransactionCategory.investments:
        writer.writeByte(12);
        break;
      case TransactionCategory.uncategorized:
        writer.writeByte(13);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BudgetTypeAdapter extends TypeAdapter<BudgetType> {
  @override
  final int typeId = 2;

  @override
  BudgetType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BudgetType.needs;
      case 1:
        return BudgetType.wants;
      case 2:
        return BudgetType.savings;
      default:
        return BudgetType.needs;
    }
  }

  @override
  void write(BinaryWriter writer, BudgetType obj) {
    switch (obj) {
      case BudgetType.needs:
        writer.writeByte(0);
        break;
      case BudgetType.wants:
        writer.writeByte(1);
        break;
      case BudgetType.savings:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
