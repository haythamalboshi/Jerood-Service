/// رقم طوارئ/جهة خدمية، يتم تحميله من تبويب "Emergency" في الشيت.
///
/// ترتيب الأعمدة المتوقع: اسم الجهة، رقم الهاتف.
class EmergencyContact {
  final String entityName;
  final String phoneNumber;

  const EmergencyContact({
    required this.entityName,
    required this.phoneNumber,
  });

  factory EmergencyContact.fromRow(List<dynamic> row) {
    String cell(int i) => i < row.length ? row[i].toString().trim() : '';
    return EmergencyContact(
      entityName: cell(0),
      phoneNumber: cell(1),
    );
  }

  /// الرقم بعد إزالة أي مسافات أو رموز غير رقمية، جاهز للاستخدام مباشرة
  /// في رابط `tel:` عند الاتصال.
  String get cleanDialNumber => phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
}
