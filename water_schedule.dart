/// دور مياه لحي معيّن، يتم تحميله من تبويب "Water" في الشيت.
///
/// ترتيب الأعمدة المتوقع: الحي، التاريخ (YYYY-MM-DD)، الوقت (HH:mm)،
/// ملاحظات (اختياري).
class WaterSchedule {
  final String neighborhood;
  final DateTime deliveryDateTime;
  final String? notes;

  const WaterSchedule({
    required this.neighborhood,
    required this.deliveryDateTime,
    this.notes,
  });

  factory WaterSchedule.fromRow(List<dynamic> row) {
    String cell(int i) => i < row.length ? row[i].toString().trim() : '';

    final neighborhood = cell(0);
    final dateStr = cell(1);
    final timeStr = cell(2).isEmpty ? '00:00' : cell(2);
    final notesValue = cell(3);

    DateTime parsed;
    try {
      parsed = DateTime.parse('${dateStr}T$timeStr:00');
    } catch (_) {
      // تنسيق تاريخ غير متوقع في الشيت — استخدم الوقت الحالي كقيمة احتياطية
      // بدل تعطّل التطبيق بالكامل.
      parsed = DateTime.now();
    }

    return WaterSchedule(
      neighborhood: neighborhood,
      deliveryDateTime: parsed,
      notes: notesValue.isEmpty ? null : notesValue,
    );
  }
}
