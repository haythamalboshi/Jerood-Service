/// بانر إعلان/تعميم، يتم تحميله من تبويب "Ads" في الشيت.
///
/// ترتيب الأعمدة المتوقع: رابط الصورة، رابط عند الضغط (اختياري)، عنوان (اختياري).
class Advertisement {
  final String imageUrl;
  final String? linkUrl;
  final String? title;

  const Advertisement({
    required this.imageUrl,
    this.linkUrl,
    this.title,
  });

  factory Advertisement.fromRow(List<dynamic> row) {
    String cell(int i) => i < row.length ? row[i].toString().trim() : '';
    final link = cell(1);
    final titleValue = cell(2);
    return Advertisement(
      imageUrl: cell(0),
      linkUrl: link.isEmpty ? null : link,
      title: titleValue.isEmpty ? null : titleValue,
    );
  }
}
