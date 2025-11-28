import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _debts = [];
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _error;

  // Delete modal state
  int? _debtToDelete;

  // Status update modal state
  Map<String, dynamic>? _statusUpdate;

  // Create debt form state
  bool _isCreatingDebt = false;
  List<String> _selectedUserIds = [];
  bool _selectAll = false;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  String _currency = 'ARS';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final debtsData = await _apiService.get('/debts');
      final usersData = await _apiService.get('/users');
      setState(() {
        _debts = debtsData as List;
        _users = usersData as List;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar datos: $e';
        _isLoading = false;
      });
    }
  }

  void _showCreateDebtForm() {
    setState(() {
      _isCreatingDebt = true;
      _selectedUserIds.clear();
      _selectAll = false;
      _amountController.clear();
      _reasonController.clear();
      _currency = 'ARS';
    });
  }

  void _closeForm() {
    setState(() {
      _isCreatingDebt = false;
    });
  }

  Future<void> _submitDebt() async {
    if (!_formKey.currentState!.validate()) return;

    final targetUsers = _selectAll ? ['ALL'] : _selectedUserIds;

    if (targetUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un usuario')),
      );
      return;
    }

    try {
      await _apiService.post('/debts', {
        'google_ids': targetUsers,
        'amount': double.parse(_amountController.text),
        'reason': _reasonController.text,
        'currency': _currency,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deuda(s) creada(s) exitosamente')),
        );
        _closeForm();
        _fetchData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al crear deuda: $e')));
      }
    }
  }

  void _toggleUserSelection(String googleId) {
    setState(() {
      if (_selectAll) _selectAll = false;
      if (_selectedUserIds.contains(googleId)) {
        _selectedUserIds.remove(googleId);
      } else {
        _selectedUserIds.add(googleId);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      _selectAll = !_selectAll;
      _selectedUserIds.clear();
    });
  }

  void _showStatusModal(int debtId, String newStatus, String currentStatus) {
    setState(() {
      _statusUpdate = {
        'id': debtId,
        'newStatus': newStatus,
        'currentStatus': currentStatus,
      };
    });
  }

  Future<void> _confirmStatusUpdate() async {
    if (_statusUpdate == null) return;

    try {
      await _apiService.put('/debts', {
        'id': _statusUpdate!['id'],
        'status': _statusUpdate!['newStatus'],
      });
      setState(() => _statusUpdate = null);
      _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar estado: $e')),
        );
      }
      setState(() => _statusUpdate = null);
    }
  }

  void _showDeleteModal(int debtId) {
    setState(() {
      _debtToDelete = debtId;
    });
  }

  Future<void> _confirmDelete() async {
    if (_debtToDelete == null) return;

    try {
      await _apiService.delete('/debts?id=$_debtToDelete');
      setState(() => _debtToDelete = null);
      _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al eliminar deuda: $e')));
      }
      setState(() => _debtToDelete = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchData,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    )
                  : _debts.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay deudas registradas',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: _debts.length,
                      itemBuilder: (context, index) {
                        final debt = _debts[index];
                        final isPaid = debt['status'] == 'paid';

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            border: Border.all(color: Colors.white, width: 1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          debt['user_name'] ?? 'Usuario',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          debt['reason'] ?? '',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${debt['currency']} ${debt['amount']}',
                                    style: TextStyle(
                                      color: isPaid
                                          ? Colors.green
                                          : Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (!isPaid)
                                    ElevatedButton.icon(
                                      onPressed: () => _showStatusModal(
                                        debt['id'],
                                        'paid',
                                        'pending',
                                      ),
                                      icon: const Icon(Icons.check),
                                      label: const Text('Pagar'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    )
                                  else
                                    ElevatedButton.icon(
                                      onPressed: () => _showStatusModal(
                                        debt['id'],
                                        'pending',
                                        'paid',
                                      ),
                                      icon: const Icon(Icons.undo),
                                      label: const Text('Deshacer'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey[700],
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _showDeleteModal(debt['id']),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),

        // FAB for creating new debt
        if (!_isCreatingDebt)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _showCreateDebtForm,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              child: const Icon(Icons.add),
            ),
          ),

        // Create Debt Form
        if (_isCreatingDebt)
          Container(
            color: Colors.black,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'CREAR DEUDA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: _closeForm,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Select All Checkbox
                      CheckboxListTile(
                        title: const Text(
                          'TODOS LOS USUARIOS',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        value: _selectAll,
                        onChanged: (_) => _toggleSelectAll(),
                        activeColor: Colors.white,
                        checkColor: Colors.black,
                        side: const BorderSide(color: Colors.white),
                      ),
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 8),

                      // User List
                      ...(_users.map((user) {
                        final isSelected = _selectedUserIds.contains(
                          user['google_id'],
                        );
                        return CheckboxListTile(
                          title: Text(
                            user['name'] ?? user['email'],
                            style: const TextStyle(color: Colors.white),
                          ),
                          value: _selectAll || isSelected,
                          onChanged: _selectAll
                              ? null
                              : (_) => _toggleUserSelection(user['google_id']),
                          activeColor: Colors.white,
                          checkColor: Colors.black,
                          side: const BorderSide(color: Colors.white),
                        );
                      }).toList()),

                      const SizedBox(height: 24),

                      // Amount
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Monto',
                          labelStyle: TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa un monto';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Ingresa un número válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Currency
                      DropdownButtonFormField<String>(
                        value: _currency,
                        dropdownColor: Colors.grey[900],
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Moneda',
                          labelStyle: TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        items: ['ARS', 'USD'].map((currency) {
                          return DropdownMenuItem(
                            value: currency,
                            child: Text(currency),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _currency = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Reason
                      TextFormField(
                        controller: _reasonController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Razón',
                          labelStyle: TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa una razón';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitDebt,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'CREAR DEUDA(S)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Delete Modal
        if (_debtToDelete != null)
          GestureDetector(
            onTap: () => setState(() => _debtToDelete = null),
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
                          '¿ELIMINAR DEUDA?',
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
                                  setState(() => _debtToDelete = null),
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

        // Status Update Modal
        if (_statusUpdate != null)
          GestureDetector(
            onTap: () => setState(() => _statusUpdate = null),
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
                        Text(
                          _statusUpdate!['newStatus'] == 'paid'
                              ? '¿MARCAR COMO PAGADO?'
                              : '¿DESHACER PAGO?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _statusUpdate!['newStatus'] == 'paid'
                              ? 'Se creará una transacción automática en el balance del club.'
                              : 'Se eliminará la transacción asociada a este pago.',
                          style: const TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () =>
                                  setState(() => _statusUpdate = null),
                              child: const Text(
                                'CANCELAR',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _confirmStatusUpdate,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _statusUpdate!['newStatus'] == 'paid'
                                    ? Colors.green
                                    : Colors.grey[700],
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                _statusUpdate!['newStatus'] == 'paid'
                                    ? 'CONFIRMAR PAGO'
                                    : 'CONFIRMAR',
                              ),
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
