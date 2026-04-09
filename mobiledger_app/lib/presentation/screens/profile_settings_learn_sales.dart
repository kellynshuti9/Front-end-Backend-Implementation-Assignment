import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/settings_provider.dart';
import '../../../domain/providers/order_credit_providers.dart';
import '../../../domain/providers/product_provider.dart';
import '../widgets/common/widgets.dart';
import '../../data/models/order_model.dart';

// ─── Profile Screen ───────────────────────────────────────────────────────────

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final products = context.watch<ProductProvider>();
    final orders = context.watch<OrderProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile View')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Avatar
          CircleAvatar(
            radius: 46,
            backgroundColor: AppColors.primary.withOpacity(0.12),
            backgroundImage:
                user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
            child: user?.photoUrl == null
                ? Text(
                    (user?.fullName.isNotEmpty == true)
                        ? user!.fullName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary))
                : null,
          ),
          const SizedBox(height: 10),
          Text(user?.fullName ?? '',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          Text(
              '@${user?.username.isNotEmpty == true ? user!.username : 'username'}',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          Text(
              user?.location.isNotEmpty == true
                  ? user!.location
                  : 'Kigali, Rwanda',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          if (auth.emailVerified == false)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.warning, size: 14),
                const SizedBox(width: 6),
                const Text('Email not verified',
                    style: TextStyle(fontSize: 11, color: AppColors.warning)),
                const SizedBox(width: 8),
                TextButton(
                  style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  onPressed: auth.resendVerificationEmail,
                  child: const Text('Resend',
                      style: TextStyle(fontSize: 11, color: AppColors.primary)),
                ),
              ]),
            ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Edit Profile',
            width: 160,
            height: 40,
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.editProfile),
          ),
          const SizedBox(height: 20),
          // Stats
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _Stat('${orders.orders.length}', 'Orders'),
            Container(width: 1, height: 36, color: AppColors.divider),
            _Stat('${products.myProducts.length}', 'Products'),
            Container(width: 1, height: 36, color: AppColors.divider),
            _Stat(
                '${context.watch<CreditProvider>().credits.length}', 'Credits'),
          ]),
          const SizedBox(height: 20),
          // Menu
          _MenuItem(Icons.store_outlined, 'My Shop',
              () => Navigator.pushNamed(context, AppRoutes.myProducts)),
          _MenuItem(Icons.list_alt_outlined, 'My Orders',
              () => Navigator.pushNamed(context, AppRoutes.myOrders)),
          _MenuItem(Icons.account_balance_wallet_outlined, 'Credit Tracker',
              () => Navigator.pushNamed(context, AppRoutes.creditTracker)),
          _MenuItem(Icons.payment_outlined, 'Payment Methods', () {}),
          _MenuItem(Icons.location_on_outlined, 'Saved Addresses', () {}),
          _MenuItem(Icons.settings_outlined, 'Settings',
              () => Navigator.pushNamed(context, AppRoutes.settings)),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Log Out',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w600)),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Log Out?'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Log Out',
                          style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                await context.read<AuthProvider>().signOut();
                if (!context.mounted) return;
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          ),
        ]),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String val, label;
  const _Stat(this.val, this.label);
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(val,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary)),
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ]);
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuItem(this.icon, this.label, this.onTap);
  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: AppColors.primary, size: 22),
        title: Text(label, style: const TextStyle(fontSize: 14)),
        trailing: const Icon(Icons.chevron_right,
            color: AppColors.textHint, size: 20),
        onTap: onTap,
      );
}

