import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/advertisement.dart';

/// شريط إعلانات/تعاميم أفقي قابل للتمرير، مصدره تبويب "Ads" في الشيت.
/// لا يعرض شيئاً إن كانت القائمة فارغة.
class AdBannerWidget extends StatelessWidget {
  final List<Advertisement> ads;

  const AdBannerWidget({super.key, required this.ads});

  Future<void> _openAd(Advertisement ad) async {
    final link = ad.linkUrl;
    if (link == null || link.isEmpty) return;
    final uri = Uri.tryParse(link);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ads.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: ads.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final ad = ads[index];
          return GestureDetector(
            onTap: () => _openAd(ad),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CachedNetworkImage(
                imageUrl: ad.imageUrl,
                width: 260,
                height: 140,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 260,
                  color: CupertinoColors.systemGrey5,
                  child: const Center(child: CupertinoActivityIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 260,
                  color: CupertinoColors.systemGrey5,
                  child: const Icon(CupertinoIcons.photo, color: CupertinoColors.systemGrey),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
