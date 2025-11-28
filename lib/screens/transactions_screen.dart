import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  String? _error;

  // Filter state
  int _filterYear = DateTime.now().year;
  int _filterMonth = DateTime.now().month;

  // Delete modal state
  int? _transactionToDelete;

  // Form state
  bool _isCreatingOrEditing = false;
  bool _isEditing = false;
  int? _editingId;
  final _formKey = GlobalKey<FormState>();
  final _detailController = TextEditingController();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  String _currency = 'ARS';
  DateTime _transactionDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  @override
  void dispose() {
    _detailController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _apiService.get(
        '/transactions?year=$_filterYear&month=$_filterMonth',
      );
      setState(() {
        _transactions = data['transactions'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar transacciones: $e';
        _isLoading = false;
      });
    }
  }

  void _resetForm() {
    setState(() {
      _isCreatingOrEditing = false;
      _isEditing = false;
      _editingId = null;
      _detailController.clear();
      _amountController.clear();
      _categoryController.clear();
      _currency = 'ARS';
      _transactionDate = DateTime.now();
    });
  }

  void _showForm({Map<String, dynamic>? transaction}) {
    if (transaction != null) {
      // Editing
      setState(() {
        _isEditing = true;
        _editingId = transaction['id'];
        _detailController.text = transaction['detail'] ?? '';
        _amountController.text = transaction['amount']?.toString() ?? '';
        _categoryController.text = transaction['category'] ?? '';
        _currency = transaction['currency'] ?? 'ARS';
        _transactionDate = DateTime.parse(
          transaction['transaction_date'].split('T')[0],
        );
      });
    }
    setState(() {
      _isCreatingOrEditing = true;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final payload = {
        'detail': _detailController.text,
        'amount': double.parse(_amountController.text),
        'currency': _currency,
        'transaction_date': _transactionDate.toIso8601String().split('T')[0],
        'category': _categoryController.text.isEmpty
            ? null
            : _categoryController.text,
      };

      if (_isEditing) {
        await _apiService.put('/transactions', {...payload, 'id': _editingId});
      } else {
        await _apiService.post('/transactions', payload);
      }

      _resetForm();
      _fetchTransactions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Transacción actualizada' : 'Transacción creada',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showDeleteModal(int transactionId) {
    setState(() {
      _transactionToDelete = transactionId;
    });
  }

  Future<void> _confirmDelete() async {
    if (_transactionToDelete == null) return;

    try {
      await _apiService.delete('/transactions?id=$_transactionToDelete');

      setState(() {
        _transactionToDelete = null;
      });

      _fetchTransactions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transacción eliminada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _transactionToDelete = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(data: ThemeData.dark(), child: child!);
      },
    );
    if (picked != null && picked != _transactionDate) {
      setState(() {
        _transactionDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _transactions.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_error != null && _transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchTransactions,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Container(
          color: Colors.black,
          child: Column(
            children: [
              // Filters
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  border: const Border(
                    bottom: BorderSide(color: Colors.white10),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _filterMonth,
                        dropdownColor: Colors.grey[900],
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Mes',
                          labelStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white70),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: List.generate(12, (index) {
                          final months = [
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
                          return DropdownMenuItem(
                            value: index + 1,
                            child: Text(months[index]),
                          );
                        }),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _filterMonth = value;
                            });
                            _fetchTransactions();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _filterYear,
                        dropdownColor: Colors.grey[900],
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Año',
                          labelStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white70),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: List.generate(7, (index) {
                          final year = DateTime.now().year - 5 + index;
                          return DropdownMenuItem(
                            value: year,
                            child: Text(year.toString()),
                          );
                        }),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _filterYear = value;
                            });
                            _fetchTransactions();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Transactions List
              Expanded(
                child: RefreshIndicator(
                  color: Colors.white,
                  backgroundColor: Colors.grey[900],
                  onRefresh: _fetchTransactions,
                  child: _transactions.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(24),
                          children: const [
                            Center(
                              child: Text(
                                'No hay transacciones en este mes',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = _transactions[index];
                            final amount = double.parse(
                              transaction['amount']?.toString() ?? '0',
                            );
                            final isIncome = amount >= 0;
                            final isAuto = transaction['debt_id'] != null;

                            return Card(
                              color: Colors.grey[900],
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: Colors.white10),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Detail + Auto badge
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            transaction['detail'] ?? '',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        if (isAuto)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[900],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'AUTO',
                                              style: TextStyle(
                                                color: Colors.blue,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Date + Category
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 12,
                                          color: Colors.grey[500],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateTime.parse(
                                            transaction['transaction_date']
                                                .split('T')[0],
                                          ).toString().split(' ')[0],
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (transaction['category'] !=
                                            null) ...[
                                          const SizedBox(width: 12),
                                          Icon(
                                            Icons.label,
                                            size: 12,
                                            color: Colors.grey[500],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            transaction['category'],
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Amount + Actions
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${transaction['currency']} ${isIncome ? '+' : ''}${amount.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: isIncome
                                                ? Colors.green[300]
                                                : Colors.red[300],
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (!isAuto)
                                          Row(
                                            children: [
                                              IconButton(
                                                onPressed: () => _showForm(
                                                  transaction: transaction,
                                                ),
                                                icon: const Icon(Icons.edit),
                                                color: Colors.blue[300],
                                                iconSize: 20,
                                              ),
                                              IconButton(
                                                onPressed: () =>
                                                    _showDeleteModal(
                                                      transaction['id'],
                                                    ),
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                ),
                                                color: Colors.red[300],
                                                iconSize: 20,
                                              ),
                                            ],
                                          )
                                        else
                                          Text(
                                            'Automática',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),

        // FAB for creating new transaction
        if (!_isCreatingOrEditing)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () => _showForm(),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              child: const Icon(Icons.add),
            ),
          ),

        // Create/Edit Form
        if (_isCreatingOrEditing)
          Container(
            color: Colors.black,
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      border: const Border(
                        bottom: BorderSide(color: Colors.white10),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _resetForm,
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isEditing
                              ? 'EDITAR TRANSACCIÓN'
                              : 'NUEVA TRANSACCIÓN',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _detailController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Detalle *',
                                labelStyle: TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white70),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Campo requerido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _amountController,
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                                signed: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Monto *',
                                labelStyle: TextStyle(color: Colors.grey),
                                helperText:
                                    'Positivo para ingresos, negativo para egresos',
                                helperStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white70),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Campo requerido';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Ingrese un número válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _currency,
                              dropdownColor: Colors.grey[900],
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Moneda',
                                labelStyle: TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white70),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'ARS',
                                  child: Text('ARS (Pesos Argentinos)'),
                                ),
                                DropdownMenuItem(
                                  value: 'USD',
                                  child: Text('USD (Dólares)'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _currency = value;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: () => _selectDate(context),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Fecha',
                                  labelStyle: TextStyle(color: Colors.grey),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _transactionDate.toString().split(' ')[0],
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.calendar_today,
                                      color: Colors.white70,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _categoryController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Categoría (Opcional)',
                                labelStyle: TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white70),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: Text(
                                _isEditing
                                    ? 'ACTUALIZAR TRANSACCIÓN'
                                    : 'CREAR TRANSACCIÓN',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Delete Confirmation Modal
        if (_transactionToDelete != null && !_isCreatingOrEditing)
          GestureDetector(
            onTap: () => setState(() => _transactionToDelete = null),
            child: Container(
              color: Colors.black87,
              child: Center(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '¿ELIMINAR TRANSACCIÓN?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Esta acción no se puede deshacer.',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () =>
                                  setState(() => _transactionToDelete = null),
                              child: const Text(
                                'CANCELAR',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _confirmDelete,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('ELIMINAR'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
