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
}
