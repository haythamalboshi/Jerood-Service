import 'package:flutter/cupertino.dart';
// BottomNavigationBarItem نوعٌ معرّف ضمن مكتبة material، لكنه مُستخدم هنا
// فقط كنموذج بيانات لعناصر CupertinoTabBar (لا نستخدم أي ودجات Material).
import 'package:flutter/material.dart' show BottomNavigationBarItem;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/pharmacy.dart';
import '../models/water_schedule.dart';
import '../models/emergency_contact.dart';
import '../models/advertisement.dart';
import '../services/storage_service.dart';
import '../services/sheets_service.dart';
import '../services/notification_service.dart';
import '../widgets/ios_card.dart';
import '../widgets/ad_banner.dart';
import 'pharmacies_screen.dart';
import 'emergency_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final StorageService storage;

  const HomeScreen({super.key, required this.storage});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final GoogleSheetsService _sheetsService;

  bool _loading = true;
  List<WaterSchedule> _waterSchedules = [];
  List<Pharmacy> _pharmacies = [];
  List<EmergencyContact> _emergencyContacts = [];
  List<Advertisement> _ads = [];
  String? _selectedNeighborhood;

  @override
  void initState() {
    super.initState();
    _sheetsService = GoogleSheetsService(widget.storage);
    _selectedNeighborhood = widget.storage.selectedNeighborhood;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await initializeDateFormatting('ar');
    await _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);

    final waterSchedules = await _sheetsService.fetchWaterSchedules();
    final pharmacies = await _sheetsService.fetchPharmacies();
    final emergencyContacts = await _sheetsService.fetchEmergencyContacts();
    final ads = await _sheetsService.fetchAdvertisements();

    if (!mounted) return;
    setState(() {
      _waterSchedules = waterSchedules;
      _pharmacies = pharmacies;
      _emergencyContacts = emergencyContacts;
      _ads = ads;
      _loading = false;
    });

    _maybeScheduleReminder();
  }

  void _maybeScheduleReminder() {
    final neighborhood = _selectedNeighborhood;
    if (neighborhood == null) return;

    final upcoming = _schedulesForSelected
        .where((w) => w.deliveryDateTime.isAfter(DateTime.now()))
        .toList();
    if (upcoming.isEmpty) return;

    NotificationService().scheduleWaterReminder(
      deliveryDateTime: upcoming.first.deliveryDateTime,
      neighborhood: neighborhood,
    );
  }

  Future<void> _selectNeighborhood(String neighborhood) async {
    setState(() => _selectedNeighborhood = neighborhood);
    await widget.storage.setSelectedNeighborhood(neighborhood);
    _maybeScheduleReminder();
  }

  Pharmacy? _firstOrNull(Iterable<Pharmacy> list) => list.isEmpty ? null : list.first;

  Pharmacy? get _dayPharmacy => _firstOrNull(_pharmacies.where((p) => p.isDayShift));
  Pharmacy? get _nightPharmacy => _firstOrNull(_pharmacies.where((p) => p.isNightShift));

  List<WaterSchedule> get _schedulesForSelected {
    final neighborhood = _selectedNeighborhood;
    if (neighborhood == null) return [];
    final list = _waterSchedules.where((w) => w.neighborhood == neighborhood).toList();
    list.sort((a, b) => a.deliveryDateTime.compareTo(b.deliveryDateTime));
    return list;
  }

  List<String> get _neighborhoods {
    final set = _waterSchedules.map((w) => w.neighborhood).where((n) => n.isNotEmpty).toSet();
    final list = set.toList();
    list.sort();
    return list;
  }

  void _pickNeighborhood() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('اختر الحي'),
        actions: _neighborhoods
            .map(
              (n) => CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(ctx);
                  _selectNeighborhood(n);
                },
                child: Text(n),
              ),
            )
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          isDestructiveAction: true,
          child: const Text('إلغاء'),
        ),
      ),
    );
  }

  Widget _buildWaterTab() {
    final schedules = _schedulesForSelected;
    final formatter = DateFormat('EEEE d MMMM yyyy، الساعة HH:mm', 'ar');

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const CupertinoSliverNavigationBar(largeTitle: Text('أدوار المياه')),
        CupertinoSliverRefreshControl(onRefresh: _loadAll),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdBannerWidget(ads: _ads),
              IosCard(
                onTap: _pickNeighborhood,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedNeighborhood ?? 'اختر الحي',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Icon(CupertinoIcons.chevron_down, size: 18, color: CupertinoColors.systemGrey),
                  ],
                ),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CupertinoActivityIndicator()),
                )
              else if (_selectedNeighborhood == null)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('الرجاء اختيار الحي لعرض دور المياه الخاص به.', textAlign: TextAlign.center),
                )
              else if (schedules.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('لا يوجد دور مياه مسجّل حالياً لهذا الحي.', textAlign: TextAlign.center),
                )
              else
                ...schedules.map(
                  (s) => IosCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.neighborhood, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(formatter.format(s.deliveryDateTime), style: const TextStyle(color: CupertinoColors.activeBlue)),
                        if (s.notes != null) ...[
                          const SizedBox(height: 4),
                          Text(s.notes!, style: const TextStyle(color: CupertinoColors.secondaryLabel)),
                        ],
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.drop_fill), label: 'المياه'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.plus_circle_fill), label: 'الصيدليات'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.phone_fill), label: 'الطوارئ'),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.settings), label: 'الإعدادات'),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 1:
            return CupertinoTabView(
              builder: (context) => CupertinoPageScaffold(
                navigationBar: const CupertinoNavigationBar(middle: Text('الصيدليات المناوبة')),
                child: PharmaciesScreen(
                  dayPharmacy: _dayPharmacy,
                  nightPharmacy: _nightPharmacy,
                  allPharmacies: _pharmacies,
                  adsList: _ads,
                  onRefresh: _loadAll,
                ),
              ),
            );
          case 2:
            return CupertinoTabView(
              builder: (context) => CupertinoPageScaffold(
                navigationBar: const CupertinoNavigationBar(middle: Text('الطوارئ')),
                child: EmergencyScreen(
                  emergencyList: _emergencyContacts,
                  adsList: _ads,
                  onRefresh: _loadAll,
                ),
              ),
            );
          case 3:
            return CupertinoTabView(
              builder: (context) => CupertinoPageScaffold(
                navigationBar: const CupertinoNavigationBar(middle: Text('الإعدادات')),
                child: SettingsScreen(
                  storage: widget.storage,
                  onReloadData: _loadAll,
                ),
              ),
            );
          default:
            return CupertinoTabView(
              builder: (context) => CupertinoPageScaffold(
                child: _buildWaterTab(),
              ),
            );
        }
      },
    );
  }
}
