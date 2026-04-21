import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TranslationHelper {
  // Dictionary mapping english standard texts to Urdu equivalents
  static final Map<String, String> _dictionary = {
    // --- Academic Badges ---
    "Excellent Standing": "شاندار کارکردگی",
    "Very Good": "بہت اچھا",
    "Good Progress": "اچھی ترقی",
    "Fair": "درمیانہ",
    "Needs Attention": "توجہ کی ضرورت ہے",
    "Action Required": "کارروائی درکار ہے",

    "Outstanding! 🎉 Your child is performing exceptionally well in both academics and homework. We are proud of their progress!": 
        "شاندار! 🎉 آپ کا بچہ تعلیم اور ہوم ورک دونوں میں غیر معمولی کارکردگی دکھا رہا ہے۔ ہمیں ان کی ترقی پر فخر ہے!",
    "Excellent work! 🌟 Your child is showing great dedication. Keep encouraging them to maintain this high standard.":
        "بہت عمدہ! 🌟 آپ کا بچہ زبردست لگن دکھا رہا ہے۔ اس اعلیٰ معیار کو برقرار رکھنے کے لیے ان کی حوصلہ افزائی کریں۔",
    "Doing Good! 👍 Your child is on the right track. A little extra focus could help them reach the top scores!":
        "اچھا کام! 👍 آپ کا بچہ صحیح راستے پر ہے۔ تھوڑی مزید توجہ انہیں ٹاپ سکور تک پہنچنے میں مدد دے سکتی ہے!",
    "Fair performance. 📚 Your child's basics are clear, but allocating more review time for homework will yield better results.":
        "درمیانی کارکردگی۔ 📚 آپ کے بچے کے تصورات واضح ہیں، لیکن ہوم ورک کے لیے مزید وقت نکالنے سے بہتر نتائج حاصل ہوں گے۔",
    "Needs attention. ⚠️ Your child is scoring below average. Let's work together to identify areas where they need help.":
        "توجہ طلب۔ ⚠️ آپ کا بچہ اوسط سے کم سکور کر رہا ہے۔ آئیے مل کر ان شعبوں کی نشاندہی کریں جہاں انہیں مدد کی ضرورت ہے۔",
    "Action required. 🚨 We've noticed a drop in performance. Please arrange a meeting with the teachers so we can support your child better.":
        "پریشان کن صورتحال۔ 🚨 ہم نے کارکردگی میں کمی محسوس کی ہے۔ براہ کرم اساتذہ کے ساتھ ملاقات کا وقت طے کریں تاکہ ہم آپ کے بچے کی بہتر مدد کر سکیں۔",

    // --- Attendance Badges ---
    "Excellent Attendance": "بہترین حاضری",
    "Needs Improvement": "بہتری کی ضرورت ہے",
    "Low Attendance": "کم حاضری",

    "Exceptional! 🌟 Your child is highly punctual and rarely misses a class. Great consistency!":
        "شاندار! 🌟 آپ کا بچہ انتہائی وقت کا پابند ہے اور شاذ و نادر ہی کوئی کلاس چھوڑتا ہے۔ بہترین تسلسل!",
    "Good Attendance! 😊 Your child maintains a very healthy attendance record.":
        "اچھی حاضری! 😊 آپ کا بچہ بہت صحت مند حاضری کا ریکارڈ برقرار رکھے ہوئے ہے۔",
    "Fair. 🌱 Frequent absences can impact learning flow. Let's aim for better consistency.":
        "درمیانہ۔ 🌱 بار بار غیر حاضریاں سیکھنے کے عمل کو متاثر کر سکتی ہیں۔ آئیں بہتر تسلسل کا ہدف بنائیں۔",
    "Needs Attention. 🚨 Significant absences have been recorded. Punctuality is key to success.":
        "توجہ طلب۔ 🚨 نمایاں غیر حاضریاں ریکارڈ کی گئی ہیں۔ وقت کی پابندی کامیابی کی کنجی ہے۔",

    // --- Personality / Wellness Badges ---
    "Role Model": "رول ماڈل",
    "Developing": "ترقی پذیر",
    "Needs Guidance": "رہنمائی کی ضرورت ہے",
    
    "Exceptional! 🌟 Your child demonstrates wonderful habits, excellent behavior, and outstanding personal care.":
        "استثنائی! 🌟 آپ کا بچہ شاندار عادات، بہترین رویے، اور ذاتی دیکھ بھال کا مظاہرہ کرتا ہے۔",
    "Great Job! 😊 Your child continues to develop strong habits and a positive attitude. We're very pleased.":
        "بہت اچھا! 😊 آپ کا بچہ مضبوط عادات اور مثبت رویہ استوار کر رہا ہے۔ ہم بہت خوش ہیں۔",
    "Doing Well! 👍 Your child is showing good progress in their personal development. Let's keep encouraging them.":
        "اچھی کارکردگی! 👍 آپ کا بچہ اپنی ذاتی نشوونما میں اچھی ترقی دکھا رہا ہے۔ آئیں ان کی حوصلہ افزائی جاری رکھیں۔",
    "On the Right Track. 🌱 Your child is learning, but gentle reminders about daily routines could be beneficial.":
        "صحیح راستے پر۔ 🌱 آپ کا بچہ سیکھ رہا ہے، لیکن روزمرہ کے معمولات کے بارے میں نرم یاددہانیاں فائدہ مند ثابت ہو سکتی ہیں۔",
    "Room for Growth. 🤝 Your child might need a bit more guidance and support with their behavior and personal care.":
        "بہتری کی گنجائش۔ 🤝 آپ کے بچے کو اپنے رویے اور ذاتی دیکھ بھال کے حوالے سے تھوڑی مزید رہنمائی اور مدد کی ضرورت ہو سکتی ہے۔",
    "Let's Connect. 💡 We'd love to partner with you to help support and improve your child's well-being and habits.":
        "رابطہ درکار ہے۔ 💡 ہم آپ کے بچے کی فلاح و بہبود اور عادات کو بہتر بنانے میں آپ کے ساتھ مل کر کام کرنا چاہیں گے۔",

    // Section Titles
    "Academic Performance": "تعلیمی کارکردگی",
    "Homework Completion": "ہوم ورک کی تکمیل",
    "Progress Insight": "ترقی کا جائزہ",
    "Monthly Summary": "ماہانہ خلاصہ",
    "Character & Well-being": "کردار اور فلاح و بہبود",
    "Overall Insight": "مجموعی جائزہ",
    "Recent Alerts": "حالیہ اطلاعات",
    
    // --- Personality Traits ---
    "Health": "صحت",
    "Behavior": "رویہ",
    "Hygiene": "صفائی",

    // --- Alerts Common Titles & Messages ---
    "Attendance update": "حاضری کی تازہ کاری",
    "Attendance Alert": "حاضری کی اطلاع",
    "Academic Update": "تعلیمی تازہ کاری",
    "Academic Alert": "تعلیمی اطلاع",
    "Wellness Update": "صحت کی تازہ کاری",
    "Wellness Alert": "صحت کی اطلاع",
    "New Message": "نیا پیغام",
    "Notice": "نوٹس",
    "Notification": "اطلاع",
    "Present": "حاضر",
    "Absent": "غیر حاضر",
    "Holiday": "چھٹی",
    "marked present": "حاضر ٹِک کیا گیا",
    "marked absent": "غیر حاضر ٹِک کیا گیا",

    // --- Result Badge ---
    "Result Card Information": "نتیجہ کارڈ کی معلومات",
    "When your child's result card is available, it will be uploaded here by the school administration or class teacher. You will be able to download it securely.":
        "جب آپ کے بچے کا نتیجہ کارڈ دستیاب ہوگا، اسے سکول انتظامیہ یا کلاس ٹیچر کی طرف سے یہاں اپ لوڈ کر دیا جائے گا۔ آپ اسے محفوظ طریقے سے ڈاؤن لوڈ کر سکیں گے۔",
    "Result Card Available": "نتیجہ کارڈ دستیاب ہے",
    "Result Card Not Yet Uploaded": "نتیجہ کارڈ ابھی اپ لوڈ نہیں ہوا",
    "Download Result Card": "نتیجہ کارڈ ڈاؤن لوڈ کریں",

    // --- Fee Screen Badges ---
    "Excellent consistency! Your prompt payments help us maintain high educational standards.": "بہترین تسلسل! آپ کی بروقت ادائیگیاں اعلیٰ تعلیمی معیار برقرار رکھنے میں ہماری مدد کرتی ہیں۔",
    "Good standing. Thank you for your continued commitment to timely fee clearances.": "اچھی حیثیت۔ بر وقت فیس کلیئرنس کے لیے آپ کے مستقل عزم کا شکریہ۔",
    "Fair standing. Clearing dues within the first week of the month will improve your reliability.": "درمیانی حیثیت۔ مہینے کے پہلے ہفتے میں واجبات ادا کرنے سے آپ کی ساکھ بہتر ہوگی۔",
    "Attention needed. Please ensure timely payments to avoid late fees and maintain a healthy standing.": "توجہ طلب۔ دیر سے ہونے والے جرمانے سے بچنے اور اچھی حیثیت برقرار رکھنے کے لیے بروقت ادائیگی یقینی بنائیں۔",
    "Excellent": "بہترین",
    "Good": "اچھا",
    "Bad": "خراب",
    "Payment Reliability": "ادائیگی کی ساکھ",
    "Based on past 6 months of fee payments.": "پچھلے 6 ماہ کی فیس ادائیگیوں پر مبنی۔",
    // --- Dynamic Prefix / Suffix Replacements ---
    "😊 Great Habits & Well-being!": "😊 بہترین عادات اور فلاح و بہبود!",
    "📊 Performance Update": "📊 کارکردگی کی تازہ کاری",
    "Performance Update": "کارکردگی کی تازہ کاری",
    // ----------------------------------------------
  };

  // Maps for student names, subjects, and generic nouns
  static final Map<String, String> _nounsDictionary = {
    // Subjects
    "Mathematics": "ریاضی",
    "Maths": "ریاضی",
    "Math": "ریاضی",
    "Islamiyat": "اسلامیات",
    "Islamiat": "اسلامیات",
    "English": "انگریزی",
    "Science": "سائنس",
    "Physics": "طبیعیات",
    "Chemistry": "کیمسٹری",
    "Biology": "حیاتیات",
    "Computer": "کمپیوٹر",
    "Urdu": "اردو",
    "History": "تاریخ",
    "Geography": "جغرافیہ",
    "Art": "آرٹ",
    "Drawing": "ڈرائنگ",
    
    // Names
    "Ayesha Siddiqua": "عائشہ صدیقہ",
    "Areeba Khan": "اریبہ خان",
    "Usman Ghani": "عثمان غنی",
    "Ali": "علی",
    "Ahmed": "احمد",
    "Ahmad": "احمد",
    "Fatima": "فاطمہ",
    "Zainab": "زینب",
    "Omar": "عمر",
    "Hassan": "حسن",
    "Hussain": "حسین",
    "Bilal": "بلال",
  };

  static String _translateNouns(String text) {
    String translated = text;
    _nounsDictionary.forEach((eng, urd) {
      // \b ensures we only match whole words if it's a single word, 
      // but for multi-word names we can just do a normal replace.
      // RegExp boundary `\b` works well for English words.
      translated = translated.replaceAll(RegExp(r'\b' + eng + r'\b', caseSensitive: false), urd);
    });
    return translated;
  }

  static String translate(String text, String currentLang) {
    if (currentLang == 'en' || text.isEmpty) return text;
    
    String translatedText = text.trim();

    // 1. Check for dynamic pattern matches (e.g. alerts with names/dates)
    
    // Pattern: Attendance alert
    // "{Name} is marked {status} in School today, {Date}."
    final attendancePattern = RegExp(r"^(.*?) is marked (.*?) in School today, (.*?)\.?$", caseSensitive: false);
    if (attendancePattern.hasMatch(translatedText)) {
      final match = attendancePattern.firstMatch(translatedText)!;
      final name = _translateNouns(match.group(1) ?? '');
      final statusEng = match.group(2)?.toLowerCase() ?? '';
      final date = match.group(3) ?? '';
      
      String statusUrd = statusEng;
      if (statusEng.contains('present')) statusUrd = 'حاضر';
      else if (statusEng.contains('absent')) statusUrd = 'غیر حاضر';
      else if (statusEng.contains('holiday')) statusUrd = 'چھٹی';

      translatedText = "$name کو آج سکول میں $statusUrd قرار دیا گیا ہے، تاریخ: $date۔";
      return translatedText; // Return early to prevent double translation
    }

    // Pattern: Wellness/Personality alert
    // "{Name} is maintaining steady habits. Continuing to encourage good daily routines will help them excel further in behavior and personal care."
    final personalityPattern = RegExp(r"^(.*?) is maintaining steady habits\. Continuing to encourage good daily routines will help them excel further in behavior and personal care\.?$", caseSensitive: false);
    if (personalityPattern.hasMatch(translatedText)) {
      final match = personalityPattern.firstMatch(translatedText)!;
      final name = _translateNouns(match.group(1) ?? '');
      translatedText = "$name مستحکم عادات برقرار رکھے ہوئے ہے۔ روزمرہ کے معمولات کی مستقل حوصلہ افزائی انہیں رویے اور ذاتی دیکھ بھال میں مزید بہتر بنائے گی۔";
      return translatedText;
    }

    // Pattern: Academic alert (both parts)
    // "{Name} is doing great in {Subjects}, but could use some extra support in {Subjects}."
    final academicPattern1 = RegExp(r"^(.*?) is doing great in (.*?), but could use some extra support in (.*?)\.?$", caseSensitive: false);
    if (academicPattern1.hasMatch(translatedText)) {
      final match = academicPattern1.firstMatch(translatedText)!;
      final name = _translateNouns(match.group(1) ?? '');
      final goodSubs = _translateNouns(match.group(2) ?? '');
      final badSubs = _translateNouns(match.group(3) ?? '');
      translatedText = "$name $goodSubs میں بہت اچھا کر رہا/رہی ہے، لیکن اسے $badSubs میں کچھ اضافی مدد کی ضرورت ہے۔";
      return translatedText;
    }

    // Pattern: Academic alert (only doing great)
    // "{Name} is doing great in {Subjects}."
    final academicPattern2 = RegExp(r"^(.*?) is doing great in (.*?)\.?$", caseSensitive: false);
    if (academicPattern2.hasMatch(translatedText)) {
      final match = academicPattern2.firstMatch(translatedText)!;
      final name = _translateNouns(match.group(1) ?? '');
      final goodSubs = _translateNouns(match.group(2) ?? '');
      translatedText = "$name $goodSubs میں بہت اچھا کر رہا/رہی ہے۔";
      return translatedText;
    }

    // Pattern: Academic alert (only needs support)
    // "{Name} could use some extra support in {Subjects}."
    final academicPattern3 = RegExp(r"^(.*?) could use some extra support in (.*?)\.?$", caseSensitive: false);
    if (academicPattern3.hasMatch(translatedText)) {
      final match = academicPattern3.firstMatch(translatedText)!;
      final name = _translateNouns(match.group(1) ?? '');
      final badSubs = _translateNouns(match.group(2) ?? '');
      translatedText = "$name کو $badSubs میں کچھ اضافی مدد کی ضرورت ہے۔";
      return translatedText;
    }

    // Pattern: Fee Calendar Alert
    // "Kindly ensure fee submissions are completed by the {dueDate} to avoid a late penalty of Rs. {penalty}."
    final feePattern = RegExp(r"^Kindly ensure fee submissions are completed by the (.*?) to avoid a late penalty of Rs\. (.*?)\.?$", caseSensitive: false);
    if (feePattern.hasMatch(translatedText)) {
      final match = feePattern.firstMatch(translatedText)!;
      // Strip English ordinals (st, nd, rd, th) from the date number to prevent RTL/LTR bidirectional breaking
      final dueDate = (match.group(1) ?? '').replaceAll(RegExp(r'[a-zA-Z]'), '').trim();
      final penalty = match.group(2) ?? '';
      translatedText = "براہ کرم یقینی بنائیں کہ فیس $dueDate تاریخ تک جمع کروا دی جائے تاکہ $penalty روپے جرمانے سے بچا جا سکے۔";
      return translatedText;
    }

    // 2. Check if the whole string matches (case insensitive exact match)
    for (var entry in _dictionary.entries) {
      if (entry.key.toLowerCase() == translatedText.toLowerCase()) {
        return entry.value;
      }
    }
    
    // 3. Allow replacing known keywords within arbitrary sentences
    _dictionary.forEach((eng, urd) {
      if (eng.split(' ').length <= 4) {
        // Use case-insensitive RegExp for inline replacements
        translatedText = translatedText.replaceAll(RegExp(eng, caseSensitive: false), urd);
      }
    });

    return translatedText;
  }

  static TextStyle getTextStyle(String currentLang, {
    double? fontSize, 
    FontWeight? fontWeight, 
    Color? color, 
    double? height
  }) {
    if (currentLang == 'ur') {
      return GoogleFonts.notoNastaliqUrdu(
        fontSize: fontSize, // Removed artificial +2 boost to keep Nastaliq size balanced with English
        fontWeight: fontWeight ?? FontWeight.normal,
        color: color,
        height: height ?? 1.8, 
      );
    }
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }
}
