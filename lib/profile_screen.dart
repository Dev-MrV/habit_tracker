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
import 'google_drive_backup_service.dart';

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
  late GoogleDriveBackupService _backupService;
  String? _lastBackupTime;

  @override
  void initState() {
    super.initState();
    _backupService = GoogleDriveBackupService();
    _loadData();
    _loadLastBackupTime();
  }

  Future<void> _loadLastBackupTime() async {
    final lastBackup = await _backupService.getLastBackupTime();
    if (mounted) {
      setState(() {
        _lastBackupTime = lastBackup != null
            ? 'Last backup: ${lastBackup.toString().split('.')[0]}'
            : 'No backups yet';
      });
    }
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
      name: _nameCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      age: int.tryParse(_ageCtrl.text.trim()) ?? 0,
      country: _country,
    );
    setState(() {
      _saving = false;
      _editing = false;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  Future<void> _performBackup(BuildContext context) async {
    if (!_backupService.isSignedIn) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: const Text('Backup to Google Drive', style: TextStyle(fontWeight: FontWeight.w700)),
          content: const Text('Sign in with your Google account to back up your habits to Google Drive.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign In')),
          ],
        ),
      );

      if (confirmed != true) return;

      final signedIn = await _backupService.signIn();
      if (!signedIn) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to sign in'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    if (mounted) {
      _showBackupProgress(context);
    }
  }

  void _showBackupProgress(BuildContext context) {
    String message = 'Preparing backup...';
    bool isComplete = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) {
          if (!isComplete) {
            _backupService.backupToGoogleDrive(
              onProgress: (msg) {
                setState(() => message = msg);
                if (msg.contains('successfully')) {
                  isComplete = true;
                  Future.delayed(const Duration(seconds: 1), () {
                    _loadLastBackupTime();
                    Navigator.pop(ctx);
                  });
                }
              },
            );
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: const Text('Backing up...', style: TextStyle(fontWeight: FontWeight.w700)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _performRestore(BuildContext context) async {
    if (!_backupService.isSignedIn) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: const Text('Restore from Backup', style: TextStyle(fontWeight: FontWeight.w700)),
          content: const Text('Sign in with your Google account to restore your habits from a previous backup.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign In')),
          ],
        ),
      );

      if (confirmed != true) return;

      final signedIn = await _backupService.signIn();
      if (!signedIn) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to sign in'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    final backups = await _backupService.getAvailableBackups();
    if (backups.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No backups found'),
            backgroundColor: AppColors.textSecondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (mounted) {
      _showRestoreOptions(context, backups);
    }
  }

  void _showRestoreOptions(BuildContext context, List backups) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Select Backup', style: TextStyle(fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: backups.length,
            itemBuilder: (ctx, index) {
              final backup = backups[index];
              return ListTile(
                title: Text(backup.name),
                subtitle: Text('${backup.createdTime.toString().split('.')[0]} (${backup.formattedSize})'),
                onTap: () {
                  Navigator.pop(ctx);
                  _performRestoreBackup(context, backup.id);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ],
      ),
    );
  }

  void _performRestoreBackup(BuildContext context, String fileId) {
    String message = 'Downloading backup...';
    bool isComplete = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) {
          if (!isComplete) {
            _backupService.restoreFromGoogleDrive(
              fileId: fileId,
              onProgress: (msg) {
                setState(() => message = msg);
                if (msg.contains('successfully')) {
                  isComplete = true;
                  Future.delayed(const Duration(seconds: 1), () {
                    ref.refresh(habitProvider);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Backup restored successfully!'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  });
                }
              },
            );
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: const Text('Restoring...', style: TextStyle(fontWeight: FontWeight.w700)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          );
        },
      ),
    );
  }

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
                    _SettingTile(icon: Icons.cloud_upload_rounded, label: 'Backup to Drive', onTap: () => _performBackup(context)),
                    Divider(height: 1, indent: 20, endIndent: 20, color: Colors.grey.withOpacity(0.2)),
                    _SettingTile(icon: Icons.cloud_download_rounded, label: 'Restore Backup', onTap: () => _performRestore(context)),
                    if (_lastBackupTime != null) ...[
                      Divider(height: 1, indent: 20, endIndent: 20, color: Colors.grey.withOpacity(0.2)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 20, color: AppColors.textSecondary),
                            const SizedBox(width: 12),
                            Text(_lastBackupTime!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
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