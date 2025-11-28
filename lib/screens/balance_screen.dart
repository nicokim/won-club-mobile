import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/api_service.dart';

class BalanceScreen extends StatefulWidget {
  const BalanceScreen({super.key});

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  final ApiService _apiService = ApiService();

  Map<String, dynamic> _balance = {'ARS': 0, 'USD': 0};
  Map<String, dynamic> _monthlyData = {
    'transactions': [],
    'income': {},
    'expenses': {},
  };

  bool _loadingBalance = true;
  bool _loadingMonthly = true;

  int _currentMonthIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    await Future.wait([_fetchBalance(), _fetchMonthlyData()]);
  }

  Future<void> _fetchBalance() async {
    setState(() => _loadingBalance = true);
    try {
      final data = await _apiService.get('/balance');
      setState(() {
        _balance = Map<String, dynamic>.from(data as Map);
        _loadingBalance = false;
      });
    } catch (e) {
      setState(() {
        _loadingBalance = false;
      });
    }
  }

  Future<void> _fetchMonthlyData() async {
    setState(() => _loadingMonthly = true);

    final monthYear = _getCurrentMonthYear();

    try {
      final data = await _apiService.get(
        '/transactions?year=${monthYear['year']}&month=${monthYear['month']}',
      );
      setState(() {
        _monthlyData = Map<String, dynamic>.from(data as Map);
        _loadingMonthly = false;
      });
    } catch (e) {
      setState(() {
        _loadingMonthly = false;
      });
    }
  }

  Map<String, dynamic> _getCurrentMonthYear() {
    final today = DateTime.now();
    final targetDate = DateTime(
      today.year,
      today.month - _currentMonthIndex,
      1,
    );

    return {
      'year': targetDate.year,
      'month': targetDate.month,
      'monthName': _getMonthName(targetDate),
    };
  }

  String _getMonthName(DateTime date) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _handlePrevMonth() {
    setState(() {
      _currentMonthIndex++;
    });
    _fetchMonthlyData();
  }

  void _handleNextMonth() {
    if (_currentMonthIndex > 0) {
      setState(() {
        _currentMonthIndex--;
      });
      _fetchMonthlyData();
    }
  }

  Future<void> _handleExportPDF() async {
    final monthYear = _getCurrentMonthYear();
    final transactions = _monthlyData['transactions'] as List? ?? [];
    final income = (_monthlyData['income'] != null)
        ? Map<String, dynamic>.from(_monthlyData['income'] as Map)
        : <String, dynamic>{};
    final expenses = (_monthlyData['expenses'] != null)
        ? Map<String, dynamic>.from(_monthlyData['expenses'] as Map)
        : <String, dynamic>{};

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Title
              pw.Text(
                'Balance - ${monthYear['monthName']}',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),

              // Income Table
              if (income.isNotEmpty) ...[
                pw.Text(
                  'INGRESOS',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Moneda',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Monto',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    ...income.entries.map((entry) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(entry.key),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              '\$${entry.value.toStringAsFixed(0)}',
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
                pw.SizedBox(height: 20),
              ],

              // Expenses Table
              if (expenses.isNotEmpty) ...[
                pw.Text(
                  'EGRESOS',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Moneda',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Monto',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    ...expenses.entries.map((entry) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(entry.key),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              '\$${entry.value.toStringAsFixed(0)}',
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
                pw.SizedBox(height: 20),
              ],

              // Transactions Table
              if (transactions.isNotEmpty) ...[
                pw.Text(
                  'DETALLE DE TRANSACCIONES',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Detalle',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Categoría',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Moneda',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Monto',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Tipo',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    ...transactions.map((t) {
                      final amount = double.parse(t['amount'].toString());
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(t['detail'] ?? ''),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(t['category'] ?? '-'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(t['currency'] ?? ''),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              '\$${amount.abs().toStringAsFixed(0)}',
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(amount < 0 ? 'Egreso' : 'Ingreso'),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );

    // Show print/save dialog
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name:
          'Balance_${monthYear['monthName'].toString().replaceAll(' ', '_')}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthYear = _getCurrentMonthYear();
    final transactions = _monthlyData['transactions'] as List? ?? [];
    final income = (_monthlyData['income'] != null)
        ? Map<String, dynamic>.from(_monthlyData['income'] as Map)
        : <String, dynamic>{};
    final expenses = (_monthlyData['expenses'] != null)
        ? Map<String, dynamic>.from(_monthlyData['expenses'] as Map)
        : <String, dynamic>{};

    return RefreshIndicator(
      onRefresh: _fetchAllData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'BALANCE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'ESTADO DE CUENTA',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Balance del Club
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BALANCE DEL CLUB',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(color: Colors.white),
                const SizedBox(height: 8),
                if (_loadingBalance)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  const Text(
                    'TOTAL EN CAJA',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ARS', style: TextStyle(color: Colors.grey)),
                      Text(
                        '\$${(_balance['ARS'] ?? 0).toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('USD', style: TextStyle(color: Colors.grey)),
                      Text(
                        '\$${(_balance['USD'] ?? 0).toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Resumen Mensual
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'RESUMEN MENSUAL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.download, color: Colors.white),
                          onPressed: _handleExportPDF,
                          tooltip: 'Exportar a PDF',
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                          ),
                          onPressed: _handlePrevMonth,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.chevron_right,
                            color: _currentMonthIndex == 0
                                ? Colors.grey
                                : Colors.white,
                          ),
                          onPressed: _currentMonthIndex == 0
                              ? null
                              : _handleNextMonth,
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  monthYear['monthName'].toString().toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (_loadingMonthly)
                  const Center(child: CircularProgressIndicator())
                else if (transactions.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No hay transacciones en este mes',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else ...[
                  ...transactions.map((transaction) {
                    final amount = double.parse(
                      transaction['amount'].toString(),
                    );
                    final isExpense = amount < 0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  transaction['detail'] ?? '',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                if (transaction['category'] != null)
                                  Text(
                                    '(${transaction['category']})',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${transaction['currency']} \$${amount.abs().toStringAsFixed(0)}',
                            style: TextStyle(
                              color: isExpense ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const Divider(color: Colors.white, height: 32),

                  // Ingresos
                  const Text(
                    'INGRESOS DEL MES',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (income.isEmpty)
                    const Text(
                      'Sin ingresos',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    )
                  else
                    ...income.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            Text(
                              '\$${entry.value.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  const SizedBox(height: 16),

                  // Egresos
                  const Text(
                    'EGRESOS DEL MES',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (expenses.isEmpty)
                    const Text(
                      'Sin egresos',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    )
                  else
                    ...expenses.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            Text(
                              '\$${entry.value.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
