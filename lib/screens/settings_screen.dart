import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../services/database_service.dart';
import '../services/pdf_export_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _paydayCycle = '15_30';
  bool _notificationsEnabled = true;
  bool _remindersEnabled = true;
  bool _billRemindersEnabled = true;
  bool _debtRemindersEnabled = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _paydayCycle = prefs.getString('payday_cycle') ?? '15_30';
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _remindersEnabled = prefs.getBool('payday_reminders') ?? true;
      _billRemindersEnabled = prefs.getBool('bill_reminders') ?? true;
      _debtRemindersEnabled = prefs.getBool('debt_reminders') ?? true;
    });
  }

  Future<void> _savePaydayCycle(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('payday_cycle', value);
    setState(() => _paydayCycle = value);
  }

  Future<void> _saveMasterNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() => _notificationsEnabled = value);
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surface,
          duration: const Duration(seconds: 2),
          content: Text(
            value
                ? '✓ Naka-ON na ang mga notification at paalala.'
                : 'Naka-OFF na ang lahat ng notification.',
            style: TextStyle(
              color: value ? AppColors.drySage : AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _saveReminders(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('payday_reminders', value);
    setState(() => _remindersEnabled = value);
  }

  Future<void> _saveBillReminders(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bill_reminders', value);
    setState(() => _billRemindersEnabled = value);
  }

  Future<void> _saveDebtReminders(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('debt_reminders', value);
    setState(() => _debtRemindersEnabled = value);
  }

  void _exportPdf() async {
    setState(() => _isExporting = true);
    try {
      await PdfExportService.exportFinancialReport();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surface,
            content: Text('Error generating PDF: $e', style: const TextStyle(color: AppColors.warningRed)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _confirmResetAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Reset Everything to ₱0?', style: TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text(
          'Mabubura ang lahat ng tala ng utang, maibabalik sa ₱0 ang iyong naipon, at mabu-clear ang wallet balance.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.warningRed),
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseService.instance.resetAllToZero();
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('payday_delayed_until');
              await prefs.remove('payday_last_received_cycle');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.surface,
                    content: Text('✓ Everything reset back to ₱0.00!', style: TextStyle(color: AppColors.drySage, fontWeight: FontWeight.bold)),
                  ),
                );
              }
            },
            child: const Text('Reset to ₱0', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.whiteSmoke),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.whiteSmoke,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Section: Payday Cycle Schedule
          _buildSectionHeader('ARAW NG SAHOD (PAYDAY SCHEDULE)'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kailan ang regular mong kinsenas?',
                  style: TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Gagamitin ito sa countdown banner sa Dashboard.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 12),
                _buildRadioTile('15th & 30th (Default / Karaniwan)', '15_30'),
                _buildRadioTile('10th & 25th', '10_25'),
                _buildRadioTile('5th & 20th', '5_20'),
                _buildRadioTile('Katapusan Lamang (End of Month Only)', 'end_of_month'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section: Export Data as PDF (User Request)
          _buildSectionHeader('EXPORT DATA'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.dustyOlive.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.drySage, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'I-export bilang PDF',
                            style: TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            'Kumuha ng kumpletong financial report (Wallets, Ipon, Utang) sa PDF format.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.dustyOlive,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isExporting ? null : _exportPdf,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.whiteSmoke),
                        )
                      : const Icon(Icons.download_rounded, size: 18, color: AppColors.whiteSmoke),
                  label: Text(
                    _isExporting ? 'Bumubuo ng PDF...' : 'I-download ang PDF Report',
                    style: const TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section: Notifications & Reminders
          _buildSectionHeader('MGA PAALALA (NOTIFICATIONS)'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                // Master Turn On / Off Notifications Switch
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _notificationsEnabled
                              ? AppColors.dustyOlive.withValues(alpha: 0.25)
                              : AppColors.inputFill,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _notificationsEnabled ? AppColors.drySage.withValues(alpha: 0.4) : AppColors.border,
                          ),
                        ),
                        child: Icon(
                          _notificationsEnabled
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_off_outlined,
                          color: _notificationsEnabled ? AppColors.drySage : AppColors.textMuted,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Flexible(
                                  child: Text(
                                    'I-on ang Notifications',
                                    style: TextStyle(
                                      color: AppColors.whiteSmoke,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _notificationsEnabled
                                        ? AppColors.dustyOlive.withValues(alpha: 0.35)
                                        : AppColors.inputFill,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: _notificationsEnabled ? AppColors.drySage : AppColors.border,
                                    ),
                                  ),
                                  child: Text(
                                    _notificationsEnabled ? 'ON' : 'OFF',
                                    style: TextStyle(
                                      color: _notificationsEnabled ? AppColors.drySage : AppColors.textMuted,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _notificationsEnabled
                                  ? 'Aktibo ang mga paalala sa sahod, bayarin, at utang.'
                                  : 'Naka-mute ang lahat ng paalala sa app.',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        activeThumbColor: AppColors.drySage,
                        activeTrackColor: AppColors.dustyOlive,
                        value: _notificationsEnabled,
                        onChanged: _saveMasterNotifications,
                      ),
                    ],
                  ),
                ),

                const Divider(color: AppColors.border, height: 1, indent: 16, endIndent: 16),

                // Sub-toggles (enabled when master notifications are ON)
                AnimatedOpacity(
                  opacity: _notificationsEnabled ? 1.0 : 0.45,
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    children: [
                      SwitchListTile(
                        activeThumbColor: AppColors.drySage,
                        activeTrackColor: AppColors.dustyOlive,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        title: const Text(
                          'Paalala Bago ang Sahod',
                          style: TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        subtitle: const Text(
                          'Magpaalala kapag 1 araw na lang bago ang iyong kinsenas.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                        value: _notificationsEnabled && _remindersEnabled,
                        onChanged: _notificationsEnabled ? _saveReminders : null,
                      ),
                      const Divider(color: AppColors.borderMuted, height: 1, indent: 16, endIndent: 16),
                      SwitchListTile(
                        activeThumbColor: AppColors.drySage,
                        activeTrackColor: AppColors.dustyOlive,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        title: const Text(
                          'Paalala sa Mga Bayarin (Bills Due)',
                          style: TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        subtitle: const Text(
                          'Magpaalala kapag malapit na ang due date ng buwanang bayarin.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                        value: _notificationsEnabled && _billRemindersEnabled,
                        onChanged: _notificationsEnabled ? _saveBillReminders : null,
                      ),
                      const Divider(color: AppColors.borderMuted, height: 1, indent: 16, endIndent: 16),
                      SwitchListTile(
                        activeThumbColor: AppColors.drySage,
                        activeTrackColor: AppColors.dustyOlive,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        title: const Text(
                          'Paalala sa Utang at Singilin',
                          style: TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        subtitle: const Text(
                          'Magpaalala sa mga nakatakdang bayaran at sisingiling pautang.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                        value: _notificationsEnabled && _debtRemindersEnabled,
                        onChanged: _notificationsEnabled ? _saveDebtReminders : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section: Danger Zone / Reset
          _buildSectionHeader('DATA MANAGEMENT'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'I-reset ang Lahat sa ₱0',
                  style: TextStyle(color: AppColors.warningRed, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Buburahin nito ang lahat ng naitalang debts, savings progress, at balances pabalik sa simula.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warningRed,
                    side: const BorderSide(color: AppColors.warningRed),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.restart_alt_rounded, size: 16),
                  label: const Text('I-reset Lahat sa ₱0', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: _confirmResetAll,
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // About / Privacy Note
          const Center(
            child: Column(
              children: [
                Text('Kinsenas v1.0.0', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(
                  '100% Offline & Lokal • Ang iyong data ay ligtas sa iyong device.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildRadioTile(String title, String value) {
    final isSelected = _paydayCycle == value;
    return InkWell(
      onTap: () => _savePaydayCycle(value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.drySage : AppColors.textSecondary,
                  width: 2,
                ),
                color: isSelected ? AppColors.drySage : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.circle, size: 8, color: AppColors.background),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? AppColors.whiteSmoke : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
