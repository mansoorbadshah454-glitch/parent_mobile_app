import 'package:flutter/material.dart';

class FeeCalculatorService {
  /// Calculates the reliable payment score based on rule:
  /// 1st to 3rd: 100% to 80%
  /// 4th to 6th: 70% to 50%
  /// 7th to 10th: < 50% down to 30%
  /// 11th to 15th: linearly down to 0%
  /// > 15th: 0%
  static double calculateMonthlyScore(int dayPaid) {
    if (dayPaid <= 0) return 0.0; // unpaid or invalid
    
    if (dayPaid >= 1 && dayPaid <= 3) {
      return 110.0 - (10.0 * dayPaid);
    } 
    else if (dayPaid >= 4 && dayPaid <= 6) {
      return 110.0 - (10.0 * dayPaid);
    } 
    else if (dayPaid >= 7 && dayPaid <= 10) {
      // (10, 30) (6, 50) -> slope -5
      return 80.0 - (5.0 * dayPaid);
    } 
    else if (dayPaid >= 11 && dayPaid <= 15) {
      // (10, 30) (15, 0) -> slope -6
      double score = 90.0 - (6.0 * dayPaid);
      return score < 0 ? 0.0 : score;
    } 
    else {
      return 0.0; // Day 16+
    }
  }

  /// Takes a list of days paid and calculates the circular gauge overall average score
  static double calculateAggregateScore(List<int> pastPaymentDays) {
    if (pastPaymentDays.isEmpty) return 0.0;
    
    double total = 0.0;
    for (var day in pastPaymentDays) {
      total += calculateMonthlyScore(day);
    }
    
    return total / pastPaymentDays.length;
  }

  /// Returns a custom message for the given payment reliability score
  static String getReliabilityMessage(double score) {
    if (score >= 80) return "Excellent consistency! Your prompt payments help us maintain high educational standards.";
    if (score >= 60) return "Good standing. Thank you for your continued commitment to timely fee clearances.";
    if (score >= 40) return "Fair standing. Clearing dues within the first week of the month will improve your reliability.";
    return "Attention needed. Please ensure timely payments to avoid late fees and maintain a healthy standing.";
  }

  /// Returns the UI color for the given payment reliability score
  static Color getReliabilityColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  /// Returns the UI icon for the given payment reliability score
  static IconData getReliabilityIcon(double score) {
    if (score >= 80) return Icons.verified_rounded;
    if (score >= 60) return Icons.thumb_up_rounded;
    if (score >= 40) return Icons.info_outline_rounded;
    return Icons.warning_amber_rounded;
  }

  /// Returns the UI label for the given payment reliability score
  static String getReliabilityLabel(double score) {
    if (score >= 80) return "Excellent";
    if (score >= 60) return "Good";
    if (score >= 40) return "Fair";
    return "Bad";
  }
}
