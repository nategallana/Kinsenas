import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/debt.dart';
import '../services/database_service.dart';

class PdfExportService {
  /// Generates a comprehensive financial PDF report and opens the print/export dialog
  static Future<void> exportFinancialReport() async {
    final accounts = await DatabaseService.instance.getAccounts();
    final goals = await DatabaseService.instance.getGoals();
    final debts = await DatabaseService.instance.getDebts();

    double totalCash = 0.0;
    for (var a in accounts) {
      totalCash += a.balance;
    }

    double totalPayables = 0.0;
    double totalReceivables = 0.0;
    final List<Debt> payables = [];
    final List<Debt> receivables = [];

    for (var d in debts) {
      if (d.type == DebtType.payable) {
        totalPayables += d.remainingAmount;
        payables.add(d);
      } else {
        totalReceivables += d.remainingAmount;
        receivables.add(d);
      }
    }

    final netWorth = (totalCash + totalReceivables) - totalPayables;
    final currencyFmt = NumberFormat.currency(symbol: 'PHP ', decimalDigits: 2);
    final dateStr = DateFormat('MMMM d, yyyy h:mm a').format(DateTime.now());

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return [
            // Title Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'KINSENAS',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#373D20'),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Personal Financial & Debt Summary Report',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Generated on:',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                    ),
                    pw.Text(
                      dateStr,
                      style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 16),
            pw.Divider(color: PdfColor.fromHex('#717744'), thickness: 1.5),
            pw.SizedBox(height: 14),

            // Section 1: Financial Overview / Net Worth
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#EFF1ED'),
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColor.fromHex('#BCBD8B')),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'TOTAL NET WORTH',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#766153'),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    currencyFmt.format(netWorth),
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: netWorth >= 0 ? PdfColor.fromHex('#373D20') : PdfColors.red800,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Cash & Wallets: ${currencyFmt.format(totalCash)}', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Payables (Owed): ${currencyFmt.format(totalPayables)}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.red700)),
                      pw.Text('Receivables (Lent): ${currencyFmt.format(totalReceivables)}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.green800)),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 22),

            // Section 2: Ipon & Savings Goals
            pw.Text(
              'IPON & SAVINGS GOALS',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#373D20'),
              ),
            ),
            pw.SizedBox(height: 8),
            if (goals.isEmpty)
              pw.Text('No savings goals recorded.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))
            else
              pw.TableHelper.fromTextArray(
                headers: ['Goal Name', 'Saved Amount', 'Target Amount', 'Progress'],
                headerStyle: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#5A6338')),
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                data: goals.map((g) {
                  final pct = (g.progressRatio * 100).toStringAsFixed(1);
                  return [
                    g.title,
                    currencyFmt.format(g.currentAmount),
                    currencyFmt.format(g.targetAmount),
                    '$pct%',
                  ];
                }).toList(),
              ),

            pw.SizedBox(height: 22),

            // Section 3: Utang Ko (Payables / Money I Owe)
            pw.Text(
              'UTANG KO (PAYABLES - MONEY I OWE)',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#766153'),
              ),
            ),
            pw.SizedBox(height: 8),
            if (payables.isEmpty)
              pw.Text('Walang nakalistang utang (No payables).', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))
            else
              pw.TableHelper.fromTextArray(
                headers: ['Lender / Institution', 'Original Amount', 'Remaining Balance', 'Due Day'],
                headerStyle: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#766153')),
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                data: payables.map((d) {
                  return [
                    d.title,
                    currencyFmt.format(d.totalAmount),
                    currencyFmt.format(d.remainingAmount),
                    d.dueDayOfMonth != null ? '${d.dueDayOfMonth}th of month' : 'N/A',
                  ];
                }).toList(),
              ),

            pw.SizedBox(height: 22),

            // Section 4: May Utang Sakin (Receivables / Money Owed to Me)
            pw.Text(
              'MAY UTANG SAKIN (RECEIVABLES - MONEY OWED TO ME)',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#373D20'),
              ),
            ),
            pw.SizedBox(height: 8),
            if (receivables.isEmpty)
              pw.Text('Walang pautang na nakalista (No receivables).', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))
            else
              pw.TableHelper.fromTextArray(
                headers: ['Borrower Name', 'Total Lent', 'Remaining to Collect', 'Due Day'],
                headerStyle: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#717744')),
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                data: receivables.map((d) {
                  return [
                    d.title,
                    currencyFmt.format(d.totalAmount),
                    currencyFmt.format(d.remainingAmount),
                    d.dueDayOfMonth != null ? '${d.dueDayOfMonth}th of month' : 'N/A',
                  ];
                }).toList(),
              ),

            pw.SizedBox(height: 30),
            pw.Divider(color: PdfColor.fromHex('#BCBD8B'), thickness: 1),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Text(
                'Kinsenas • Offline-First Personal Finance Tracker • All Data Stored Locally',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ),
          ];
        },
      ),
    );

    // Open print preview / export / save dialog
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Kinsenas_Financial_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
}
