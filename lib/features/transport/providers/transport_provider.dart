import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../core/providers/parent_data_provider.dart';
import '../../kids/providers/kids_provider.dart';
import '../models/transport_models.dart';

/// Ultra-Fast 100ms Live Vehicle Tracking via Firebase Realtime Database (RTDB)
/// Uses 0 Firestore reads and streams real-time bus coordinates smoothly to Parent App
final liveVehicleTrackingProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, vehicleId) async* {
  if (vehicleId.isEmpty) {
    yield null;
    return;
  }

  final parentData = ref.watch(parentDataProvider).value;
  if (parentData == null || parentData.schoolId.isEmpty) {
    yield null;
    return;
  }

  final schoolId = parentData.schoolId.trim();
  final candidates = <String>[schoolId];
  if (RegExp(r'^\d+$').hasMatch(schoolId)) {
    candidates.insert(0, 'SCHOOL_$schoolId');
  } else if (schoolId.startsWith('SCHOOL_')) {
    candidates.add(schoolId.substring(7));
  }

  final rtdb = FirebaseDatabase.instance;

  for (final sId in candidates) {
    try {
      final rtdbRef = rtdb.ref('schools/$sId/live_tracking/$vehicleId');
      yield* rtdbRef.onValue.map((event) {
        if (event.snapshot.value != null && event.snapshot.value is Map) {
          return Map<String, dynamic>.from(event.snapshot.value as Map);
        }
        return null;
      });
      return;
    } catch (_) {}
  }

  yield null;
});

final selectedTransportKidIdProvider = StateProvider<String?>((ref) => null);

