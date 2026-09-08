class DriverInfo {
  final String id;
  final String name;
  final String phone;
  final String? photoUrl;
  final String experienceYears;
  final double rating;

  const DriverInfo({
    required this.id,
    required this.name,
    required this.phone,
    this.photoUrl,
    this.experienceYears = '4+ Years',
    this.rating = 4.9,
  });

  factory DriverInfo.fromMap(Map<String, dynamic> map, String id) {
    return DriverInfo(
      id: id,
      name: map['driverName']?.toString() ?? map['name']?.toString() ?? 'Assigned Driver',
      phone: map['driverPhone']?.toString() ?? map['phone']?.toString() ?? '+92 300 1234567',
      photoUrl: map['driverPhoto']?.toString() ?? map['photoUrl']?.toString(),
      experienceYears: map['experience']?.toString() ?? '4+ Years',
      rating: (map['rating'] is num) ? (map['rating'] as num).toDouble() : 4.9,
    );
  }
}

class VehicleInfo {
  final String id;
  final String vehicleNo;
  final String model;
  final String color;
  final String routeName;
  final int capacity;

  const VehicleInfo({
    required this.id,
    required this.vehicleNo,
    required this.model,
    required this.color,
    required this.routeName,
    this.capacity = 16,
  });

  factory VehicleInfo.fromMap(Map<String, dynamic> map, String id) {
    return VehicleInfo(
      id: id,
      vehicleNo: map['vehicleNo']?.toString() ?? map['regNo']?.toString() ?? 'VAN-786',
      model: map['model']?.toString() ?? map['type']?.toString() ?? 'Toyota HiAce Grand Cabin',
      color: map['color']?.toString() ?? 'Silver White',
      routeName: map['routeName']?.toString() ?? map['title']?.toString() ?? 'Morning Route',
      capacity: int.tryParse(map['capacity']?.toString() ?? '16') ?? 16,
    );
  }
}

enum TripStage {
  notStarted,
  onTheWayToStop,
  studentBoarded,
  reachedSchool,
  departedSchool,
  droppedHome,
}

class TripStep {
  final String title;
  final String subtitle;
  final String time;
  final bool isCompleted;
  final bool isCurrent;

  const TripStep({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isCompleted,
    required this.isCurrent,
  });
}

class KidTransportDetails {
  final String kidId;
  final String kidName;
  final String pickupStop;
  final String morningPickupTime;
  final String afternoonDropTime;
  final bool isTakingVanToday;
  final String tripType; // 'pickup' or 'dropoff'
  final TripStage currentStage;
  final String etaText;
  final double distanceKm;
  final DriverInfo driver;
  final VehicleInfo vehicle;
  final List<TripStep> timelineSteps;
  final bool isAllocated;
  final String routeTitle;
  final double monthlyFare;

  const KidTransportDetails({
    required this.kidId,
    required this.kidName,
    required this.pickupStop,
    required this.morningPickupTime,
    required this.afternoonDropTime,
    required this.isTakingVanToday,
    required this.tripType,
    required this.currentStage,
    required this.etaText,
    required this.distanceKm,
    required this.driver,
    required this.vehicle,
    required this.timelineSteps,
    this.isAllocated = false,
    this.routeTitle = 'Morning Route',
    this.monthlyFare = 2500,
  });
}
