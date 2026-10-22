/// صيدلية مناوبة، يتم تحميلها من تبويب "Pharmacies" في الشيت.
///
/// ترتيب الأعمدة المتوقع في الشيت: الاسم، العنوان، المناوبة (يوم/ليل)، الهاتف.
/// إن كان ترتيب الأعمدة الفعلي مختلفاً، عدّل [Pharmacy.fromRow] فقط.
class Pharmacy {
  final String name;
  final String address;
  final String shift;
  final String? phone;

  const Pharmacy({
    required this.name,
    required this.address,
    required this.shift,
    this.phone,
  });

  factory Pharmacy.fromRow(List<dynamic> row) {
    String cell(int i) => i < row.length ? row[i].toString().trim() : '';
    final phoneValue = cell(3);
    return Pharmacy(
      name: cell(0),
      address: cell(1),
      shift: cell(2),
      phone: phoneValue.isEmpty ? null : phoneValue,
    );
  }

  /// يدعم القيم العربية والإنجليزية الشائعة لمناوبة النهار.
  bool get isDayShift {
    final s = shift.trim();
    return s == 'يوم' || s == 'ظهر' || s == 'ظهراً' || s.toLowerCase() == 'day';
  }

  bool get isNightShift => !isDayShift;
}
