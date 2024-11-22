import 'package:client_info/formatdate.dart';
import 'package:client_info/sql/mysql_services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  Set<int> selectedPostDates = {}; // Set to store selected post date indices

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

  // Calculate the total amount of selected post date payments
  double getTotalAmount() {
    double totalAmount = 0.0;
    for (var index in selectedPostDates) {
      totalAmount += postDates[index]['amount'];
    }
    return totalAmount;
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
                int index = postDates
                    .indexOf(postDate); // Get the index of the post date
                bool isExpanded = expandedPostDateStates[index] ??
                    false; // Get the expanded state

                return Card(
                  elevation: 5,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text('Payment ID: ${postDate['id']}'),
                        subtitle: Text(
                          'Amount: \₱${(postDate['amount'] as double).toStringAsFixed(2)}', // Round amount
                        ),
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
                            // Toggle the expansion state when the user taps
                            expandedPostDateStates[index] = !isExpanded;
                          });
                        },
                      ),
                      // Only show the additional details if the tile is expanded
                      if (isExpanded)
                        ExpansionTile(
                          title: Text('Additional Post Date Details'),
                          children: <Widget>[
                            ListTile(
                              title: Text('Type: ${postDate['type']}'),
                            ),
                            ListTile(
                              title: Text(
                                'Amount: \₱${NumberFormat('#,###.00', 'en_PH').format(postDate['amount'] as double)}', // Comma formatted amount with 2 decimal places
                              ),
                            ),
                            ListTile(
                              title: Text(
                                'Date Cleared: ${formatDate(postDate['dateclear'])}',
                              ),
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
        // Display total amount of selected post date payments
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
