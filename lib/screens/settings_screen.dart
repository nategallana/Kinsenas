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
  bool _remindersEnabled = true;
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
      _remindersEnabled = prefs.getBool('payday_reminders') ?? true;
    });
  }

  Future<void> _savePaydayCycle(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('payday_cycle', value);
    setState(() => _paydayCycle = value);
  }

  Future<void> _saveReminders(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('payday_reminders', value);
    setState(() => _remindersEnabled = value);
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
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.whiteSmoke),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mga Setting (Settings)',
          style: TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 18),
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
            child: SwitchListTile(
              activeThumbColor: AppColors.drySage,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: const Text('Paalala Bago ang Sahod', style: TextStyle(color: AppColors.whiteSmoke, fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: const Text('Magpaalala kapag 1 araw na lang bago ang iyong kinsenas.', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              value: _remindersEnabled,
              onChanged: _saveReminders,
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
