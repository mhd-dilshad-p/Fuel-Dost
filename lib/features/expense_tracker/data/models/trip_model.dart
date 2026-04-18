import 'package:hive/hive.dart';

/// Trip model for expense tracking, stored in Hive.
class TripModel extends HiveObject {
  final String id;
  final DateTime date;
  final double distance;
  final double fuelUsed;
  final double cost;
  final String? originName;
  final String? destinationName;
  final String fuelType;
  final String vehicleType;
  final double mileage;
  final double fuelPrice;
  final bool isRoundTrip;

  TripModel({
    required this.id,
    required this.date,
    required this.distance,
    required this.fuelUsed,
    required this.cost,
    this.originName,
    this.destinationName,
    required this.fuelType,
    required this.vehicleType,
    required this.mileage,
    required this.fuelPrice,
    required this.isRoundTrip,
  });

  double get costPerKm {
    final effectiveDistance = isRoundTrip ? distance * 2 : distance;
    if (effectiveDistance <= 0) return 0;
    return cost / effectiveDistance;
  }

  TripModel copyWith({
    String? id,
    DateTime? date,
    double? distance,
    double? fuelUsed,
    double? cost,
    String? originName,
    String? destinationName,
    String? fuelType,
    String? vehicleType,
    double? mileage,
    double? fuelPrice,
    bool? isRoundTrip,
  }) {
    return TripModel(
      id: id ?? this.id,
      date: date ?? this.date,
      distance: distance ?? this.distance,
      fuelUsed: fuelUsed ?? this.fuelUsed,
      cost: cost ?? this.cost,
      originName: originName ?? this.originName,
      destinationName: destinationName ?? this.destinationName,
      fuelType: fuelType ?? this.fuelType,
      vehicleType: vehicleType ?? this.vehicleType,
      mileage: mileage ?? this.mileage,
      fuelPrice: fuelPrice ?? this.fuelPrice,
      isRoundTrip: isRoundTrip ?? this.isRoundTrip,
    );
  }
}

/// Manual Hive TypeAdapter for TripModel (no code generation needed).
class TripModelAdapter extends TypeAdapter<TripModel> {
  @override
  final int typeId = 0;

  @override
  TripModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return TripModel(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      distance: fields[2] as double,
      fuelUsed: fields[3] as double,
      cost: fields[4] as double,
      originName: fields[5] as String?,
      destinationName: fields[6] as String?,
      fuelType: fields[7] as String,
      vehicleType: fields[11] as String? ?? 'Bike',
      mileage: fields[8] as double,
      fuelPrice: fields[9] as double,
      isRoundTrip: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TripModel obj) {
    writer.writeByte(12); // number of fields
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.date);
    writer.writeByte(2);
    writer.write(obj.distance);
    writer.writeByte(3);
    writer.write(obj.fuelUsed);
    writer.writeByte(4);
    writer.write(obj.cost);
    writer.writeByte(5);
    writer.write(obj.originName);
    writer.writeByte(6);
    writer.write(obj.destinationName);
    writer.writeByte(7);
    writer.write(obj.fuelType);
    writer.writeByte(8);
    writer.write(obj.mileage);
    writer.writeByte(9);
    writer.write(obj.fuelPrice);
    writer.writeByte(10);
    writer.write(obj.isRoundTrip);
    writer.writeByte(11);
    writer.write(obj.vehicleType);
  }
}
