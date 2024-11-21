import 'package:client_info/formatdate.dart';
import 'package:client_info/sql/mysql_services.dart';
import 'package:flutter/material.dart';

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

  Map<int, bool> expandedInvoiceStates = {};

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

    return ListView(
      padding: EdgeInsets.all(8),
      children: <Widget>[
        // Invoices List
        Card(
          elevation: 5,
          margin: EdgeInsets.symmetric(vertical: 8),
          child: ExpansionTile(
            title: Text('Invoices for ${widget.selectedClient}'),
            subtitle: Text(''),
            trailing: Icon(Icons.arrow_drop_down),
            children: invoices.map((invoice) {
              int index = invoices.indexOf(invoice);

              return ExpansionTile(
                title: Text('Invoice Ref: ${invoice['ref']}'),
                subtitle: Text('Amount: \₱${invoice['amount']}'),
                trailing: Text('Due: ${formatDate(invoice['due_date'])}'),
                onExpansionChanged: (bool expanded) {
                  setState(() {
                    expandedInvoiceStates[index] = expanded;
                  });
                },
                children: <Widget>[
                  // Additional details inside the first ExpansionTile
                  ExpansionTile(
                    title: Text('Additional Invoice Details'),
                    children: <Widget>[
                      ListTile(
                        title: Text('Date: ${formatDate(invoice['date'])}'),
                      ),
                      ListTile(
                        title: Text('Balance: \₱${invoice['balance']}'),
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
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
