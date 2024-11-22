import 'package:client_info/formatdate.dart';
import 'package:client_info/sql/mysql_services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Invoices extends StatefulWidget {
  final String
      selectedClient; // Pass the selected client to the invoices screen

  Invoices({required this.selectedClient});

  @override
  _InvoicesState createState() => _InvoicesState();
}

class _InvoicesState extends State<Invoices> {
  final MysqlService mysql = MysqlService(); // Instance of the Mysql class

  bool isLoading = true; // To control loading state
  List<Map<String, dynamic>> invoices = []; // List to hold fetched invoices
  Map<int, bool> expandedInvoiceStates =
      {}; // For expanding the invoice details
  Set<int> selectedInvoices = {}; // Set to store selected invoice indices

  @override
  void initState() {
    super.initState();
    if (widget.selectedClient.isNotEmpty) {
      _loadInvoices();
    }
  }

  @override
  void didUpdateWidget(covariant Invoices oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the selected client changes, reload the invoices
    if (oldWidget.selectedClient != widget.selectedClient) {
      _loadInvoices();
    }
  }

  // Fetch invoices using the selected client's name
  Future<void> _loadInvoices() async {
    if (widget.selectedClient.isNotEmpty) {
      setState(() {
        isLoading = true;
      });

      try {
        var invoiceData = await mysql.getInvoices(widget.selectedClient);

        setState(() {
          invoices = invoiceData;
          isLoading = false;
        });
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        // Show error message if an exception occurs
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Error"),
            content: Text("Failed to load invoices. Please try again."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("OK"),
              ),
            ],
          ),
        );
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Calculate the total amount of selected invoices
  double getTotalAmount() {
    double totalAmount = 0.0;
    for (var index in selectedInvoices) {
      totalAmount += invoices[index]['amount'];
    }
    return totalAmount;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedClient.isEmpty) {
      return Center(child: Text("Please select a client to view invoices."));
    }

    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (invoices.isEmpty) {
      return Center(child: Text("No unpaid invoices found for this client."));
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(8),
            children: <Widget>[
              Divider(),
              // Invoices list display
              ...invoices.map((invoice) {
                int index =
                    invoices.indexOf(invoice); // Get the index of the invoice
                bool isExpanded = expandedInvoiceStates[index] ??
                    false; // Get the expanded state

                return Card(
                  elevation: 5,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text('Invoice Ref: ${invoice['ref']}'),
                        subtitle: Text(
                          'Amount: \₱${NumberFormat('#,###.00', 'en_PH').format(invoice['amount'] as double)}', // Format with commas and 2 decimal places
                        ),
                        trailing:
                            Text('Due: ${formatDate(invoice['due_date'])}'),
                        onTap: () {
                          setState(() {
                            // Toggle the expansion state when the user taps
                            expandedInvoiceStates[index] = !isExpanded;
                          });
                        },
                        leading: Checkbox(
                          value: selectedInvoices.contains(index),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedInvoices.add(index);
                              } else {
                                selectedInvoices.remove(index);
                              }
                            });
                          },
                        ),
                      ),
                      // Only show the additional details if the tile is expanded
                      if (isExpanded)
                        ExpansionTile(
                          title: Text('Additional Invoice Details'),
                          children: <Widget>[
                            ListTile(
                              title:
                                  Text('Date: ${formatDate(invoice['date'])}'),
                            ),
                            ListTile(
                              title: Text(
                                'Balance: \₱${NumberFormat('#,###.00', 'en_PH').format(invoice['balance'] as double)}', // Comma formatted balance with 2 decimal places
                              ),
                            ),
                            ListTile(
                              title: Text('Order ID: ${invoice['order_id']}'),
                            ),
                            ListTile(
                              title: Text(
                                  'Collection Date: ${formatDate(invoice['collection_date'])}'),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        // Display total amount of selected invoices
        if (selectedInvoices.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Total Amount: \₱${NumberFormat('#,###.00', 'en_PH').format(getTotalAmount())}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
      ],
    );
  }
}
