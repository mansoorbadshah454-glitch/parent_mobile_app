import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/providers/parent_data_provider.dart';
import '../../kids/providers/kids_provider.dart';
import '../models/transport_models.dart';
import '../providers/transport_provider.dart';

class PickupDropoffScreen extends ConsumerStatefulWidget {
  const PickupDropoffScreen({super.key});

  @override
  ConsumerState<PickupDropoffScreen> createState() => _PickupDropoffScreenState();
}

class _PickupDropoffScreenState extends ConsumerState<PickupDropoffScreen>
    with SingleTickerProviderStateMixin {
  String _selectedKidId = '';
  String _activeShift = 'morning'; // 'morning' (Pickup) or 'afternoon' (Drop-off)
  late AnimationController _demoAnimController;
  late Animation<double> _vanAnimation;
  bool _isPlayingDemo = false;

  @override
  void initState() {
    super.initState();
    _demoAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    _vanAnimation = CurvedAnimation(
      parent: _demoAnimController,
      curve: Curves.easeInOut,
    );

    _demoAnimController.addListener(() {
      setState(() {});
    });

    _demoAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isPlayingDemo = false;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final kids = ref.read(kidsProvider).value ?? [];
      if (kids.isNotEmpty) {
        setState(() {
          _selectedKidId = kids.first.id;
        });
      }
    });
  }

  @override
  void dispose() {
    _demoAnimController.dispose();
    super.dispose();
  }

  void _toggleDemoSimulation() {
    if (_demoAnimController.isAnimating) {
      _demoAnimController.stop();
      setState(() {
        _isPlayingDemo = false;
      });
    } else {
      if (_demoAnimController.isCompleted) {
        _demoAnimController.reset();
      }
      _demoAnimController.forward();
      setState(() {
        _isPlayingDemo = true;
      });
    }
  }

  Future<void> _callPhone(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri);
      }
    } catch (e) {
      try {
        await launchUrl(uri);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open phone dialer for: $phone'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    var cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('0') && cleanPhone.length == 11) {
      cleanPhone = '92${cleanPhone.substring(1)}';
    }

    final webUri = Uri.parse('https://wa.me/$cleanPhone');
    final nativeUri = Uri.parse('whatsapp://send?phone=$cleanPhone');

    try {
      final launched = await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        final webLaunched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
        if (!webLaunched) {
          await launchUrl(webUri, mode: LaunchMode.platformDefault);
        }
      }
    } catch (e) {
      try {
        final webLaunched = await launchUrl(webUri, mode: LaunchMode.externalApplication);
        if (!webLaunched) {
          await launchUrl(webUri, mode: LaunchMode.platformDefault);
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open WhatsApp. Driver number: $phone'),
              backgroundColor: ThemeColors.primaryPurple,
              action: SnackBarAction(
                label: 'Call Instead',
                textColor: Colors.amber,
                onPressed: () => _callPhone(phone),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kidsAsync = ref.watch(kidsProvider);
    final kids = kidsAsync.value ?? [];

    if (kids.isNotEmpty && _selectedKidId.isEmpty) {
      _selectedKidId = kids.first.id;
    }

    final transportAsync = _selectedKidId.isNotEmpty
        ? ref.watch(kidTransportProvider(_selectedKidId))
        : null;

    return Scaffold(
      backgroundColor: ThemeColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: ThemeColors.primaryPurple,
        elevation: 0,
        title: Text(
          'Pickup & Drop-off',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            tooltip: 'Transport Rules',
            onPressed: () => _showTransportInfoDialog(context),
          ),
        ],
      ),
      body: kids.isEmpty
          ? const Center(
              child: Text(
                'No student registered under your account.',
                style: TextStyle(color: ThemeColors.secondaryText),
              ),
            )
          : Column(
              children: [
                // 1. Kids Selector Tab Bar
                if (kids.length > 1) _buildKidsSelector(kids),

                // 2. Main Scrollable Content
                Expanded(
                  child: transportAsync == null
                      ? const Center(child: CircularProgressIndicator())
                      : transportAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, stack) => Center(
                            child: Text(
                              'Failed to load transport details.',
                              style: GoogleFonts.montserrat(color: Colors.red),
                            ),
                          ),
                          data: (details) => details.isAllocated
                              ? _buildMainContent(details)
                              : _buildNotEnrolledState(details),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildNotEnrolledState(KidTransportDetails details) {
    final parentData = ref.watch(parentDataProvider).value;
    final schoolPhone = parentData?.phone ?? '';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: ThemeColors.primaryPurple.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: ThemeColors.primaryPurple.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.directions_bus_outlined,
                size: 48,
                color: ThemeColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Transport Service Not Enrolled',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ThemeColors.primaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${details.kidName.isNotEmpty ? details.kidName : "Your child"} is not currently registered for the school transport service. If you would like to avail daily van/bus pickup and drop-off, please contact the school administration office.',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: ThemeColors.secondaryText,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 20, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Want to register for School Bus?',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: ThemeColors.primaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contact school front desk or visit the administration office during official timings to select your route and stop.',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: ThemeColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (schoolPhone.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () => _callPhone(schoolPhone),
                icon: const Icon(Icons.phone, size: 18),
                label: const Text('Contact School Office'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeColors.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKidsSelector(List<KidData> kids) {
    final activeId = kids.any((k) => k.id == _selectedKidId) ? _selectedKidId : kids.first.id;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school_outlined, size: 16, color: ThemeColors.primaryPurple),
              const SizedBox(width: 6),
              Text(
                'Select Student:',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ThemeColors.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: activeId,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: ThemeColors.primaryPurple, size: 24),
                borderRadius: BorderRadius.circular(16),
                dropdownColor: Colors.white,
                items: kids.map((kid) {
                  return DropdownMenuItem<String>(
                    value: kid.id,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: ThemeColors.lightPurple.withOpacity(0.4),
                          backgroundImage: kid.imageUrl.isNotEmpty
                              ? CachedNetworkImageProvider(kid.imageUrl)
                              : null,
                          child: kid.imageUrl.isEmpty
                              ? const Icon(Icons.person, size: 18, color: ThemeColors.primaryPurple)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                kid.name,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  color: ThemeColors.primaryText,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                kid.className.isNotEmpty && kid.className != 'N/A'
                                    ? 'Class: ${kid.className} • Roll #${kid.rollNo}'
                                    : 'Student ID: ${kid.id}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  color: ThemeColors.secondaryText,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null && val != _selectedKidId) {
                    setState(() {
                      _selectedKidId = val;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(KidTransportDetails details) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(kidTransportProvider(_selectedKidId));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // A. Live Status & ETA Card
            _buildLiveStatusCard(details),
            const SizedBox(height: 16),

            // B. Visual Live Route & Map Simulation
            _buildRouteMapCard(details),
            const SizedBox(height: 16),

            // C. Driver & Vehicle Details Card
            _buildDriverAndVehicleCard(details),
            const SizedBox(height: 16),

            // D. Trip Timeline Steps
            _buildTripTimelineCard(details),
            const SizedBox(height: 16),

            // E. Quick Actions: "Not taking van today" Toggle & Emergency
            _buildQuickActionsCard(details),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveStatusCard(KidTransportDetails details) {
    final isMorning = _activeShift == 'morning';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ThemeColors.primaryPurple, ThemeColors.deepPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.primaryPurple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00E676),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LIVE TRACKING',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                isMorning ? '🌅 Morning Shift' : '🌇 Afternoon Shift',
                style: GoogleFonts.montserrat(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            details.isTakingVanToday
                ? (isMorning ? 'Van is Approaching Your Stop' : 'Van Departed from School')
                : 'Marked Absent from Van Today',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            details.isTakingVanToday
                ? (isMorning
                    ? 'Estimated Arrival at Stop in ~6 mins'
                    : 'Estimated Drop-off at Home in ~12 mins')
                : 'Student will commute independently or with parents.',
            style: GoogleFonts.montserrat(
              color: Colors.white.withOpacity(0.85),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isMorning ? details.pickupStop : 'Drop-off: ${details.pickupStop}',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  isMorning ? details.morningPickupTime : details.afternoonDropTime,
                  style: GoogleFonts.montserrat(
                    color: Colors.amberAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteMapCard(KidTransportDetails details) {
    final animVal = _vanAnimation.value;
    final currentProgress = _demoAnimController.isAnimating || _demoAnimController.isCompleted
        ? animVal
        : 0.45; // Default middle position when idle

    final calculatedDistance = (1.5 * (1.0 - (currentProgress * 0.9))).clamp(0.1, 1.5);
    final distanceText = _demoAnimController.isCompleted
        ? 'Arrived at Stop'
        : '${calculatedDistance.toStringAsFixed(1)} km to Stop';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.map_rounded, color: ThemeColors.primaryPurple, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Live Route Map',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: ThemeColors.primaryText,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _demoAnimController.isCompleted ? Colors.purple.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _demoAnimController.isCompleted ? Colors.purple.shade200 : Colors.green.shade200,
                  ),
                ),
                child: Text(
                  distanceText,
                  style: GoogleFonts.montserrat(
                    color: _demoAnimController.isCompleted ? Colors.purple.shade800 : Colors.green.shade800,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Visual Simulation Map Container with LayoutBuilder
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD0DDEB)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final roadLeft = 45.0;
                final roadRight = totalWidth - 45.0;
                final roadDistance = roadRight - roadLeft;
                final vanX = roadLeft + (currentProgress * roadDistance) - 22;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Road Background Track
                    Positioned(
                      left: roadLeft,
                      right: 45.0,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    // Active Traveled Road
                    Positioned(
                      left: roadLeft,
                      width: (currentProgress * roadDistance).clamp(0.0, roadDistance),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: ThemeColors.primaryPurple,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    // Landmark 1: School Start
                    Positioned(
                      left: 14,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: ThemeColors.deepPurple,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.school, color: Colors.white, size: 18),
                          ),
                          const SizedBox(height: 4),
                          Text('School', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    // Landmark 2: Home Stop
                    Positioned(
                      right: 14,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.home, color: Colors.white, size: 18),
                          ),
                          const SizedBox(height: 4),
                          Text('Your Stop', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    // Animated Moving Van Marker
                    Positioned(
                      left: vanX.clamp(10.0, totalWidth - 60.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(_isPlayingDemo ? 0.6 : 0.3),
                                  blurRadius: _isPlayingDemo ? 12 : 6,
                                  spreadRadius: _isPlayingDemo ? 3 : 1,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.directions_bus, color: Colors.white, size: 20),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                            ),
                            child: Text(
                              details.vehicle.vehicleNo,
                              style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Interactive Simulation Controller Button
          InkWell(
            onTap: _toggleDemoSimulation,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: _isPlayingDemo
                    ? Colors.amber.shade50
                    : ThemeColors.lightPurple.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isPlayingDemo ? Colors.amber.shade300 : ThemeColors.lightPurple,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isPlayingDemo
                        ? Icons.pause_circle_filled_rounded
                        : (_demoAnimController.isCompleted
                            ? Icons.replay_circle_filled_rounded
                            : Icons.play_circle_filled_rounded),
                    color: _isPlayingDemo ? Colors.amber.shade900 : ThemeColors.primaryPurple,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _isPlayingDemo
                            ? 'Simulation Running (Tap to Pause)'
                            : (_demoAnimController.isCompleted
                                ? 'Replay Van Movement Demo'
                                : 'Play Live Van Movement Demo'),
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _isPlayingDemo ? Colors.amber.shade900 : ThemeColors.primaryPurple,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverAndVehicleCard(KidTransportDetails details) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Driver & Vehicle Details',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: ThemeColors.primaryText,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Driver Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: ThemeColors.lightPurple,
                backgroundImage: details.driver.photoUrl != null
                    ? CachedNetworkImageProvider(details.driver.photoUrl!)
                    : null,
                child: details.driver.photoUrl == null
                    ? const Icon(Icons.person, size: 32, color: ThemeColors.primaryPurple)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      details.driver.name,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: ThemeColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${details.driver.rating}',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: ThemeColors.primaryText,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•  ${details.driver.experienceYears}',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: ThemeColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${details.vehicle.model} (${details.vehicle.color})',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: ThemeColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              // License Plate Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black26),
                ),
                child: Text(
                  details.vehicle.vehicleNo,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 10),

          // Contact Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _callPhone(details.driver.phone),
                  icon: const Icon(Icons.phone, size: 18, color: Colors.white),
                  label: Text(
                    'Call Driver',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openWhatsApp(details.driver.phone),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18, color: ThemeColors.primaryPurple),
                  label: Text(
                    'WhatsApp',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: ThemeColors.primaryPurple,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: ThemeColors.primaryPurple),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<TripStep> _getStepsForCurrentShift(KidTransportDetails details) {
    if (_activeShift == 'afternoon') {
      return [
        TripStep(
          title: 'Boarded Van at School',
          subtitle: 'Student checked in by driver at school gate',
          time: '01:50 PM',
          isCompleted: true,
          isCurrent: false,
        ),
        TripStep(
          title: 'Van Departed School',
          subtitle: 'En route towards your destination stop',
          time: '02:00 PM',
          isCompleted: true,
          isCurrent: false,
        ),
        TripStep(
          title: 'Approaching Your Stop',
          subtitle: 'Van is nearby, please be at designated drop stop',
          time: details.afternoonDropTime,
          isCompleted: false,
          isCurrent: true,
        ),
        TripStep(
          title: 'Dropped Safely at Home',
          subtitle: 'Student received and trip completed',
          time: '02:25 PM',
          isCompleted: false,
          isCurrent: false,
        ),
      ];
    }

    return [
      TripStep(
        title: 'Van Started Morning Route',
        subtitle: 'Driver started from main terminal',
        time: '07:05 AM',
        isCompleted: true,
        isCurrent: false,
      ),
      TripStep(
        title: 'Approaching Your Stop',
        subtitle: 'Van is 1.2 km away, please keep student ready',
        time: details.morningPickupTime,
        isCompleted: false,
        isCurrent: true,
      ),
      TripStep(
        title: 'Student Picked Up',
        subtitle: 'Boarded safely and on the way to school',
        time: '07:30 AM',
        isCompleted: false,
        isCurrent: false,
      ),
      TripStep(
        title: 'Reached School Safely',
        subtitle: 'Arrived at School gate and handed to class in-charge',
        time: '07:55 AM',
        isCompleted: false,
        isCurrent: false,
      ),
    ];
  }

  Widget _buildTripTimelineCard(KidTransportDetails details) {
    final steps = _getStepsForCurrentShift(details);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trip Checkpoints',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: ThemeColors.primaryText,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _activeShift == 'morning' ? 'Home ➔ School' : 'School ➔ Home',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ThemeColors.primaryPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Interactive Shift Switcher (Morning Pickup vs Afternoon Dropoff)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _activeShift = 'morning';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                      decoration: BoxDecoration(
                        color: _activeShift == 'morning' ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _activeShift == 'morning'
                            ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wb_sunny_rounded, size: 15, color: Colors.orange),
                          const SizedBox(width: 5),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Morning (Pickup)',
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: _activeShift == 'morning' ? FontWeight.w700 : FontWeight.w500,
                                  color: _activeShift == 'morning' ? ThemeColors.primaryPurple : ThemeColors.secondaryText,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _activeShift = 'afternoon';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                      decoration: BoxDecoration(
                        color: _activeShift == 'afternoon' ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _activeShift == 'afternoon'
                            ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.home_rounded, size: 15, color: ThemeColors.deepPurple),
                          const SizedBox(width: 5),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Afternoon (Drop-off)',
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: _activeShift == 'afternoon' ? FontWeight.w700 : FontWeight.w500,
                                  color: _activeShift == 'afternoon' ? ThemeColors.primaryPurple : ThemeColors.secondaryText,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Stepper List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final step = steps[index];
              final isLast = index == steps.length - 1;

              Color indicatorColor = Colors.grey.shade300;
              IconData icon = Icons.circle;

              if (step.isCompleted) {
                indicatorColor = const Color(0xFF10B981);
                icon = Icons.check_circle_rounded;
              } else if (step.isCurrent) {
                indicatorColor = ThemeColors.primaryPurple;
                icon = Icons.radio_button_checked_rounded;
              }

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline Line & Dot
                    Column(
                      children: [
                        Icon(icon, size: 20, color: indicatorColor),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: step.isCompleted ? const Color(0xFF10B981) : Colors.grey.shade300,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    // Content
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    step.title,
                                    style: GoogleFonts.montserrat(
                                      fontWeight: step.isCurrent || step.isCompleted
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: 14,
                                      color: step.isCurrent
                                          ? ThemeColors.primaryPurple
                                          : ThemeColors.primaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    step.subtitle,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      color: ThemeColors.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              step.time,
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ThemeColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(KidTransportDetails details) {
    final parentData = ref.watch(parentDataProvider).value;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Parent Controls',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: ThemeColors.primaryText,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: details.isTakingVanToday ? const Color(0xFFF8FAFC) : Colors.red.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: details.isTakingVanToday ? const Color(0xFFE2E8F0) : Colors.red.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  details.isTakingVanToday ? Icons.no_crash_outlined : Icons.cancel_outlined,
                  color: details.isTakingVanToday ? ThemeColors.primaryPurple : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Not Taking Van Today',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: ThemeColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Notify driver early so they do not wait at your gate.',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: ThemeColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: !details.isTakingVanToday,
                  activeColor: Colors.red,
                  onChanged: (isAbsent) async {
                    if (parentData != null) {
                      await TransportActions.toggleVanAttendance(
                        schoolId: parentData.schoolId,
                        kidId: _selectedKidId,
                        isTakingVan: !isAbsent,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isAbsent
                                  ? 'Alert sent: Student marked absent from van today.'
                                  : 'Van pickup status restored.',
                            ),
                            backgroundColor: isAbsent ? Colors.red.shade700 : ThemeColors.primaryPurple,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTransportInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.directions_bus, color: ThemeColors.primaryPurple),
            const SizedBox(width: 10),
            Text('Transport Policy', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoPoint('Please reach the designated stop 5 minutes before scheduled pickup time.'),
            const SizedBox(height: 8),
            _buildInfoPoint('If student is not using the van, toggle "Not Taking Van Today" before 06:45 AM.'),
            const SizedBox(height: 8),
            _buildInfoPoint('For route changes or driver emergencies, contact school transport admin.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood', style: TextStyle(color: ThemeColors.primaryPurple, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4.0),
          child: Icon(Icons.check_circle_outline, size: 16, color: ThemeColors.primaryPurple),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.montserrat(fontSize: 13, color: ThemeColors.primaryText),
          ),
        ),
      ],
    );
  }
}
