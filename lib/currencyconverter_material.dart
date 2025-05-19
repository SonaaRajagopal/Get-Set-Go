import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dropdown_search/dropdown_search.dart';

class CurrencyConverterMaterialPage extends StatefulWidget {
  const CurrencyConverterMaterialPage({super.key});

  @override
  _CurrencyConverterMaterialPageState createState() => _CurrencyConverterMaterialPageState();
}

class _CurrencyConverterMaterialPageState extends State<CurrencyConverterMaterialPage> {
  final TextEditingController _amountController = TextEditingController();
  String _conversionResult = '';
  Map<String, dynamic> _supportedCurrencies = {};
  String? _fromCurrency;
  String? _toCurrency;

  @override
  void initState() {
    super.initState();
    fetchSupportedCurrencies();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // Method to fetch supported currencies
  Future<void> fetchSupportedCurrencies() async {
    var url = Uri.parse("https://openexchangerates.org/api/currencies.json");
    var headers = {
      'Authorization': '1d2ee0d621354de68804194ee0091dda', // Replace with your actual API key
    };

    try {
      var response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          _supportedCurrencies = data;

        });
      } else {
        print('Request failed with status: ${response.statusCode}.');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  // Placeholder method for conversion (you'll need to implement the actual conversion logic)
  Future<void> convertCurrency() async {
    if (_fromCurrency != null && _toCurrency != null && _amountController.text.isNotEmpty) {
      var amount = double.tryParse(_amountController.text);

      if (amount != null) {
        var url = Uri.parse(
            "https://openexchangerates.org/api/latest.json?app_id=1d2ee0d621354de68804194ee0091dda"
        );

        try {
          var response = await http.get(url);

          if (response.statusCode == 200) {
            var data = json.decode(response.body);
            var fromRate = data['rates'][_fromCurrency];
            var toRate = data['rates'][_toCurrency];

            if (fromRate != null && toRate != null) {
              var convertedAmount = (amount / fromRate) * toRate;

              setState(() {
                _conversionResult = 'Converted amount: ${convertedAmount.toStringAsFixed(2)} $_toCurrency';
              });
            } else {
              setState(() {
                _conversionResult = 'Error: Could not retrieve exchange rates for selected currencies.';
              });
            }
          } else {
            setState(() {
              _conversionResult = 'Error: Request failed with status: ${response.statusCode}.';
            });
          }
        } catch (e) {
          setState(() {
            _conversionResult = 'Error occurred: $e';
          });
        }
      } else {
        setState(() {
          _conversionResult = 'Please enter a valid amount.';
        });
      }
    } else {
      setState(() {
        _conversionResult = 'Please select currencies and enter an amount.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('CurrencyConverterMaterialPage loaded');
    return Scaffold(
      backgroundColor: const Color.fromRGBO(240, 248, 255, 1),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Currency Converter",
                  style: TextStyle(
                    fontSize: 30,
                    color: Color.fromRGBO(8, 14, 44, 1),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                DropdownSearch<String>(
                  popupProps: const PopupProps.bottomSheet(
                    showSearchBox: true,
                  ),
                  items: _supportedCurrencies.keys.map((code) {
                    return '$code - ${_supportedCurrencies[code]}';
                  }).toList(),
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "From Currency",
                      filled: true,
                      fillColor: Color.fromRGBO(173, 216, 230, 0.25),
                      prefixIcon: Icon(Icons.monetization_on),
                      prefixIconColor: Color.fromRGBO(8, 14, 44, 1),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.black,
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.black,
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _fromCurrency = value?.split(' - ')[0];
                    });
                  },
                  selectedItem: _fromCurrency != null
                      ? '$_fromCurrency - ${_supportedCurrencies[_fromCurrency]}'
                      : null,
                ),
                const SizedBox(height: 20),
                DropdownSearch<String>(
                  popupProps: const PopupProps.bottomSheet(
                    showSearchBox: true,
                  ),
                  items: _supportedCurrencies.keys.map((code) {
                    return '$code - ${_supportedCurrencies[code]}';
                  }).toList(),
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: "To Currency",
                      filled: true,
                      fillColor: Color.fromRGBO(173, 216, 230, 0.25),
                      prefixIcon: Icon(Icons.monetization_on),
                      prefixIconColor: Color.fromRGBO(8, 14, 44, 1),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.black,
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.black,
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _toCurrency = value?.split(' - ')[0];
                    });
                  },
                  selectedItem: _toCurrency != null
                      ? '$_toCurrency - ${_supportedCurrencies[_toCurrency]}'
                      : null,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    hintText: "Please Enter the Amount",
                    hintStyle: TextStyle(color: Color.fromRGBO(8, 14, 44, 1)),
                    filled: true,
                    fillColor: Color.fromRGBO(173, 216, 230, 0.25),
                    prefixIcon: Icon(Icons.monetization_on),
                    prefixIconColor: Color.fromRGBO(8, 14, 44, 1),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.black,
                        width: 2.0,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.black,
                        width: 2.0,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: convertCurrency,
                  child: const Text("Convert"),
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                      Navigator.pushNamed(context, '/camera');
                      },
                  child: const Text("Camera"),
                ),
                Text(
                  _conversionResult,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(0, 23, 45,1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text('Currency Converter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: () {
              Navigator.pushNamed(context, '/expense-tracker');
            },
          ),
        ],
      ),
    );
  }
}
