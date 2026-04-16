import 'package:flutter/material.dart';
import '../providers/kids_provider.dart';
import '../../../core/theme/theme_colors.dart';

class PersonalityTabContent extends StatefulWidget {
  final KidData kid;
  
  const PersonalityTabContent({Key? key, required this.kid}) : super(key: key);

  @override
  State<PersonalityTabContent> createState() => _PersonalityTabContentState();
}

class _PersonalityTabContentState extends State<PersonalityTabContent> {
  bool _startAnimation = false;

  @override
  void initState() {
    super.initState();
    
    // Trigger animation shortly after build
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _startAnimation = true;
        });
      }
    });
  }

  // Personality Badge Logic mapping natively using Records Feature in Dart 3!
  ({String msg, Color color, IconData icon, String title}) _getPersonalityData(double score) {
    if (score >= 90) {
      return (
        msg: "Exceptional! 🌟 Your child demonstrates wonderful habits, excellent behavior, and outstanding personal care.",
        color: Colors.green.shade600,
        icon: Icons.star_rounded,
        title: "Role Model",
      );
    } else if (score >= 80) {
      return (
        msg: "Great Job! 😊 Your child continues to develop strong habits and a positive attitude. We're very pleased.",
        color: Colors.teal.shade500,
        icon: Icons.thumb_up_rounded,
        title: "Very Good",
      );
    } else if (score >= 70) {
      return (
        msg: "Doing Well! 👍 Your child is showing good progress in their personal development. Let's keep encouraging them.",
        color: ThemeColors.primaryPurple,
        icon: Icons.favorite_rounded,
        title: "Good Progress",
      );
    } else if (score >= 60) {
      return (
        msg: "On the Right Track. 🌱 Your child is learning, but gentle reminders about daily routines could be beneficial.",
        color: Colors.orange.shade500,
        icon: Icons.eco_rounded,
        title: "Developing",
      );
    } else if (score >= 40) {
      return (
        msg: "Room for Growth. 🤝 Your child might need a bit more guidance and support with their behavior and personal care.",
        color: Colors.deepOrange.shade500,
        icon: Icons.pan_tool_rounded,
        title: "Needs Guidance",
      );
    } else {
      return (
        msg: "Let's Connect. 💡 We'd love to partner with you to help support and improve your child's well-being and habits.",
        color: Colors.red.shade600,
        icon: Icons.handshake_rounded,
        title: "Action Required",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final healthScore = widget.kid.wellness['health']?.toDouble() ?? 80.0;
    final behaviorScore = widget.kid.wellness['behavior']?.toDouble() ?? 80.0;
    final hygieneScore = widget.kid.wellness['hygiene']?.toDouble() ?? 80.0;
    final averageScore = (healthScore + behaviorScore + hygieneScore) / 3.0;

    final badgeData = _getPersonalityData(averageScore);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Character & Well-being",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ThemeColors.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          _buildTraitsCard(healthScore, behaviorScore, hygieneScore),
          const SizedBox(height: 32),

          const Text(
            "Overall Insight",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ThemeColors.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoBadge(badgeData),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTraitsCard(double healthScore, double behaviorScore, double hygieneScore) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHorizontalBar("Health", healthScore, Icons.favorite_rounded, Colors.pink.shade400),
          const SizedBox(height: 24),
          _buildHorizontalBar("Behavior", behaviorScore, Icons.psychology_rounded, Colors.purple.shade400),
          const SizedBox(height: 24),
          _buildHorizontalBar("Hygiene", hygieneScore, Icons.clean_hands_rounded, Colors.lightBlue.shade400),
        ],
      ),
    );
  }

  Widget _buildHorizontalBar(String title, double score, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ThemeColors.primaryText,
                ),
              ),
            ),
            Text(
              '${score.toInt()}%',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ThemeColors.primaryText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Progress Bar
        Container(
          height: 10,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(5),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              return Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 1400),
                    curve: Curves.easeOutQuart,
                    height: 10,
                    width: _startAnimation ? (maxWidth * (score / 100)) : 0,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.6), color],
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBadge(({String msg, Color color, IconData icon, String title}) data) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: data.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: data.color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              color: data.color,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: data.color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.msg,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ThemeColors.primaryText,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
