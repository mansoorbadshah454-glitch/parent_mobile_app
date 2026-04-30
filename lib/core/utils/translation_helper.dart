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
    "No Data": "کوئی ڈیٹا نہیں",
    "Critical Attendance": "انتہائی کم حاضری",
    "High Absenteeism": "زیادہ غیر حاضری",
    "No attendance recorded yet. 📅 Attendance data for this month will appear here once marked by the teacher.": "ابھی تک حاضری ریکارڈ نہیں کی گئی۔ 📅 اس مہینے کی حاضری کا ڈیٹا استاد کی طرف سے نشان زد ہونے کے بعد یہاں ظاہر ہوگا۔",

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
    // --- New Academic/Homework Titles ---
    "Distinction": "امتیازی کارکردگی",
    "Satisfactory": "تسلی بخش",
    "Poor Performance": "ناقص کارکردگی",
    "Poor Consistency": "ناقص تسلسل",
    
    // --- Syllabus Badges ---
    "Active Chapter Available": "موجودہ باب دستیاب ہے",
    "Currently Teaching in School": "اس وقت سکول میں پڑھایا جا رہا ہے",
    "Our faculty is currently focusing on this chapter, ensuring a deep understanding of core concepts. We highly encourage you to discuss these topics with your child at home to reinforce their learning.": "ہماری فیکلٹی اس وقت اس باب پر توجہ دے رہی ہے، تاکہ بنیادی تصورات کی گہری سمجھ کو یقینی بنایا جا سکے۔ ہم آپ کی بھرپور حوصلہ افزائی کرتے ہیں کہ اپنے بچے کے ساتھ گھر پر ان موضوعات پر بات کریں تاکہ ان کی سیکھنے کی صلاحیت مزید بہتر ہو۔",
    "No chapter is currently marked as 'In Progress' for this subject.": "اس مضمون کے لیے فی الحال کوئی باب 'جاری ہے' کے طور پر نشان زد نہیں ہے۔",
    "No syllabus data available.": "نصاب کا کوئی ڈیٹا دستیاب نہیں ہے۔",
    "Failed to load syllabus.": "نصاب لوڈ کرنے میں ناکام۔",
    "Failed to load chapters.": "ابواب لوڈ کرنے میں ناکام۔",

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

    // Pattern: Scheduled Test Message
    // "Consistent practice builds confidence. Support {Name} by creating a distraction-free study space for this test!"
    final scheduledTestPattern = RegExp(r"^Consistent practice builds confidence\. Support (.*?) by creating a distraction-free study space for this test!?$", caseSensitive: false);
    if (scheduledTestPattern.hasMatch(translatedText)) {
      final match = scheduledTestPattern.firstMatch(translatedText)!;
      final name = _translateNouns(match.group(1) ?? '');
      translatedText = "مسلسل مشق اعتماد پیدا کرتی ہے۔ اس ٹیسٹ کے لیے خلفشار سے پاک مطالعہ کی جگہ بنا کر $name کی مدد کریں!";
      return translatedText;
    }

    // Pattern: Academic Badges
    final acadDistinction = RegExp(r"^Exceptional performance! 🎉 Your child demonstrates outstanding academic excellence, particularly in (.*?) \((.*?)\%\)\.?$", caseSensitive: false);
    if (acadDistinction.hasMatch(translatedText)) {
      final match = acadDistinction.firstMatch(translatedText)!;
      final subj = _translateNouns(match.group(1) ?? '');
      final score = match.group(2) ?? '';
      return "شاندار کارکردگی! 🎉 آپ کا بچہ غیر معمولی تعلیمی قابلیت کا مظاہرہ کر رہا ہے، خاص طور پر $subj ($score%) میں۔";
    }

    final acadExcellent = RegExp(r"^Excellent progress! 🌟 Consistent high academic standards observed, with notable proficiency in (.*?) \((.*?)\%\)\.?$", caseSensitive: false);
    if (acadExcellent.hasMatch(translatedText)) {
      final match = acadExcellent.firstMatch(translatedText)!;
      final subj = _translateNouns(match.group(1) ?? '');
      final score = match.group(2) ?? '';
      return "بہترین ترقی! 🌟 مسلسل اعلیٰ تعلیمی معیار دیکھنے میں آیا ہے، جس میں نمایاں مہارت $subj ($score%) میں ہے۔";
    }

    final acadVeryGood = RegExp(r"^Very good standing\. 👍 A strong academic record overall\. Maintaining focus on (.*?) \((.*?)\%\) will further improve their grade\.?$", caseSensitive: false);
    if (acadVeryGood.hasMatch(translatedText)) {
      final match = acadVeryGood.firstMatch(translatedText)!;
      final subj = _translateNouns(match.group(1) ?? '');
      final score = match.group(2) ?? '';
      return "بہت اچھی کارکردگی۔ 👍 مجموعی طور پر ایک مضبوط تعلیمی ریکارڈ۔ $subj ($score%) پر توجہ برقرار رکھنے سے ان کے گریڈ میں مزید بہتری آئے گی۔";
    }

    final acadGood = RegExp(r"^Good performance\. 📚 Core concepts are clear, showing strength in (.*?)\. Additional revision for (.*?) is recommended\.?$", caseSensitive: false);
    if (acadGood.hasMatch(translatedText)) {
      final match = acadGood.firstMatch(translatedText)!;
      final highSubj = _translateNouns(match.group(1) ?? '');
      final lowSubj = _translateNouns(match.group(2) ?? '');
      return "اچھی کارکردگی۔ 📚 بنیادی تصورات واضح ہیں، جو $highSubj میں مضبوطی ظاہر کرتے ہیں۔ $lowSubj کے لیے اضافی دہرائی کی سفارش کی جاتی ہے۔";
    }

    final acadSatisfactory = RegExp(r"^Satisfactory progress\. 📊 Academic results meet basic expectations\. Dedicated study time for (.*?) \((.*?)\%\) is advised\.?$", caseSensitive: false);
    if (acadSatisfactory.hasMatch(translatedText)) {
      final match = acadSatisfactory.firstMatch(translatedText)!;
      final subj = _translateNouns(match.group(1) ?? '');
      final score = match.group(2) ?? '';
      return "تسلی بخش ترقی۔ 📊 تعلیمی نتائج بنیادی توقعات پر پورا اترتے ہیں۔ $subj ($score%) کے لیے مطالعہ کا وقت مختص کرنے کا مشورہ دیا جاتا ہے۔";
    }

    final acadNeedsImprovement = RegExp(r"^Needs improvement\. ⚠️ Below average performance detected\. Guided support is necessary to address weaknesses in (.*?) \((.*?)\%\)\.?$", caseSensitive: false);
    if (acadNeedsImprovement.hasMatch(translatedText)) {
      final match = acadNeedsImprovement.firstMatch(translatedText)!;
      final subj = _translateNouns(match.group(1) ?? '');
      final score = match.group(2) ?? '';
      return "بہتری کی ضرورت ہے۔ ⚠️ اوسط سے کم کارکردگی نوٹ کی گئی۔ $subj ($score%) میں کمزوریوں کو دور کرنے کے لیے رہنمائی اور مدد ضروری ہے۔";
    }

    final acadPoor = RegExp(r"^Poor academic standing\. 📉 Significant difficulties observed\. Please consult with the teacher regarding (.*?) \((.*?)\%\)\.?$", caseSensitive: false);
    if (acadPoor.hasMatch(translatedText)) {
      final match = acadPoor.firstMatch(translatedText)!;
      final subj = _translateNouns(match.group(1) ?? '');
      final score = match.group(2) ?? '';
      return "ناقص تعلیمی کارکردگی۔ 📉 نمایاں مشکلات دیکھی گئی ہیں۔ براہ کرم $subj ($score%) کے حوالے سے استاد سے مشورہ کریں۔";
    }

    final acadAction = RegExp(r"^Critical attention required\. 🚨 Substantial academic intervention is urgently needed\. Kindly schedule a meeting with the administration\.?$", caseSensitive: false);
    if (acadAction.hasMatch(translatedText)) {
      return "انتہائی توجہ درکار ہے۔ 🚨 فوری طور پر نمایاں تعلیمی مداخلت کی ضرورت ہے۔ براہ کرم انتظامیہ کے ساتھ ملاقات کا وقت طے کریں۔";
    }

    // Pattern: Homework Badges
    final hwDistinction = RegExp(r"^Exceptional consistency! 📝 All assignments are submitted on time, showing great responsibility, especially in (.*?)\.?$", caseSensitive: false);
    if (hwDistinction.hasMatch(translatedText)) {
      final match = hwDistinction.firstMatch(translatedText)!;
      final subj = _translateNouns(match.group(1) ?? '');
      return "شاندار تسلسل! 📝 تمام اسائنمنٹس وقت پر جمع کروائی گئی ہیں، جو کہ زبردست ذمہ داری کو ظاہر کرتی ہے، خاص طور پر $subj میں۔";
    }

    final hwExcellent = RegExp(r"^Excellent completion rate! 🎒 Highly consistent with daily tasks, demonstrating a strong work ethic\.?$", caseSensitive: false);
    if (hwExcellent.hasMatch(translatedText)) {
      return "تکمیل کی بہترین شرح! 🎒 روزمرہ کے کاموں کے ساتھ انتہائی مطابقت، جو کام کے ایک مضبوط اصول کو ظاہر کرتی ہے۔";
    }

    final hwVeryGood = RegExp(r"^Very good consistency\. 📓 Most homework is completed effectively\. Please ensure (.*?) assignments are not overlooked\.?$", caseSensitive: false);
    if (hwVeryGood.hasMatch(translatedText)) {
      final match = hwVeryGood.firstMatch(translatedText)!;
      final subj = _translateNouns(match.group(1) ?? '');
      return "بہت اچھا تسلسل۔ 📓 زیادہ تر ہوم ورک مؤثر طریقے سے مکمل کیا گیا ہے۔ براہ کرم یقینی بنائیں کہ $subj کی اسائنمنٹس کو نظر انداز نہ کیا جائے۔";
    }

    final hwGood = RegExp(r"^Good adherence\. ⏱️ Homework is generally submitted\. Monitoring (.*?) tasks will help maintain regularity\.?$", caseSensitive: false);
    if (hwGood.hasMatch(translatedText)) {
      final match = hwGood.firstMatch(translatedText)!;
      final subj = _translateNouns(match.group(1) ?? '');
      return "اچھی پابندی۔ ⏱️ ہوم ورک عام طور پر جمع کروایا جاتا ہے۔ $subj کے کاموں کی نگرانی باقاعدگی برقرار رکھنے میں مدد دے گی۔";
    }

    final hwSatisfactory = RegExp(r"^Satisfactory completion\. 📋 Assignments are partially met\. Regular checks on (.*?) homework are recommended\.?$", caseSensitive: false);
    if (hwSatisfactory.hasMatch(translatedText)) {
      final match = hwSatisfactory.firstMatch(translatedText)!;
      final subj = _translateNouns(match.group(1) ?? '');
      return "تسلی بخش تکمیل۔ 📋 اسائنمنٹس جزوی طور پر پوری کی گئی ہیں۔ $subj کے ہوم ورک کی باقاعدہ جانچ پڑتال کی سفارش کی جاتی ہے۔";
    }

    final hwNeedsAttention = RegExp(r"^Needs attention\. ⚠️ Multiple missing assignments noted\. Increased parental supervision is advised, particularly for (.*?)\.?$", caseSensitive: false);
    if (hwNeedsAttention.hasMatch(translatedText)) {
      final match = hwNeedsAttention.firstMatch(translatedText)!;
      final subj = _translateNouns(match.group(1) ?? '');
      return "توجہ طلب۔ ⚠️ متعدد گمشدہ اسائنمنٹس نوٹ کی گئیں۔ خاص طور پر $subj کے لیے والدین کی نگرانی میں اضافے کا مشورہ دیا جاتا ہے۔";
    }

    final hwPoor = RegExp(r"^Poor homework record\. 📉 Consistency is severely lacking\. Immediate focus is required to address missing tasks in (.*?)\.?$", caseSensitive: false);
    if (hwPoor.hasMatch(translatedText)) {
      final match = hwPoor.firstMatch(translatedText)!;
      final subj = _translateNouns(match.group(1) ?? '');
      return "ناقص ہوم ورک کا ریکارڈ۔ 📉 تسلسل کی شدید کمی ہے۔ $subj میں نامکمل کاموں کو دور کرنے کے لیے فوری توجہ درکار ہے۔";
    }

    final hwAction = RegExp(r"^Action required\. 🚨 Chronic failure to submit homework\. Urgent parental intervention is necessary\.?$", caseSensitive: false);
    if (hwAction.hasMatch(translatedText)) {
      return "کارروائی درکار ہے۔ 🚨 ہوم ورک جمع کرانے میں مسلسل ناکامی۔ والدین کی فوری مداخلت ضروری ہے۔";
    }

    // Pattern: Chapter Name
    final chapterPattern = RegExp(r"^Chapter: (.*?)$", caseSensitive: false);
    if (chapterPattern.hasMatch(translatedText)) {
      final match = chapterPattern.firstMatch(translatedText)!;
      final chap = match.group(1) ?? '';
      return "باب: $chap";
    }

    // Pattern: Attendance Dynamic Badges
    final attExceptional = RegExp(r"^Exceptional! 🌟 Your child has perfect attendance with (.*?) presents so far this month\. We highly appreciate this dedication!?$", caseSensitive: false);
    if (attExceptional.hasMatch(translatedText)) {
      final match = attExceptional.firstMatch(translatedText)!;
      return "شاندار! 🌟 آپ کے بچے کی حاضری بہترین ہے اور اس ماہ اب تک ${match.group(1)} حاضریاں ہیں۔ ہم اس لگن کی دل کھول کر تعریف کرتے ہیں!";
    }

    final attGood = RegExp(r"^Good Attendance! 😊 Your child has only missed 1 day out of (.*?) tracked days\. Keep up the good consistency\.?$", caseSensitive: false);
    if (attGood.hasMatch(translatedText)) {
      final match = attGood.firstMatch(translatedText)!;
      return "اچھی حاضری! 😊 آپ کے بچے نے ${match.group(1)} ٹریک کیے گئے دنوں میں سے صرف 1 دن چھٹی کی ہے۔ اس اچھے تسلسل کو برقرار رکھیں۔";
    }

    final attFair = RegExp(r"^Fair\. 🌱 Your child has (.*?) absences this month\. While (.*?) days of attendance is good, reducing absences will help maintain their academic flow\.?$", caseSensitive: false);
    if (attFair.hasMatch(translatedText)) {
      final match = attFair.firstMatch(translatedText)!;
      return "درمیانہ۔ 🌱 آپ کے بچے کی اس ماہ ${match.group(1)} غیر حاضریاں ہیں۔ اگرچہ ${match.group(2)} دن کی حاضری اچھی ہے، غیر حاضریوں کو کم کرنے سے ان کی تعلیمی روانی برقرار رکھنے میں مدد ملے گی۔";
    }

    final attNeedsAttention = RegExp(r"^Needs Attention\. ⚠️ Your child has accumulated (.*?) absences against (.*?) presents\. Please ensure they attend classes regularly to avoid falling behind\.?$", caseSensitive: false);
    if (attNeedsAttention.hasMatch(translatedText)) {
      final match = attNeedsAttention.firstMatch(translatedText)!;
      return "توجہ کی ضرورت ہے۔ ⚠️ آپ کے بچے نے ${match.group(2)} حاضریوں کے مقابلے میں ${match.group(1)} غیر حاضریاں جمع کر لی ہیں۔ براہ کرم یقینی بنائیں کہ وہ باقاعدگی سے کلاسز میں شرکت کریں تاکہ وہ پیچھے نہ رہ جائیں۔";
    }

    final attActionRequired = RegExp(r"^Action Required\. 🚨 Your child has been absent for (.*?) days this month\. This level of absenteeism critically impacts their learning\. Please contact the administration\.?$", caseSensitive: false);
    if (attActionRequired.hasMatch(translatedText)) {
      final match = attActionRequired.firstMatch(translatedText)!;
      return "کارروائی درکار ہے۔ 🚨 آپ کا بچہ اس ماہ ${match.group(1)} دن غیر حاضر رہا ہے۔ غیر حاضری کی یہ سطح ان کے سیکھنے کے عمل کو بری طرح متاثر کرتی ہے۔ براہ کرم انتظامیہ سے رابطہ کریں۔";
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