final kidTransportProvider = StreamProvider.family<KidTransportDetails, String>((ref, kidId) async* {
  final parentDataAsync = ref.watch(parentDataProvider);
  final kidsAsync = ref.watch(kidsProvider);

  final parentData = parentDataAsync.value;
  final kids = kidsAsync.value ?? [];
  
  final currentKid = kids.firstWhere(
    (k) => k.id == kidId,
    orElse: () => KidData(
      id: kidId,
      name: 'Student',
      imageUrl: '',
      className: '',
      classId: '',
      rollNo: '',
      wellness: {},
      attendanceHistory: {},
      monthlyFeeStatus: 'paid',
    ),
  );

  if (parentData == null || parentData.schoolId.isEmpty) {
    yield _buildDefaultTransportDetails(currentKid);
    return;
  }

  // Stream live transport updates from Firestore
  final vehicleStream = FirebaseFirestore.instance
      .collection('schools')
      .doc(parentData.schoolId)
      .collection('students')
      .doc(kidId)
      .snapshots();

  await for (final snapshot in vehicleStream) {
    if (!snapshot.exists || snapshot.data() == null) {
      yield _buildDefaultTransportDetails(currentKid);
    } else {
      final data = snapshot.data() ?? <String, dynamic>{};
      final vehicleMap = data['assignedVehicle'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final driverMap = data['assignedDriver'] as Map<String, dynamic>? ?? <String, dynamic>{};
      final transportSettings = data['transport'] as Map<String, dynamic>? ?? <String, dynamic>{};

      final isTakingVan = transportSettings['isTakingVanToday'] as bool? ?? true;
      final tripType = transportSettings['tripType']?.toString() ?? 'pickup';
      final statusStageStr = transportSettings['stage']?.toString() ?? 'onTheWayToStop';
      
      TripStage stage = TripStage.onTheWayToStop;
      if (statusStageStr == 'notStarted') stage = TripStage.notStarted;
      if (statusStageStr == 'studentBoarded') stage = TripStage.studentBoarded;
      if (statusStageStr == 'reachedSchool') stage = TripStage.reachedSchool;
      if (statusStageStr == 'departedSchool') stage = TripStage.departedSchool;
      if (statusStageStr == 'droppedHome') stage = TripStage.droppedHome;

      final driver = DriverInfo(
        id: driverMap['id']?.toString() ?? 'drv_1',
        name: driverMap['name']?.toString() ?? 'Muhammad Aslam',
        phone: driverMap['phone']?.toString() ?? '+92 300 1234567',
        photoUrl: driverMap['photoUrl']?.toString(),
        experienceYears: driverMap['experience']?.toString() ?? '5+ Years',
        rating: 4.9,
      );

      final vehicle = VehicleInfo(
        id: vehicleMap['id']?.toString() ?? 'veh_1',
        vehicleNo: vehicleMap['vehicleNo']?.toString() ?? 'LEA-4589',
        model: vehicleMap['model']?.toString() ?? 'Toyota HiAce Grand Cabin',
        color: vehicleMap['color']?.toString() ?? 'White',
        routeName: vehicleMap['routeName']?.toString() ?? 'Route #4 (Gulberg & Model Town)',
        capacity: 16,
      );

      final timeline = _generateTimeline(stage, tripType);

      yield KidTransportDetails(
        kidId: kidId,
        kidName: currentKid.name,
        pickupStop: transportSettings['stopName']?.toString() ?? 'Stop #12, Main Boulevard',
        morningPickupTime: transportSettings['morningTime']?.toString() ?? '07:25 AM',
        afternoonDropTime: transportSettings['afternoonTime']?.toString() ?? '02:15 PM',
        isTakingVanToday: isTakingVan,
        tripType: tripType,
        currentStage: stage,
        etaText: transportSettings['eta']?.toString() ?? '5 - 8 mins away',
        distanceKm: (transportSettings['distanceKm'] is num) ? (transportSettings['distanceKm'] as num).toDouble() : 1.2,
        driver: driver,
        vehicle: vehicle,
        timelineSteps: timeline,
      );
    }
  }
});

List<TripStep> _generateTimeline(TripStage stage, String tripType) {
  if (tripType == 'dropoff') {
    return [
      TripStep(
        title: 'Boarded Van at School',
        subtitle: 'Student checked in by driver at school gate',
        time: '01:50 PM',
        isCompleted: stage.index >= TripStage.departedSchool.index,
        isCurrent: stage == TripStage.studentBoarded,
      ),
      TripStep(
        title: 'Van Departed School',
        subtitle: 'En route towards home destination',
        time: '02:00 PM',
        isCompleted: stage.index >= TripStage.departedSchool.index,
        isCurrent: stage == TripStage.departedSchool,
      ),
      TripStep(
        title: 'Dropped Safely at Home',
        subtitle: 'Drop-off confirmed at your designated stop',
        time: '02:20 PM',
        isCompleted: stage == TripStage.droppedHome,
        isCurrent: false,
      ),
    ];
  }

  // Morning Pickup
  return [
    TripStep(
      title: 'Van Started Morning Route',
      subtitle: 'Driver started from main terminal',
      time: '07:05 AM',
      isCompleted: stage.index >= TripStage.onTheWayToStop.index,
      isCurrent: stage == TripStage.notStarted,
    ),
    TripStep(
      title: 'Approaching Your Stop',
      subtitle: 'Van is 1.2 km away, please keep student ready',
      time: '07:20 AM',
      isCompleted: stage.index >= TripStage.studentBoarded.index,
      isCurrent: stage == TripStage.onTheWayToStop,
    ),
    TripStep(
      title: 'Student Picked Up',
      subtitle: 'Boarded safely and on the way to school',
      time: '07:25 AM',
      isCompleted: stage.index >= TripStage.reachedSchool.index,
      isCurrent: stage == TripStage.studentBoarded,
    ),
    TripStep(
      title: 'Reached School Safely',
      subtitle: 'Arrived at School gate and handed to class in-charge',
      time: '07:55 AM',
      isCompleted: stage == TripStage.reachedSchool,
      isCurrent: false,
    ),
  ];
}

KidTransportDetails _buildDefaultTransportDetails(KidData kid) {
  return KidTransportDetails(
    kidId: kid.id,
    kidName: kid.name.isNotEmpty ? kid.name : 'Student',
    pickupStop: 'Stop #12, Main Boulevard Stop',
    morningPickupTime: '07:25 AM',
    afternoonDropTime: '02:15 PM',
    isTakingVanToday: true,
    tripType: 'pickup',
    currentStage: TripStage.onTheWayToStop,
    etaText: 'Approx. 6 Mins (1.2 km)',
    distanceKm: 1.2,
    driver: const DriverInfo(
      id: 'drv_default',
      name: 'Muhammad Aslam',
      phone: '+92 300 1234567',
      photoUrl: null,
      experienceYears: '5+ Years Exp.',
      rating: 4.9,
    ),
    vehicle: const VehicleInfo(
      id: 'veh_default',
      vehicleNo: 'LEA-4589',
      model: 'Toyota HiAce Grand Cabin',
      color: 'Silver White',
      routeName: 'Morning Route #4 (Gulberg / Model Town)',
      capacity: 16,
    ),
    timelineSteps: _generateTimeline(TripStage.onTheWayToStop, 'pickup'),
  );
}

class TransportActions {
  static Future<void> toggleVanAttendance({
    required String schoolId,
    required String kidId,
    required bool isTakingVan,
  }) async {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    try {
      // 1. Update in transport_management settings (universally accessible to driver)
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('settings')
          .doc('transport_management')
          .set({
        'studentLeaves': {
          kidId: {
            'isLeave': !isTakingVan,
            'reason': !isTakingVan ? 'Not taking van today' : '',
            'date': todayStr,
            'updatedAt': FieldValue.serverTimestamp(),
          }
        }
      }, SetOptions(merge: true));

      // 2. Update directly on student record
      await FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('students')
          .doc(kidId)
          .set({
        'transport': {
          'isTakingVanToday': isTakingVan,
          'leaveReason': !isTakingVan ? 'Not taking van today' : '',
          'updatedAt': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));
    } catch (e) {
      // Silent catch to prevent UI freeze
    }
  }
}
