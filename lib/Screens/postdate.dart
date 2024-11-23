import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:client_info/sql/mysql_services.dart';
import 'package:client_info/formatdate.dart';

class PostDate extends StatefulWidget {
  final String
      selectedClient; // Pass the selected client to the PostDate screen

  PostDate({required this.selectedClient});

  @override
  _PostDateState createState() => _PostDateState();
}

class _PostDateState extends State<PostDate> {
  final MysqlService mysql = MysqlService(); // Instance of the Mysql class

  bool isLoading = true; // To control loading state
  List<Map<String, dynamic>> postDates =
      []; // List to hold fetched post date payments
  Map<int, bool> expandedPostDateStates =
      {}; // Track expanded states for each post date
  Map<int, bool> expandedTransactionStates =
      {}; // Track expanded states for transaction details
  Set<int> selectedPostDates = {}; // Set to store selected post date indices

  Set<int> selectedTransactions = {};
  double totalSelectedAmount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.selectedClient.isNotEmpty) {
      _loadPostDates();
    }
  }

  @override
  void didUpdateWidget(covariant PostDate oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the selected client changes, reload the post date payments
    if (oldWidget.selectedClient != widget.selectedClient) {
      _loadPostDates();
    }
  }

  // Fetch post date payments using the selected client's name
  Future<void> _loadPostDates() async {
    if (widget.selectedClient.isNotEmpty) {
      setState(() {
        isLoading = true;
      });

      try {
        var postData = await mysql.getPostDates(widget.selectedClient);

        setState(() {
          postDates = postData;
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
            content:
                Text("Failed to load post date payments. Please try again."),
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

  // Fetch transaction details for a specific payment_id
  Future<List<Map<String, dynamic>>> _fetchTransactionDetails(
      String paymentId) async {
    try {
      return await mysql.getTransactionDetails(paymentId);
    } catch (e) {
      print('Error fetching transaction details: $e');
      throw Exception('Failed to fetch transaction details');
    }
  }

  // Calculate the total amount of selected post date payments
  double getTotalAmount() {
    double totalAmount = 0.0;
    for (var index in selectedPostDates) {
      totalAmount += postDates[index]['amount'];
    }
    return totalAmount;
  }

   Future<Map<String, dynamic>> _fetchPaymentDetails(String paymentId) async {
    try {
      return await mysql.getPaymentDetails(paymentId);
    } catch (e) {
      print('Error fetching payment details: $e');
      throw Exception('Failed to fetch payment details');
    }
  }

 @override
  Widget build(BuildContext context) {
    if (widget.selectedClient.isEmpty) {
      return Center(
          child: Text("Please select a client to view post date payments."));
    }

    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (postDates.isEmpty) {
      return Center(
          child: Text("No post date payments found for this client."));
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(8),
            children: <Widget>[
              Divider(),
              // PostDate list display
              ...postDates.map((postDate) {
                int index = postDates.indexOf(postDate);
                bool isExpanded = expandedPostDateStates[index] ?? false;

                return Card(
                  elevation: 5,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text('Payment ID: ${postDate['id']}'),
                        subtitle: Text(
                            'Amount: \₱${NumberFormat('#,###.00', 'en_PH').format(postDate['amount'] as double)}'),
                        trailing:
                            Text('Date: ${formatDate(postDate['dateclear'])}'),
                        leading: Checkbox(
                          value: selectedPostDates.contains(index),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedPostDates.add(index);
                              } else {
                                selectedPostDates.remove(index);
                              }
                            });
                          },
                        ),
                        onTap: () {
                          setState(() {
                            expandedPostDateStates[index] = !isExpanded;
                          });
                        },
                      ),
                      // Only show the first expansion (Payment Details) if the tile is expanded
                      if (isExpanded)
                        ExpansionTile(
                          title: Text('Payment Details'),
                          children: <Widget>[
                            FutureBuilder<Map<String, dynamic>>(
                              future: _fetchPaymentDetails(postDate['id']),
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
                                    child:
                                        Text('Failed to load payment details.'),
                                  );
                                } else if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return Padding(
                                    padding: EdgeInsets.all(16),
                                    child:
                                        Text('No payment details available.'),
                                  );
                                }

                                var paymentDetails = snapshot.data!;

                                return Column(
                                  children: [
                                    ListTile(
                                      title: Text(
                                          'Type: ${paymentDetails['type']}'),
                                    ),
                                    ListTile(
                                      title: Text(
                                        'Amount: \₱${NumberFormat('#,###.00', 'en_PH').format(paymentDetails['amount'] as double)}',
                                      ),
                                    ),
                                    ListTile(
                                      title: Text(
                                          'Date Cleared: ${formatDate(paymentDetails['dateclear'])}'),
                                    ),
                                    ListTile(
                                      title: Text(
                                          'Date: ${formatDate(paymentDetails['datetime'])}'),
                                    ),
                                  ],
                                );
                              },
                            ),
                            // Second Expansion Tile for Transaction Details
                            ExpansionTile(
                              title: Text('Transaction Details'),
                              children: <Widget>[
                                FutureBuilder<List<Map<String, dynamic>>>(
                                  future: _fetchTransactionDetails(postDate['id']),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.active) {
                                      return Padding(
                                        padding: EdgeInsets.all(16),
                                        child: CircularProgressIndicator(),
                                      );
                                    } else if (snapshot.hasError) {
                                      return Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text('Failed to load transaction details.'),
                                      );
                                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                      return Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text('No transaction details available.'),
                                      );
                                    }

                                    var transactions = snapshot.data!;

                                    return SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Table(
                                          border: TableBorder.all(color: Colors.grey, width: 1),
                                          columnWidths: {
                                            0: FixedColumnWidth(150),
                                            1: FixedColumnWidth(200),
                                            2: FixedColumnWidth(150),
                                            3: FixedColumnWidth(120),
                                            4: FixedColumnWidth(50), // Added column for checkbox
                                          },
                                          children: [
                                            // Header Row with checkbox column
                                            TableRow(
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200], // Background color for header
                                              ),
                                              children: [
                                                TableCell(
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    child: Text('Client',
                                                        style: TextStyle(fontWeight: FontWeight.bold)),
                                                  ),
                                                ),
                                                TableCell(
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    child: Text('Payment Date',
                                                        style: TextStyle(fontWeight: FontWeight.bold)),
                                                  ),
                                                ),
                                                TableCell(
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    child: Text('Ref No.',
                                                        style: TextStyle(fontWeight: FontWeight.bold)),
                                                  ),
                                                ),
                                                TableCell(
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    child: Text('Amount',
                                                        style: TextStyle(fontWeight: FontWeight.bold)),
                                                  ),
                                                ),
                                                TableCell(
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    child: Text('',
                                                        style: TextStyle(fontWeight: FontWeight.bold)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            // Transaction Rows with checkboxes
                                            ...transactions.asMap().entries.map((entry) {
                                              int index = entry.key;
                                              var transaction = entry.value;

                                              return TableRow(
                                                children: [
                                                  TableCell(
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Text(transaction['name'] ?? 'N/A'),
                                                    ),
                                                  ),
                                                  TableCell(
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Text(formatDate(transaction['datetime'])),
                                                    ),
                                                  ),
                                                  TableCell(
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Text(transaction['ref'] ?? 'N/A'),
                                                    ),
                                                  ),
                                                  TableCell(
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(8.0),
                                                      child: Text(
                                                          '₱${NumberFormat('#,###.00', 'en_PH').format(transaction['transaction_amount'] as double)}'),
                                                    ),
                                                  ),
                                                  TableCell(
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(0),
                                                      child: Checkbox(
                                                        value: selectedTransactions.contains(index),
                                                        onChanged: (bool? value) {
                                                          setState(() {
                                                            if (value == true) {
                                                              selectedTransactions.add(index);
                                                              totalSelectedAmount += transaction['transaction_amount'] as double;
                                                            } else {
                                                              selectedTransactions.remove(index);
                                                              totalSelectedAmount -= transaction['transaction_amount'] as double;
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
                                      ),
                                    );
                                  },
                                ),
                                // Display total sum of selected transactions
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'Total Selected Amount: \₱${NumberFormat('#,###.00', 'en_PH').format(totalSelectedAmount)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
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
        if (selectedPostDates.isNotEmpty)
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
