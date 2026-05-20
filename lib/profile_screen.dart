import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'app_theme.dart';
import 'app_constants.dart';
import 'auth_provider.dart';
import 'habit_provider.dart';
import 'notification_provider.dart';
import 'theme_provider.dart';
import 'animated_widget.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _editing = false;
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  String _country = 'United States';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final user = ref.read(authProvider).currentUser;
    if (user != null) {
      _nameCtrl.text = user.name;
      _usernameCtrl.text = user.username;
      _ageCtrl.text = user.age.toString();
      _country = user.country;
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _usernameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await ref.read(authProvider.notifier).updateProfile(
      name: _nameCtrl.text.trim(), username: _usernameCtrl.text.trim(),
      age: int.tryParse(_ageCtrl.text.trim()) ?? 0, country: _country,
    );
    setState(() { _saving = false; _editing = false; });
  }

  @override
  void dispose() { _nameCtrl.dispose(); _usernameCtrl.dispose(); _ageCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final habits = ref.watch(habitProvider);
    final isDark = ref.watch(themeProvider);
    final user = auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    final initials = user.name.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
        actions: [
          if (!_editing)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: () => setState(() => _editing = true),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w700)),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // Avatar
            Center(
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400), curve: Curves.easeOutBack,
                    width: _editing ? 100 : 120, height: _editing ? 100 : 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 30, offset: const Offset(0, 10))],
                      border: Border.all(color: isDark ? AppColors.surfaceDark : Colors.white, width: 4),
                    ),
                    child: Center(
                      child: Text(initials, style: TextStyle(color: Colors.white, fontSize: _editing ? 36 : 44, fontWeight: FontWeight.w800, fontFamily: 'Outfit')),
                    ),
                  ).animate().scale(delay: 100.ms, begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: !_editing
                        ? Column(
                            key: const ValueKey('n_v'),
                            children: [
                              Text(user.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontFamily: 'Outfit', fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                child: Text('@${user.username}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14)),
                              ),
                            ],
                          )
                        : Text('Editing Profile', key: const ValueKey('e_v'), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            if (!_editing) ...[
              Row(
                children: [
                  Expanded(child: _StatBadge(label: 'Habits', value: '${habits.habits.length}', color: AppColors.primary)),
                  const SizedBox(width: 16),
                  Expanded(child: _StatBadge(label: 'This Week', value: '${habits.totalCompletionsThisWeek}', color: AppColors.accentGreen)),
                  const SizedBox(width: 16),
                  Expanded(child: _StatBadge(label: 'Best Streak', value: '${habits.getBestHabit()?.currentStreak ?? 0}d', color: AppColors.accentOrange)),
                ],
              ).animate().fade(delay: 200.ms).slideY(begin: 0.1),
              const SizedBox(height: 32),
            ],

            AnimatedCrossFade(
              duration: const Duration(milliseconds: 400),
              crossFadeState: _editing ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: _InfoSection(user: user, isDark: isDark),
              secondChild: _EditSection(nameCtrl: _nameCtrl, usernameCtrl: _usernameCtrl, ageCtrl: _ageCtrl, country: _country, onCountryChanged: (c) => setState(() => _country = c), onSave: _save, onCancel: () { _loadData(); setState(() => _editing = false); }, saving: _saving),
            ),

            if (!_editing) ...[
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Column(
                  children: [
                    _SettingTile(icon: Icons.dark_mode_rounded, label: 'Dark Mode', trailing: Switch(value: isDark, onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(), activeColor: AppColors.primary)),
                    Divider(height: 1, indent: 20, endIndent: 20, color: Colors.grey.withOpacity(0.2)),
                    Consumer(
                      builder: (ctx, r, _) {
                        final st = r.watch(notificationProvider).globalEnabled;
                        return _SettingTile(icon: Icons.notifications_active_rounded, label: 'Global Notifications', trailing: Switch(value: st, onChanged: (_) => r.read(notificationProvider.notifier).toggleGlobal(), activeColor: AppColors.primary));
                      },
                    ),
                    Divider(height: 1, indent: 20, endIndent: 20, color: Colors.grey.withOpacity(0.2)),
                    const _SettingTile(icon: Icons.privacy_tip_rounded, label: 'Privacy Policy'),
                    Divider(height: 1, indent: 20, endIndent: 20, color: Colors.grey.withOpacity(0.2)),
                    const _SettingTile(icon: Icons.info_rounded, label: 'About HabitFlow'),
                    Divider(height: 1, indent: 20, endIndent: 20, color: Colors.grey.withOpacity(0.2)),
                    _SettingTile(icon: Icons.logout_rounded, label: 'Sign Out', iconColor: AppColors.error, labelColor: AppColors.error, onTap: () => _confirmLogout(context)),
                  ],
                ),
              ).animate().fade(delay: 300.ms).slideY(begin: 0.1),
              const SizedBox(height: 120),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Sign Out?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to log out of your cloud account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600))),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, elevation: 0), onPressed: () { Navigator.pop(context); ref.read(authProvider.notifier).logout(); }, child: const Text('Sign Out')),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final dynamic user;
  final bool isDark;
  const _InfoSection({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          _InfoRow(icon: Icons.person_rounded, label: 'Legal Name', value: user.name),
          Divider(height: 1, indent: 20, endIndent: 20, color: Colors.grey.withOpacity(0.2)),
          _InfoRow(icon: Icons.alternate_email_rounded, label: 'Username', value: '@${user.username}'),
          Divider(height: 1, indent: 20, endIndent: 20, color: Colors.grey.withOpacity(0.2)),
          _InfoRow(icon: Icons.cake_rounded, label: 'Age Requirement', value: '${user.age} yrs'),
          Divider(height: 1, indent: 20, endIndent: 20, color: Colors.grey.withOpacity(0.2)),
          _InfoRow(icon: Icons.public_rounded, label: 'Region', value: user.country),
        ],
      ),
    ).animate().fade(delay: 250.ms);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppColors.primary, size: 20)),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textSecondary)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        ],
      ),
    );
  }
}

