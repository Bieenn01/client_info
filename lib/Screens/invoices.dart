import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:client_info/sql/mysql_services.dart';
import 'package:client_info/formatdate.dart';


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

  Set<int> selectedProducts = {};
  double totalSelectedProductAmount = 0;

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

    // Calculate the total amount of selected invoices
  double getTotalAmount() {
    double totalAmount = 0.0;
    for (var index in selectedInvoices) {
      totalAmount += invoices[index]['amount'];
    }
    return totalAmount;
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

  // Fetch the details for an Order ID
  Future<Map<String, dynamic>> _fetchOrderDetails(String orderId) async {
    try {
      return await mysql.getOrderDetails(orderId);
    } catch (e) {
      print('Error fetching order details: $e');
      throw Exception('Failed to fetch order details');
    }
  }

  // Fetch the product order details for a specific order ID
  Future<List<Map<String, dynamic>>> _fetchProductDetails(
      String orderId) async {
    try {
      var results = await mysql.getProductDetails(orderId);
      return results;
    } catch (e) {
      print('Error fetching product details: $e');
      throw Exception('Failed to fetch product details');
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
                            // Order ID - ExpansionTile with FutureBuilder
                            ExpansionTile(
                              title: Text('Order ID: ${invoice['order_id']}'),
                              children: <Widget>[
                                FutureBuilder<Map<String, dynamic>>(
                                  future:
                                      _fetchOrderDetails(invoice['order_id']),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.active) {
                                      return Padding(
                                        padding: EdgeInsets.all(16),
                                        child: CircularProgressIndicator(),
                                      );
                                    } else if (snapshot.hasError) {
                                      return Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text(
                                            'Failed to load order details.'),
                                      );
                                    } else if (!snapshot.hasData ||
                                        snapshot.data!.isEmpty) {
                                      return Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text(
                                            'No details available for this order.'),
                                      );
                                    }

                                    var orderDetails = snapshot.data!;

                                    return Column(
                                      children: [
                                        ListTile(
                                          title: Text(
                                              'Client Name: ${orderDetails['client_name']}'),
                                        ),
                                        ListTile(
                                          title: Text(
                                              'Order Type: ${orderDetails['type']}'),
                                        ),
                                        ListTile(
                                          title: Text(
                                              'Delivery: ${orderDetails['delivery']}'),
                                        ),
                                        ListTile(
                                          title: Text(
                                              'Finish Time: ${formatDate(orderDetails['finishtime'])}'),
                                        ),
                                        ListTile(
                                          title: Text(
                                              'Remarks: ${orderDetails['remarks']}'),
                                        ),
                                        ListTile(
                                          title: Text(
                                              'Packs: ${orderDetails['packs']}'),
                                        ),
                                        ListTile(
                                          title: Text(
                                              'Created: ${formatDate(orderDetails['created'])}'),
                                        ),
                                        ListTile(
                                          title: Text(
                                              'Saved: ${formatDate(orderDetails['saved'])}'),
                                        ),
                                        ListTile(
                                          title: Text(
                                              'Total: ₱${NumberFormat('#,###.00', 'en_PH').format(orderDetails['total'] as double)}'),
                                        ),
                                        ListTile(
                                          title: Text(
                                              'Source Location: ${orderDetails['source_location']}'),
                                        ),
                                        ListTile(
                                          title: Text(
                                              'Complete Location: ${orderDetails['complete_location']}'),
                                        ),
                                        // Second ExpansionTile for Product Details
                                        FutureBuilder<
                                            List<Map<String, dynamic>>>(
                                          future: _fetchProductDetails(
                                              invoice['order_id']),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.active) {
                                              return Padding(
                                                padding: EdgeInsets.all(16),
                                                child:
                                                    CircularProgressIndicator(),
                                              );
                                            } else if (snapshot.hasError) {
                                              return Padding(
                                                padding: EdgeInsets.all(16),
                                                child: Text(
                                                    'Failed to load product details.'),
                                              );
                                            } else if (!snapshot.hasData ||
                                                snapshot.data!.isEmpty) {
                                              return Padding(
                                                padding: EdgeInsets.all(16),
                                                child: Text(
                                                    'No product details available for this order.'),
                                              );
                                            }

                                            return ExpansionTile(
                                              title: Text('Product Details'),
                                              children: <Widget>[
                                                FutureBuilder<
                                                    List<Map<String, dynamic>>>(
                                                  future: _fetchProductDetails(
                                                      invoice['order_id']),
                                                  builder: (context,
                                                      productSnapshot) {
                                                    if (productSnapshot
                                                            .connectionState ==
                                                        ConnectionState
                                                            .active) {
                                                      return Padding(
                                                        padding:
                                                            EdgeInsets.all(16),
                                                        child:
                                                            CircularProgressIndicator(),
                                                      );
                                                    } else if (productSnapshot
                                                        .hasError) {
                                                      return Padding(
                                                        padding:
                                                            EdgeInsets.all(16),
                                                        child: Text(
                                                            'Failed to load product details.'),
                                                      );
                                                    } else if (!productSnapshot
                                                            .hasData ||
                                                        productSnapshot
                                                            .data!.isEmpty) {
                                                      return Padding(
                                                        padding:
                                                            EdgeInsets.all(16),
                                                        child: Text(
                                                            'No product details available.'),
                                                      );
                                                    }

                                                    var productDetails =
                                                        productSnapshot.data!;

                                                    return Padding(
                                                      padding:
                                                          EdgeInsets.all(0),
                                                      child:
                                                          SingleChildScrollView(
                                                        scrollDirection: Axis
                                                            .horizontal, // Enables horizontal scrolling
                                                        child: Column(
                                                          children: [
                                                            Table(
                                                              border:
                                                                  TableBorder
                                                                      .all(
                                                                color:
                                                                    Colors.grey,
                                                                width: 1,
                                                              ),
                                                              columnWidths: {
                                                                0: FixedColumnWidth(
                                                                    200),
                                                                1: FixedColumnWidth(
                                                                    120),
                                                                2: FixedColumnWidth(
                                                                    120),
                                                                3: FixedColumnWidth(
                                                                    120),
                                                                4: FixedColumnWidth(
                                                                    120),
                                                                5: FixedColumnWidth(
                                                                    50), // Added column for checkbox
                                                              },
                                                              children: [
                                                                // Header Row with background color for better readability
                                                                TableRow(
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors
                                                                            .grey[
                                                                        200], // Light grey background for header
                                                                  ),
                                                                  children: [
                                                                    TableCell(
                                                                      child:
                                                                          Padding(
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            8.0),
                                                                        child:
                                                                            Text(
                                                                          'Product',
                                                                          style:
                                                                              TextStyle(fontWeight: FontWeight.bold),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    TableCell(
                                                                      child:
                                                                          Padding(
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            8.0),
                                                                        child:
                                                                            Text(
                                                                          'Order Quantity',
                                                                          style:
                                                                              TextStyle(fontWeight: FontWeight.bold),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    TableCell(
                                                                      child:
                                                                          Padding(
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            8.0),
                                                                        child:
                                                                            Text(
                                                                          'Allotted Quantity',
                                                                          style:
                                                                              TextStyle(fontWeight: FontWeight.bold),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    TableCell(
                                                                      child:
                                                                          Padding(
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            8.0),
                                                                        child:
                                                                            Text(
                                                                          'Served Quantity',
                                                                          style:
                                                                              TextStyle(fontWeight: FontWeight.bold),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    TableCell(
                                                                      child:
                                                                          Padding(
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            8.0),
                                                                        child:
                                                                            Text(
                                                                          'Total',
                                                                          style:
                                                                              TextStyle(fontWeight: FontWeight.bold),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    TableCell(
                                                                      child:
                                                                          Padding(
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            8.0),
                                                                        child:
                                                                            Text(
                                                                          '',
                                                                          style:
                                                                              TextStyle(fontWeight: FontWeight.bold),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                // Product Details Rows (data rows)
                                                                ...productDetails
                                                                    .asMap()
                                                                    .entries
                                                                    .map(
                                                                        (entry) {
                                                                  int index =
                                                                      entry.key;
                                                                  var product =
                                                                      entry
                                                                          .value;

                                                                  return TableRow(
                                                                    children: [
                                                                      TableCell(
                                                                        child:
                                                                            Padding(
                                                                          padding: const EdgeInsets
                                                                              .all(
                                                                              8.0),
                                                                          child:
                                                                              Text('${product['name']}'),
                                                                        ),
                                                                      ),
                                                                      TableCell(
                                                                        child:
                                                                            Padding(
                                                                          padding: const EdgeInsets
                                                                              .all(
                                                                              8.0),
                                                                          child:
                                                                              Text('${product['order_quantity']}'),
                                                                        ),
                                                                      ),
                                                                      TableCell(
                                                                        child:
                                                                            Padding(
                                                                          padding: const EdgeInsets
                                                                              .all(
                                                                              8.0),
                                                                          child:
                                                                              Text('${product['alotted_quantity']}'),
                                                                        ),
                                                                      ),
                                                                      TableCell(
                                                                        child:
                                                                            Padding(
                                                                          padding: const EdgeInsets
                                                                              .all(
                                                                              8.0),
                                                                          child:
                                                                              Text('${product['served_quantity']}'),
                                                                        ),
                                                                      ),
                                                                      TableCell(
                                                                        child:
                                                                            Padding(
                                                                          padding: const EdgeInsets
                                                                              .all(
                                                                              8.0),
                                                                          child:
                                                                              Text(
                                                                            '₱${NumberFormat('#,###.00', 'en_PH').format(product['total'] as double)}',
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      TableCell(
                                                                        child:
                                                                            Padding(
                                                                          padding: const EdgeInsets
                                                                              .all(
                                                                              0),
                                                                          child:
                                                                              Checkbox(
                                                                            value:
                                                                                selectedProducts.contains(index),
                                                                            onChanged:
                                                                                (bool? value) {
                                                                              setState(() {
                                                                                if (value == true) {
                                                                                  selectedProducts.add(index);
                                                                                  totalSelectedProductAmount += product['total'] as double;
                                                                                } else {
                                                                                  selectedProducts.remove(index);
                                                                                  totalSelectedProductAmount -= product['total'] as double;
                                                                                }
                                                                              });
                                                                            },
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  );
                                                                }).toList(),
                                                              ],
                                                            ),
                                                            // Display total selected amount
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(8.0),
                                                              child: Text(
                                                                'Total Selected Amount: \₱${NumberFormat('#,###.00', 'en_PH').format(totalSelectedProductAmount)}',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .green,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                            ListTile(
                              title: Text(
                                  'Collection Date: ${formatDate(invoice['collection_date'])}'),
                            )
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