// ─── Edit Profile Screen ──────────────────────────────────────────────────────

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late TextEditingController _name, _username, _phone, _location, _shop;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().user;
    _name = TextEditingController(text: u?.fullName ?? '');
    _username = TextEditingController(text: u?.username ?? '');
    _phone = TextEditingController(text: u?.phoneNumber ?? '');
    _location = TextEditingController(text: u?.location ?? '');
    _shop = TextEditingController(text: u?.shopName ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _phone.dispose();
    _location.dispose();
    _shop.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final ok = await context.read<AuthProvider>().updateProfile({
      'fullName': _name.text.trim(),
      'username': _username.text.trim(),
      'phoneNumber': _phone.text.trim(),
      'location': _location.text.trim(),
      'shopName': _shop.text.trim(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated!')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Edit Profile')),
        body: LoadingOverlay(
          loading: _saving,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(alignment: Alignment.bottomRight, children: [
                    const CircleAvatar(
                        radius: 46,
                        backgroundColor: AppColors.inputFill,
                        child: Icon(Icons.person,
                            size: 46, color: AppColors.textHint)),
                    Container(
                      decoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.camera_alt,
                          size: 14, color: Colors.white),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  const Text('Change Photo',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 24),
                  _f('Full Name'),
                  AppTextField(
                      hint: '',
                      controller: _name,
                      validator: (v) => Validators.required(v, 'Name')),
                  const SizedBox(height: 14),
                  _f('Shop Name'),
                  AppTextField(
                      hint: 'e.g. Kigali Fresh Market', controller: _shop),
                  const SizedBox(height: 14),
                  _f('Username'),
                  AppTextField(hint: '@username', controller: _username),
                  const SizedBox(height: 14),
                  _f('Phone Number'),
                  AppTextField(
                      hint: '+250 78...',
                      controller: _phone,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 14),
                  _f('Location'),
                  AppTextField(
                      hint: 'e.g. Kigali, Rwanda', controller: _location),
                  const SizedBox(height: 28),
                  AppButton(
                      label: 'Save Changes',
                      onPressed: _save,
                      isLoading: _saving),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _f(String t) => Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(t,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      );
}

// ─── Settings Screen ──────────────────────────────────────────────────────────

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          title: const Text('Settings'), automaticallyImplyLeading: false),
      body: ListView(children: [
        _header('My Profile'),
        _info('Shop Name',
            user?.shopName.isNotEmpty == true ? user!.shopName : 'My Shop'),
        _info('Owner', user?.fullName ?? ''),
        _info(
            'Location',
            user?.location.isNotEmpty == true
                ? user!.location
                : 'Kigali, Rwanda'),
        ListTile(
          leading: const Icon(Icons.edit_outlined,
              color: AppColors.primary, size: 20),
          title: const Text('Edit Profile', style: TextStyle(fontSize: 13)),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => Navigator.pushNamed(context, AppRoutes.editProfile),
        ),

        _header('App Preferences'),
        // Language dropdown
        ListTile(
          title: const Text('App Language', style: TextStyle(fontSize: 13)),
          trailing: DropdownButton<String>(
            value: settings.language,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'rw', child: Text('Kinyarwanda')),
            ],
            onChanged: (v) => settings.setLanguage(v!),
          ),
        ),
        // Currency dropdown
        ListTile(
          title: const Text('Currency', style: TextStyle(fontSize: 13)),
          trailing: DropdownButton<String>(
            value: settings.currency,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'RWF', child: Text('RWF')),
              DropdownMenuItem(value: 'USD', child: Text('USD')),
            ],
            onChanged: (v) => settings.setCurrency(v!),
          ),
        ),
        SwitchListTile.adaptive(
          title: const Text('Dark Mode', style: TextStyle(fontSize: 13)),
          value: settings.darkMode,
          activeColor: AppColors.primary,
          onChanged: settings.setDarkMode,
        ),
        SwitchListTile.adaptive(
          title: const Text('Auto Sync', style: TextStyle(fontSize: 13)),
          value: settings.autoSync,
          activeColor: AppColors.primary,
          onChanged: settings.setAutoSync,
        ),
        SwitchListTile.adaptive(
          title: const Text('Notifications', style: TextStyle(fontSize: 13)),
          value: settings.notifications,
          activeColor: AppColors.primary,
          onChanged: settings.setNotifications,
        ),
        SwitchListTile.adaptive(
          title: const Text('Data Saver', style: TextStyle(fontSize: 13)),
          value: settings.dataSaver,
          activeColor: AppColors.primary,
          onChanged: settings.setDataSaver,
        ),

        _header('Data & Backup'),
        _navTile(
            context, 'Backup to Cloud', Icons.cloud_upload_outlined, () {}),
        _navTile(
            context, 'Export Sales Report', Icons.download_outlined, () {}),
        _navTile(context, 'Clear App Cache', Icons.delete_sweep_outlined,
            () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Clear Cache?'),
              content: const Text('This will reset all local preferences.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Clear',
                        style: TextStyle(color: AppColors.error))),
              ],
            ),
          );
          if (ok == true && context.mounted) {
            await settings.clearCache();
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Cache cleared')));
          }
        }),

        _header('Support'),
        _navTile(context, 'Help & FAQ', Icons.help_outline, () {}),
        _navTile(context, 'Contact Us', Icons.mail_outline, () {}),
        _info('About MobiLedger', 'Version 1.0.0'),

        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Log Out',
                style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Log Out?'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Log Out',
                          style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                await context.read<AuthProvider>().signOut();
                if (!context.mounted) return;
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          ),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _header(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(t.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5)),
      );

  Widget _info(String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textPrimary)),
            Text(v,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      );

  Widget _navTile(
          BuildContext ctx, String l, IconData icon, VoidCallback onTap) =>
      ListTile(
        leading: Icon(icon, color: AppColors.primary, size: 20),
        title: Text(l, style: const TextStyle(fontSize: 13)),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      );
}

