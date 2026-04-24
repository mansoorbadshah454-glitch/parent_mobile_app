import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../kids/providers/kids_provider.dart';
import '../../kids/providers/academic_performance_provider.dart';
import '../../../core/theme/theme_colors.dart';
import '../../kids/widgets/shining_profile_avatar.dart';

class PerformanceUpdateScreen extends ConsumerStatefulWidget {
  final KidData kid;

  const PerformanceUpdateScreen({Key? key, required this.kid}) : super(key: key);

  @override
  ConsumerState<PerformanceUpdateScreen> createState() => _PerformanceUpdateScreenState();
}

class _PerformanceUpdateScreenState extends ConsumerState<PerformanceUpdateScreen> with SingleTickerProviderStateMixin {
  late AnimationController _bgAnimationController;

  @override
  void initState() {
    super.initState();
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    super.dispose();
  }

  String _translateSubject(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('english')) return 'انگریزی';
    if (s.contains('urdu')) return 'اردو';
    if (s.contains('math')) return 'ریاضی';
    if (s.contains('science')) return 'سائنس';
    if (s.contains('islam')) return 'اسلامیات';
    if (s.contains('social') || s == 'sst') return 'معاشرتی علوم';
    if (s.contains('computer') || s == 'it') return 'کمپیوٹر';
    if (s.contains('physic')) return 'فزکس';
    if (s.contains('chemist')) return 'کیمسٹری';
    if (s.contains('bio')) return 'بائیولوجی';
    if (s.contains('geo')) return 'جغرافیہ';
    if (s.contains('histor')) return 'تاریخ';
    if (s.contains('art') || s.contains('draw')) return 'ڈرائنگ';
    if (s.contains('quran') || s.contains('nazra')) return 'قرآن مجید';
    if (s.contains('arabic')) return 'عربی';
    if (s.contains('pak')) return 'مطالعہ پاکستان';
    return subject;
  }

  // Generate dynamic messages
  ({String eng, String urdu}) _generateMessages(String name, Map<String, double> subjects, double overallScore) {
    if (subjects.isEmpty) {
      return (
        eng: "$name has no academic data recorded yet. Please check back later.",
        urdu: "$name کا کوئی تعلیمی ڈیٹا ابھی تک ریکارڈ نہیں کیا گیا۔ براہ کرم بعد میں چیک کریں۔"
      );
    }

    List<String> outstanding = [];
    List<String> satisfactory = [];
    List<String> needsImprovement = [];
    List<String> critical = [];

    subjects.forEach((subject, score) {
      if (score >= 80) {
        outstanding.add(subject);
      } else if (score >= 50) {
        satisfactory.add(subject);
      } else if (score >= 30) {
        needsImprovement.add(subject);
      } else {
        critical.add(subject);
      }
    });

    List<String> bestGroup = outstanding.isNotEmpty ? outstanding : satisfactory;
    List<String> worstGroup = critical.isNotEmpty ? critical : needsImprovement;

    String bestStr = bestGroup.join(", ");
    String urduBestStr = bestGroup.map((s) => _translateSubject(s)).join("، ");

    String worstStr = worstGroup.join(", ");
    String urduWorstStr = worstGroup.map((s) => _translateSubject(s)).join("، ");

    String engIntro = "";
    String urduIntro = "";

    bool hasGood = bestGroup.isNotEmpty;
    bool hasBad = worstGroup.isNotEmpty;

    if (hasGood && !hasBad) {
      if (outstanding.isNotEmpty) {
        engIntro = "$name is showing exceptional skills in $bestStr.";
        urduIntro = "$name $urduBestStr میں غیر معمولی مہارت کا مظاہرہ کر رہے ہیں۔";
      } else {
        engIntro = "$name is making satisfactory progress in $bestStr.";
        urduIntro = "$name $urduBestStr میں تسلی بخش ترقی کر رہے ہیں۔";
      }
    } else if (!hasGood && hasBad) {
      if (critical.isNotEmpty) {
        engIntro = "$name is currently facing significant difficulties in $worstStr. Urgent focus is needed.";
        urduIntro = "$name کو فی الحال $urduWorstStr میں نمایاں مشکلات کا سامنا ہے۔ فوری توجہ کی ضرورت ہے۔";
      } else {
        engIntro = "$name needs to put more effort into $worstStr to improve grades.";
        urduIntro = "$name کو گریڈز بہتر بنانے کے لیے $urduWorstStr میں مزید محنت کی ضرورت ہے۔";
      }
    } else if (hasGood && hasBad) {
      String goodPart = outstanding.isNotEmpty 
          ? "is excelling in $bestStr" 
          : "is doing satisfactorily in $bestStr";
      String urduGoodPart = outstanding.isNotEmpty 
          ? "$urduBestStr میں شاندار کارکردگی دکھا رہے ہیں" 
          : "$urduBestStr میں مناسب کارکردگی دکھا رہے ہیں";

      String badPart = critical.isNotEmpty
          ? "immediate attention is required in $worstStr"
          : "some extra effort is needed in $worstStr";
      String urduBadPart = critical.isNotEmpty
          ? "$urduWorstStr میں فوری توجہ کی ضرورت ہے"
          : "$urduWorstStr میں مزید محنت کی ضرورت ہے";

      engIntro = "$name $goodPart. However, $badPart.";
      urduIntro = "$name $urduGoodPart۔ تاہم، $urduBadPart۔";
    }

    String engScoreMsg = "";
    String urduScoreMsg = "";

    if (overallScore >= 85) {
      engScoreMsg = "Outstanding achievement! Your child's dedication and hard work have resulted in exceptional academic success. We are incredibly proud of them!";
      urduScoreMsg = "نمایاں کامیابی! آپ کے بچے کی لگن اور محنت کے نتیجے میں غیر معمولی تعلیمی کامیابی حاصل ہوئی ہے۔ ہمیں ان پر بے حد فخر ہے!";
    } else if (overallScore >= 75) {
      engScoreMsg = "Excellent performance! Your child is displaying a strong grasp of the subjects. Keep motivating them to maintain this impressive momentum.";
      urduScoreMsg = "شاندار کارکردگی! آپ کا بچہ مضامین پر مضبوط گرفت دکھا رہا ہے۔ اس شاندار تسلسل کو برقرار رکھنے کے لیے ان کی حوصلہ افزائی کرتے رہیں۔";
    } else if (overallScore >= 65) {
      engScoreMsg = "Good effort! Your child is performing well overall. With a little more dedication and consistent practice, they can easily achieve excellent grades.";
      urduScoreMsg = "اچھی کوشش! آپ کا بچہ مجموعی طور پر اچھی کارکردگی دکھا رہا ہے۔ تھوڑی مزید لگن اور مستقل مشق سے وہ باآسانی شاندار گریڈز حاصل کر سکتے ہیں۔";
    } else if (overallScore >= 45) {
      engScoreMsg = "A satisfactory performance with room for growth. Encouraging your child to participate more actively in class will help them reach the next level.";
      urduScoreMsg = "کارکردگی تسلی بخش ہے مگر مزید بہتری کی گنجائش موجود ہے۔ بچے کی کلاس میں سرگرم شرکت کی حوصلہ افزائی انہیں اگلی سطح تک پہنچنے میں مدد دے گی۔";
    } else if (overallScore >= 30) {
      engScoreMsg = "Your child is showing basic understanding, but requires more focus to secure higher grades. Regular revision and a strict study schedule are recommended.";
      urduScoreMsg = "آپ کا بچہ بنیادی سمجھ بوجھ کا مظاہرہ کر رہا ہے، لیکن بہتر گریڈز کے لیے مزید توجہ درکار ہے۔ باقاعدہ دہرائی اور مطالعہ کا شیڈول تجویز کیا جاتا ہے۔";
    } else if (overallScore >= 20) {
      engScoreMsg = "There are significant areas needing improvement in your child's academics. Consistent effort and extra attention at home will help them achieve better results.";
      urduScoreMsg = "آپ کے بچے کی تعلیم میں بہتری کی کافی گنجائش ہے۔ گھر پر مسلسل محنت اور اضافی توجہ انہیں بہتر نتائج حاصل کرنے میں مدد دے گی۔";
    } else {
      engScoreMsg = "Your child's overall academic performance is currently below expectations. We highly recommend scheduling a meeting with the teachers to discuss a structured improvement plan.";
      urduScoreMsg = "آپ کے بچے کی مجموعی تعلیمی کارکردگی توقعات سے کم ہے۔ ہم اساتذہ کے ساتھ ملاقات کا مشورہ دیتے ہیں تاکہ بہتری کا منصوبہ بنایا جا سکے۔";
    }

    return (
      eng: "$engIntro\n\n$engScoreMsg",
      urdu: "$urduIntro\n\n$urduScoreMsg"
    );
  }

  @override
  Widget build(BuildContext context) {
    final performanceAsync = ref.watch(academicPerformanceProvider((
      id: widget.kid.id,
      classId: widget.kid.classId,
      className: widget.kid.className,
    )));

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: performanceAsync.when(
        data: (data) {
          final subjectScores = data?.academicScores ?? {};
          final homeworkScore = data?.homeworkAverage ?? 0.0;
          
          double overallScore = 0.0;
          if (subjectScores.isNotEmpty) {
            final double averageAcademic = subjectScores.values.reduce((a, b) => a + b) / subjectScores.length;
            overallScore = (averageAcademic * 0.6) + (homeworkScore * 0.4);
          }

          final msgs = _generateMessages(widget.kid.name.split(' ').first, subjectScores, overallScore);
          return Column(
            children: [
              // Header Section with Animated Background
              Stack(
                children: [
                  AnimatedBuilder(
                    animation: _bgAnimationController,
                    builder: (context, child) {
                      return ClipRect(
                        child: CustomPaint(
                          painter: BackgroundParticlePainter(
                            animation: _bgAnimationController.value,
                            overallScore: overallScore,
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.only(top: topPadding, bottom: 32),
                            decoration: BoxDecoration(
                            color: ThemeColors.primaryPurple.withOpacity(0.85),
                          ),
                          child: Column(
                            children: [
                              // Top Bar
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Performance Update",
                                        style: GoogleFonts.montserrat(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              // Profile Segment
                              Hero(
                                tag: 'kid_avatar_${widget.kid.id}',
                                child: ShiningProfileAvatar(
                                  imageUrl: widget.kid.imageUrl,
                                  radius: 50,
                                  strokeWidth: 4,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                widget.kid.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Class: ${widget.kid.className} | Roll No: ${widget.kid.rollNo}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white30),
                                ),
                                child: Text(
                                  "Overall Score: ${overallScore.toInt()}%",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              
              // Information Badges Section
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildDetailedInfoBadge(
                        msg: msgs.eng,
                        color: ThemeColors.primaryPurple,
                        icon: Icons.auto_graph_rounded,
                        title: "Performance Insights",
                      ),
                      const SizedBox(height: 20),
                      _buildDetailedInfoBadge(
                        msg: msgs.urdu,
                        color: Colors.teal.shade600,
                        icon: Icons.language_rounded,
                        title: "تفصیلی جائزہ",
                        isUrdu: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: ThemeColors.primaryPurple)),
        error: (error, stack) => Center(child: Text("Error loading data: $error", style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildDetailedInfoBadge({
    required String msg,
    required Color color,
    required IconData icon,
    required String title,
    bool isUrdu = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUrdu ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUrdu) ...[
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (isUrdu) ...[
                const SizedBox(width: 12),
                Icon(icon, color: color, size: 28),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Text(
            msg,
            textAlign: isUrdu ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              fontSize: 15,
              color: ThemeColors.primaryText,
              height: 1.6,
              fontFamily: isUrdu ? 'Jameel Noori Nastaleeq' : null, // If using custom font for Urdu
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Infinite Animated Background
class BackgroundParticlePainter extends CustomPainter {
  final double animation;
  final double overallScore;
  
  BackgroundParticlePainter({required this.animation, required this.overallScore});

  void _drawEmoji(Canvas canvas, String emoji, double x, double y, double size, double opacity) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(fontSize: size, color: Colors.white.withOpacity(opacity)),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42); // Fixed seed for stable particle positions

    List<String> emojis;
    int direction; // 1 = up, -1 = down
    int baseSpeed; // 1 = normal, 2 = fast, 3 = very fast
    double baseOpacity;

    // 10 Different Animations based on score (Strictly School/Academic Elements)
    if (overallScore >= 90) {
      emojis = ['🏆', '🎓', '🌟', '✨']; // Top performers: Trophies, graduation caps
      direction = 1;
      baseSpeed = 2;
      baseOpacity = 0.8;
    } else if (overallScore >= 80) {
      emojis = ['🏅', '🎉', '⭐', '👏']; // High performers: Medals, claps
      direction = 1;
      baseSpeed = 1;
      baseOpacity = 0.7;
    } else if (overallScore >= 70) {
      emojis = ['🚀', '💡', '🎒', '✨']; // Good performers: Rockets, backpacks
      direction = 1;
      baseSpeed = 1;
      baseOpacity = 0.6;
    } else if (overallScore >= 60) {
      emojis = ['📚', '✏️', '🎯', '📐']; // Steady: Books, rulers, pencils
      direction = 1;
      baseSpeed = 1;
      baseOpacity = 0.5;
    } else if (overallScore >= 50) {
      emojis = ['📖', '💼', '🧩', '📎']; // Average: Books, briefcases, paperclips
      direction = 1;
      baseSpeed = 1;
      baseOpacity = 0.4;
    } else if (overallScore >= 40) {
      emojis = ['🕰️', '⏳', '📋', '📝']; // Needs effort: Clocks, clipboards, memos
      direction = -1; // Slow sinking
      baseSpeed = 1;
      baseOpacity = 0.4;
    } else if (overallScore >= 30) {
      emojis = ['⏰', '📉', '⚠️', '📝']; // Warning: Alarm clocks, downward charts
      direction = -1;
      baseSpeed = 1;
      baseOpacity = 0.5;
    } else if (overallScore >= 20) {
      emojis = ['📉', '❗', '❌', '⭕']; // Poor: Charts, crosses, hollow circles
      direction = -1;
      baseSpeed = 2; // Fast sink
      baseOpacity = 0.6;
    } else if (overallScore >= 10) {
      emojis = ['❌', '❗', '🛑', '📉']; // Very poor: Crosses, stop signs
      direction = -1;
      baseSpeed = 2;
      baseOpacity = 0.7;
    } else {
      emojis = ['🆘', '🛑', '❌', '📉']; // Critical: SOS, stops, crosses
      direction = -1;
      baseSpeed = 3; // Very fast sink
      baseOpacity = 0.8;
    }

    double H = size.height + 160;

    // Draw 25 emoji particles for smooth performance
    for (int i = 0; i < 25; i++) {
      double x = random.nextDouble() * size.width;
      
      // Integer speed multipliers ensure exactly full screen loops when animation == 1.0
      int particleSpeedMultiplier = baseSpeed + random.nextInt(2); // Parallax effect
      
      double yOffset = animation * H * particleSpeedMultiplier * direction;
      double startY = random.nextDouble() * H;
      
      // True modulo for flawless infinite loop (handles negative values correctly)
      double y = ((startY - yOffset) % H + H) % H;
      y -= 80; // Shift up so elements disappear gracefully before wrapping

      double opacity = random.nextDouble() * 0.4 + (baseOpacity * 0.5);
      double emojiSize = random.nextDouble() * 15 + 15; // Size between 15 and 30

      // Pulse effect to make elements feel alive (integer cycles to prevent snapping)
      int pulseCycles = random.nextInt(3) + 2; 
      double pulsePhase = random.nextDouble() * pi * 2;
      double pulse = sin((animation * pi * 2 * pulseCycles) + pulsePhase);
      emojiSize += pulse * 4;

      String selectedEmoji = emojis[i % emojis.length];

      _drawEmoji(canvas, selectedEmoji, x, y, emojiSize, opacity);
    }
  }

  @override
  bool shouldRepaint(covariant BackgroundParticlePainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
