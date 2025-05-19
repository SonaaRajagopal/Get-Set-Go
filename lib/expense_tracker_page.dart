import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dropdown_search/dropdown_search.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ExpenseTrackerPage extends StatefulWidget {
  const ExpenseTrackerPage({super.key});

  @override
  _ExpenseTrackerPageState createState() => _ExpenseTrackerPageState();
}

class _ExpenseTrackerPageState extends State<ExpenseTrackerPage> {
  bool _isAddingExpense = false;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _conversionResult = '';
  Map<String, dynamic> _supportedCurrencies = {};
  String? _selectedCategory;
  String? _selectedBaseCurrency;
  String? _selectedForeignCurrency;
  String? _currentTourId;
  DateTime? _selectedDateTime;
  double _budget = 0.0;
  double _totalExpenses = 0.0;
  List<Map<String, dynamic>> _expenses = [];
  final double _warningThreshold = 0.8; // Warn at 80% of budget
  bool _hasShownWarning = false;

  @override
  void initState() {
    super.initState();
    fetchSupportedCurrencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTourSettings();
      _checkBudgetWarnings();
    });
  }

  // Helper method to safely parse doubles
  double safeParseDouble(String value, {double defaultValue = 0.0}) {
    try {
      double result = double.parse(value);
      if (result.isFinite) {
        return result;
      }
    } catch (e) {
      print('Error parsing double: $e');
    }
    return defaultValue;
  }

  Future<void> fetchSupportedCurrencies() async {
    var url = Uri.parse("https://openexchangerates.org/api/currencies.json");
    var headers = {
      'Authorization': '1d2ee0d621354de68804194ee0091dda',
    };

    try {
      var response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        setState(() {
          _supportedCurrencies = json.decode(response.body);
        });
      } else {
        print('Request failed with status: ${response.statusCode}.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Failed to fetch currencies: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      print('Error occurred: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching currencies: $e')),
        );
      }
    }
  }

  ////budget warning
  void _checkBudgetWarnings() {
    if (!_hasShownWarning && _budget > 0) {
      double usedPercentage = _totalExpenses / _budget;
      if (usedPercentage >= _warningThreshold && usedPercentage < 1.0) {
        _showBudgetWarningDialog(
            'Warning: You have used ${(usedPercentage * 100).toStringAsFixed(1)}% of your budget');
      } else if (usedPercentage >= 1.0) {
        _showBudgetExceededDialog();
      }
    }
  }

  Future<void> _showBudgetWarningDialog(String message) async {
    _hasShownWarning = true;
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Budget Warning'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showBudgetExceededDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Budget Exceeded'),
            ],
          ),
          content: const Text(
              'You have exceeded your budget. Would you like to extend your budget?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showExtendBudgetDialog();
              },
              child: const Text('Extend Budget'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showExtendBudgetDialog() async {
    final TextEditingController additionalBudgetController =
        TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Extend Budget'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Current Budget: $_selectedBaseCurrency ${_budget.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              TextField(
                controller: additionalBudgetController,
                decoration: const InputDecoration(
                  labelText: 'Additional Budget Amount',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.add_card),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (additionalBudgetController.text.isNotEmpty) {
                  double additionalAmount =
                      double.tryParse(additionalBudgetController.text) ?? 0;
                  if (additionalAmount > 0) {
                    await _extendBudget(additionalAmount);
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _extendBudget(double additionalAmount) async {
    try {
      double newBudget = _budget + additionalAmount;
      await _firestore.collection('tours').doc(_currentTourId).update({
        'budget': newBudget,
        'budgetHistory': FieldValue.arrayUnion([
          {
            'date': DateTime.now(),
            'previousBudget': _budget,
            'newBudget': newBudget,
            'increase': additionalAmount,
          }
        ]),
      });

      setState(() {
        _budget = newBudget;
        _hasShownWarning = false; // Reset warning flag after budget extension
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Budget extended by $_selectedBaseCurrency ${additionalAmount.toStringAsFixed(2)}')),
        );
      }
    } catch (e) {
      print('Error extending budget: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error extending budget: $e')),
        );
      }
    }
  }

  ///past tour
  Future<void> _showPastToursDialog() async {
    try {
      QuerySnapshot toursSnapshot = await _firestore
          .collection('tours')
          .orderBy('createdAt', descending: true)
          .get();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Past Tours',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      CloseButton(),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: toursSnapshot.docs.length,
                      itemBuilder: (context, index) {
                        var tour = toursSnapshot.docs[index].data()
                            as Map<String, dynamic>;
                        var tourId = toursSnapshot.docs[index].id;
                        var createdAt =
                            tour['createdAt']?.toDate() ?? DateTime.now();

                        return Card(
                          child: ListTile(
                            title: Text(
                                'Tour - ${DateFormat('MMM dd, yyyy').format(createdAt)}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Budget: ${tour['baseCurrency']} ${tour['budget']?.toStringAsFixed(2)}'),
                                Text(
                                    'Currencies: ${tour['baseCurrency']} → ${tour['foreignCurrency']}'),
                                if (tour['budgetHistory'] != null)
                                  Text(
                                      'Budget Extended: ${(tour['budgetHistory'] as List).length} times'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () => _showTourDetails(tourId),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      print('Error loading past tours: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading past tours: $e')),
        );
      }
    }
  }

  Future<void> _showTourDetails(String tourId) async {
    try {
      var tourDoc = await _firestore.collection('tours').doc(tourId).get();
      var expensesSnapshot = await _firestore
          .collection('tours')
          .doc(tourId)
          .collection('expenses')
          .orderBy('date')
          .get();

      if (!mounted) return;

      var tour = tourDoc.data() as Map<String, dynamic>;
      var expenses = expensesSnapshot.docs.map((doc) => doc.data()).toList();

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tour Details - ${DateFormat('MMM dd, yyyy').format(tour['createdAt'].toDate())}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const CloseButton(),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTourInfoCard(tour),
                          if (tour['budgetHistory'] != null)
                            _buildBudgetHistoryCard(tour['budgetHistory']),
                          _buildExpensesHistoryCard(expenses),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      print('Error loading tour details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tour details: $e')),
        );
      }
    }
  }

  Widget _buildTourInfoCard(Map<String, dynamic> tour) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tour Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Text(
                'Initial Budget: ${tour['baseCurrency']} ${tour['budget']?.toStringAsFixed(2)}'),
            Text('Base Currency: ${tour['baseCurrency']}'),
            Text('Foreign Currency: ${tour['foreignCurrency']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetHistoryCard(List<dynamic> budgetHistory) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Budget Extensions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: budgetHistory.length,
              itemBuilder: (context, index) {
                var extension = budgetHistory[index];
                return ListTile(
                  title: Text(
                      'Extended on ${DateFormat('MMM dd, yyyy').format(extension['date'].toDate())}'),
                  subtitle: Text(
                      'Increased by: ${extension['increase']?.toStringAsFixed(2)}'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesHistoryCard(List<dynamic> expenses) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Expenses History',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                var expense = expenses[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Icon(_getCategoryIcon(expense['category'])),
                  ),
                  title: Text(
                      '${expense['category']} - ${expense['convertedAmount']?.toStringAsFixed(2)}'),
                  subtitle: Text(
                    '${expense['notes']} - ${DateFormat('MMM dd, yyyy').format(expense['date'].toDate())}',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadTourSettings() async {
    try {
      if (_currentTourId == null) {
        QuerySnapshot tourSnapshot = await _firestore.collection('tours').get();
        if (tourSnapshot.docs.isNotEmpty) {
          setState(() {
            _currentTourId = tourSnapshot.docs.last.id;
          });
          await _fetchTourSettings();
          await _fetchExpenses();
        } else {
          _showNewTourDialog();
        }
      } else {
        await _fetchTourSettings();
        await _fetchExpenses();
      }
    } catch (e) {
      print('Error loading tour settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tour settings: $e')),
        );
      }
    }
  }

  Future<void> _fetchTourSettings() async {
    if (_currentTourId == null) return;

    try {
      DocumentSnapshot doc =
          await _firestore.collection('tours').doc(_currentTourId).get();
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          _selectedBaseCurrency = data['baseCurrency'];
          _selectedForeignCurrency = data['foreignCurrency'];
          var budgetValue = data['budget'];
          _budget = (budgetValue is num) ? budgetValue.toDouble() : 0.0;
          if (!_budget.isFinite) _budget = 0.0;
        });
      }
    } catch (e) {
      print('Error fetching tour settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching tour settings: $e')),
        );
      }
    }
  }

  Future<void> _fetchExpenses() async {
    if (_currentTourId == null) return;

    try {
      QuerySnapshot expensesSnapshot = await _firestore
          .collection('tours')
          .doc(_currentTourId)
          .collection('expenses')
          .orderBy('date', descending: true)
          .get();

      List<Map<String, dynamic>> expenses = [];
      double total = 0.0;

      for (var doc in expensesSnapshot.docs) {
        try {
          var data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;

          var amount = 0.0;
          if (data['convertedAmount'] is num) {
            amount = (data['convertedAmount'] as num).toDouble();
          }

          if (amount.isFinite) {
            total += amount;
            expenses.add(data);
          }
        } catch (e) {
          print('Error processing expense document: $e');
        }
      }

      setState(() {
        _expenses = expenses;
        _totalExpenses = total.isFinite ? total : 0.0;
      });
    } catch (e) {
      print('Error fetching expenses: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching expenses: $e')),
        );
      }
    }
  }

  Future<void> _saveExpense() async {
    if (_currentTourId == null ||
        _amountController.text.isEmpty ||
        _selectedCategory == null ||
        _selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    try {
      double amount = safeParseDouble(_amountController.text);
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount')),
        );
        return;
      }

      double conversionRate = await _fetchConversionRate(
        _selectedBaseCurrency,
        _selectedForeignCurrency,
      );

      double convertedAmount = amount * conversionRate;
      if (!convertedAmount.isFinite) {
        convertedAmount =
            amount; // Fallback to original amount if conversion fails
      }

      await _firestore
          .collection('tours')
          .doc(_currentTourId)
          .collection('expenses')
          .add({
        'amount': amount,
        'convertedAmount': convertedAmount,
        'category': _selectedCategory,
        'notes': _notesController.text,
        'date': _selectedDateTime,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _clearForm();
      await _fetchExpenses();
      _checkBudgetWarnings();

      setState(() {
        _isAddingExpense = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense saved successfully')),
        );
      }
    } catch (e) {
      print('Error saving expense: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving expense: $e')),
        );
      }
    }
  }

  Future<void> _startNewTour() async {
    try {
      double budget = safeParseDouble(_budgetController.text);
      if (budget <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid budget amount')),
        );
        return;
      }

      String tourId = DateTime.now().millisecondsSinceEpoch.toString();

      await _firestore.collection('tours').doc(tourId).set({
        'baseCurrency': _selectedBaseCurrency,
        'foreignCurrency': _selectedForeignCurrency,
        'budget': budget,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _currentTourId = tourId;
        _budget = budget;
        _expenses = [];
        _totalExpenses = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New tour created successfully')),
      );
    } catch (e) {
      print('Error creating new tour: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating new tour: $e')),
      );
    }
  }

  List<PieChartSectionData> _buildPieChartSections() {
    if (_totalExpenses <= 0) {
      return [
        PieChartSectionData(
          color: Colors.grey,
          value: 100,
          title: 'No Expenses',
          radius: 100,
          titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
        )
      ];
    }

    Map<String, double> categoryTotals = {};
    for (var expense in _expenses) {
      String category = expense['category'] as String;
      double amount = 0.0;
      if (expense['convertedAmount'] is num) {
        amount = (expense['convertedAmount'] as num).toDouble();
      }
      if (amount.isFinite) {
        categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      }
    }

    List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.yellow,
      Colors.purple,
    ];

    return categoryTotals.entries.map((entry) {
      int index = categoryTotals.keys.toList().indexOf(entry.key);
      double percentage =
          _totalExpenses > 0 ? (entry.value / _totalExpenses * 100) : 0;
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: entry.value,
        title: '${entry.key}\n${percentage.toStringAsFixed(1)}%',
        radius: 100,
        titleStyle: const TextStyle(color: Colors.white, fontSize: 12),
      );
    }).toList();
  }

  Future<void> _deleteTour() async {
    if (_currentTourId == null) return;

    try {
      // Delete all expenses for this tour
      QuerySnapshot expensesSnapshot = await _firestore
          .collection('tours')
          .doc(_currentTourId)
          .collection('expenses')
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in expensesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_firestore.collection('tours').doc(_currentTourId));
      await batch.commit();

      setState(() {
        _currentTourId = null;
        _selectedBaseCurrency = null;
        _selectedForeignCurrency = null;
        _budget = 0;
        _expenses = [];
        _totalExpenses = 0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tour deleted successfully')),
        );
        _showNewTourDialog();
      }
    } catch (e) {
      print('Error deleting tour: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting tour: $e')),
        );
      }
    }
  }

  Future<void> _deleteExpense(String expenseId) async {
    if (_currentTourId == null) return;

    try {
      await _firestore
          .collection('tours')
          .doc(_currentTourId)
          .collection('expenses')
          .doc(expenseId)
          .delete();

      await _fetchExpenses();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense deleted successfully')),
        );
      }
    } catch (e) {
      print('Error deleting expense: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting expense: $e')),
        );
      }
    }
  }

  Future<double> _fetchConversionRate(
      String? baseCurrency, String? foreignCurrency) async {
    if (baseCurrency == null || foreignCurrency == null) {
      return 1.0;
    }

    try {
      var url = Uri.parse(
          "https://openexchangerates.org/api/latest.json?app_id=1d2ee0d621354de68804194ee0091dda&base=$baseCurrency&symbols=$foreignCurrency");

      var response = await http.get(url);
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        var rate = data['rates'][foreignCurrency]?.toDouble();
        return rate?.isFinite == true ? rate! : 1.0;
      }
    } catch (e) {
      print('Error fetching conversion rate: $e');
    }
    return 1.0;
  }

  void _clearForm() {
    _amountController.clear();
    _dateController.clear();
    _notesController.clear();
    setState(() {
      _selectedCategory = null;
      _selectedDateTime = null;
    });
  }

  Widget _buildExpenseForm() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: [
                'Food',
                'Transport',
                'Entertainment',
                'Utilities',
                'Others'
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Date',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDateTime ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null) {
                  setState(() {
                    _selectedDateTime = pickedDate;
                    _dateController.text =
                        DateFormat('yyyy-MM-dd').format(pickedDate);
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _saveExpense,
              icon: const Icon(Icons.save),
              label: const Text('Save Expense'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Currency and Tour Management Methods
  Future<void> _showNewTourDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('New Tour Settings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _budgetController,
                  decoration: const InputDecoration(
                    labelText: 'Budget',
                    prefixIcon: Icon(Icons.account_balance_wallet),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownSearch<String>(
                  items: _supportedCurrencies.keys.toList(),
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "Base Currency",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.money),
                    ),
                  ),
                  onChanged: (value) =>
                      setState(() => _selectedBaseCurrency = value),
                  selectedItem: _selectedBaseCurrency,
                ),
                const SizedBox(height: 16),
                DropdownSearch<String>(
                  items: _supportedCurrencies.keys.toList(),
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "Foreign Currency",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.currency_exchange),
                    ),
                  ),
                  onChanged: (value) =>
                      setState(() => _selectedForeignCurrency = value),
                  selectedItem: _selectedForeignCurrency,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_budgetController.text.isNotEmpty &&
                    _selectedBaseCurrency != null &&
                    _selectedForeignCurrency != null) {
                  _budget = double.parse(_budgetController.text);
                  await _startNewTour();
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                }
              },
              child: const Text('Create Tour'),
            ),
          ],
        );
      },
    );
  }

  // UI Building Methods
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'new_tour':
                  _showNewTourDialog();
                  break;
                case 'past_tours':
                  _showPastToursDialog();
                  break;
                case 'extend_budget':
                  _showExtendBudgetDialog();
                  break;
                case 'delete_tour':
                  _deleteTour();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'new_tour',
                child: ListTile(
                  leading: Icon(Icons.add),
                  title: Text('New Tour'),
                ),
              ),
              const PopupMenuItem(
                value: 'past_tours',
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text('Past Tours'),
                ),
              ),
              const PopupMenuItem(
                value: 'extend_budget',
                child: ListTile(
                  leading: Icon(Icons.account_balance_wallet),
                  title: Text('Extend Budget'),
                ),
              ),
              const PopupMenuItem(
                value: 'delete_tour',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title:
                      Text('Delete Tour', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ],
      ),
      body: _currentTourId == null
          ? const Center(
              child: Text('No active tour. Please create a new tour to begin.'),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBudgetOverview(),
                  const SizedBox(height: 16),
                  if (!_isAddingExpense)
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _isAddingExpense = true),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Expense'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  if (_isAddingExpense) ...[
                    _buildExpenseForm(),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () => setState(() => _isAddingExpense = false),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _buildCharts(),
                  const SizedBox(height: 16),
                  _buildExpensesList(),
                ],
              ),
            ),
      floatingActionButton: !_isAddingExpense && _currentTourId != null
          ? FloatingActionButton(
              onPressed: () => setState(() => _isAddingExpense = true),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBudgetOverview() {
    double remainingBudget = _budget - _totalExpenses;
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                    child: _buildBudgetCard('Budget', _budget, Colors.blue)),
                const SizedBox(width: 4),
                Expanded(
                    child:
                        _buildBudgetCard('Spent', _totalExpenses, Colors.red)),
                const SizedBox(width: 4),
                Expanded(
                    child: _buildBudgetCard(
                        'Left', remainingBudget, Colors.green)),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _budget > 0
                  ? (_totalExpenses / _budget).clamp(0.0, 1.0)
                  : 0.0,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                remainingBudget > 0 ? Colors.blue : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(String title, double amount, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _selectedBaseCurrency ?? '',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                amount.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCharts() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Expense Breakdown',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sections: _buildPieChartSections(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesList() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _expenses.length,
              itemBuilder: (context, index) {
                final expense = _expenses[index];
                return ListTile(
                  leading: CircleAvatar(
                    child:
                        Icon(_getCategoryIcon(expense['category'] as String)),
                  ),
                  title: Text(
                    '${expense['category']} - ${_selectedBaseCurrency} ${expense['convertedAmount'].toStringAsFixed(2)}',
                  ),
                  subtitle: Text(
                    '${expense['notes']} - ${DateFormat('MMM dd, yyyy').format(expense['date'].toDate())}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteExpense(expense['id']),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'utilities':
        return Icons.build;
      default:
        return Icons.category;
    }
  }

  // Add the remaining methods (fetchSupportedCurrencies, _startNewTour, etc.) here...
}