// ─── Learn Hub Screen ─────────────────────────────────────────────────────────

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});
  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _searchCtrl = TextEditingController();
  String _query = '';
  final _tabs = ['Business Series', 'Finance', 'Marketing'];

  static const _lessons = [
    _Lesson('📊', 'How to Price Your Products',
        'Learn competitive pricing strategies', 15, AppColors.success),
    _Lesson('🤝', 'Managing Customer Credit',
        'Safely offer credit to customers', 10, AppColors.info),
    _Lesson('💰', 'Saving For Your Business',
        'Build business savings effectively', 20, AppColors.warning),
    _Lesson('📚', 'Record Keeping', 'Simple bookkeeping methods', 25,
        AppColors.primary),
    _Lesson('📣', 'Marketing on Social Media', 'Reach more customers online',
        18, Colors.purple),
    _Lesson('🏦', 'Accessing Business Loans', 'Understand financing options',
        22, AppColors.error),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? _lessons
        : _lessons
            .where((l) =>
                l.title.toLowerCase().contains(_query.toLowerCase()) ||
                l.subtitle.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Learn Hub'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.navInactive,
          indicatorColor: AppColors.accent,
          isScrollable: true,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: AppTextField(
            hint: 'Search learning topics...',
            controller: _searchCtrl,
            prefix:
                const Icon(Icons.search, size: 20, color: AppColors.textHint),
            suffix: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    })
                : null,
            onChanged: (q) => setState(() => _query = q),
          ),
        ),
        Expanded(
          child: _query.isNotEmpty
              ? _LessonList(lessons: filtered)
              : TabBarView(
                  controller: _tab,
                  children: _tabs
                      .map((_) => const _LessonList(lessons: _lessons))
                      .toList(),
                ),
        ),
      ]),
    );
  }
}

class _Lesson {
  final String icon, title, subtitle;
  final int duration;
  final Color color;
  const _Lesson(
      this.icon, this.title, this.subtitle, this.duration, this.color);
}

class _LessonList extends StatelessWidget {
  final List<_Lesson> lessons;
  const _LessonList({required this.lessons});

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off,
        title: 'No Results',
        subtitle: 'Try a different search term',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        ...lessons.map((l) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: l.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                            child: Text(l.icon,
                                style: const TextStyle(fontSize: 22)))),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.title,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(l.subtitle,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    )),
                    Column(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: l.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('${l.duration} min',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: l.color)),
                      ),
                      const SizedBox(height: 6),
                      Icon(Icons.play_circle_outline, color: l.color, size: 22),
                    ]),
                  ]),
                ),
              ),
            )),
        Center(
            child: OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('View More Topics...',
              style: TextStyle(fontWeight: FontWeight.w600)),
        )),
      ],
    );
  }
}

// ─── Sales Screen ─────────────────────────────────────────────────────────────

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});
  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  int _period = 0;
  final _periods = ['Today', 'This Week', 'This Month'];

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>().orders;
    final now = DateTime.now();

    List<OrderModel> filtered;
    switch (_period) {
      case 0:
        filtered = orders
            .where((o) =>
                o.createdAt.day == now.day && o.createdAt.month == now.month)
            .toList();
      case 1:
        final weekAgo = now.subtract(const Duration(days: 7));
        filtered = orders.where((o) => o.createdAt.isAfter(weekAgo)).toList();
      default:
        filtered = orders
            .where((o) =>
                o.createdAt.month == now.month && o.createdAt.year == now.year)
            .toList();
    }

    final totalSales = filtered.fold(0.0, (s, o) => s + o.total);
    final avgSale = filtered.isEmpty ? 0.0 : totalSales / filtered.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Sales')),
      body: Column(children: [
        // Period filter
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
              children: List.generate(
                  _periods.length,
                  (i) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () => setState(() => _period = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: i == _period
                                  ? AppColors.primary
                                  : AppColors.inputFill,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(_periods[i],
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: i == _period
                                        ? Colors.white
                                        : AppColors.textSecondary)),
                          ),
                        ),
                      ))),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              // Stats
              Row(children: [
                Expanded(
                    child: _StatBox(
                        'Total Sales',
                        '${totalSales.toStringAsFixed(0)} RWF',
                        AppColors.primary)),
                const SizedBox(width: 10),
                Expanded(
                    child: _StatBox(
                        'Transactions', '${filtered.length}', AppColors.info)),
                const SizedBox(width: 10),
                Expanded(
                    child: _StatBox(
                        'Avg. Sale',
                        '${avgSale.toStringAsFixed(0)} RWF',
                        AppColors.warning)),
              ]),
              const SizedBox(height: 20),
              const SectionHeader(title: 'Recent Transactions'),
              const SizedBox(height: 10),
              ...filtered.isEmpty
                  ? [
                      const EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No Transactions',
                        subtitle: 'No sales in this period',
                      )
                    ]
                  : filtered.map((o) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(o.formattedDate,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary)),
                                    Text('${o.total.toStringAsFixed(0)} RWF',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(o.orderNumber,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                Text(
                                    o.items
                                        .map((i) => i.productName)
                                        .join(', '),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                StatusBadge(
                                  label: o.paymentMethod,
                                  color: AppColors.info,
                                ),
                              ]),
                        ),
                      )),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title, value;
  final Color color;
  const _StatBox(this.title, this.value, this.color);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(fontSize: 10, color: Colors.white70)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ]),
      );
}