class _EditSection extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController usernameCtrl;
  final TextEditingController ageCtrl;
  final String country;
  final Function(String) onCountryChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final bool saving;

  const _EditSection({required this.nameCtrl, required this.usernameCtrl, required this.ageCtrl, required this.country, required this.onCountryChanged, required this.onSave, required this.onCancel, required this.saving});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: isDark ? AppColors.cardDark : Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
      child: Column(
        children: [
          TextFormField(controller: nameCtrl, style: const TextStyle(fontWeight: FontWeight.w600), decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_rounded))),
          const SizedBox(height: 16),
          TextFormField(controller: usernameCtrl, style: const TextStyle(fontWeight: FontWeight.w600), decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.alternate_email_rounded))),
          const SizedBox(height: 16),
          TextFormField(controller: ageCtrl, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], style: const TextStyle(fontWeight: FontWeight.w600), decoration: const InputDecoration(labelText: 'Age', prefixIcon: Icon(Icons.cake_rounded))),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(value: country, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary), isExpanded: true, decoration: const InputDecoration(labelText: 'Country', prefixIcon: Icon(Icons.public_rounded)), items: kCountries.map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary)))).toList(), onChanged: (v) => onCountryChanged(v!)),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: onCancel, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('Cancel'))),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: GradientButton(label: 'Save Changes', onTap: onSave, isLoading: saving)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: isDark ? AppColors.cardDark : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(isDark ? 0.2 : 0.1), width: 1.5), boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w800, fontFamily: 'Outfit')),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? labelColor;

  const _SettingTile({required this.icon, required this.label, this.trailing, this.onTap, this.iconColor, this.labelColor});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: (iconColor ?? AppColors.primary).withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20)),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: labelColor))),
            if (trailing != null) trailing! else if (onTap != null) const Icon(Icons.chevron_right_rounded, color: AppColors.textLight, size: 20),
          ],
        ),
      ),
    );
  }
}