import 'package:client_info/sql/mysql_services.dart';
import 'package:flutter/material.dart';

class GeneralInfo extends StatefulWidget {
  final String selectedClient; // Add a parameter for selected client

  GeneralInfo({required this.selectedClient});

  @override
  _GeneralInfoState createState() => _GeneralInfoState();
}

class _GeneralInfoState extends State<GeneralInfo> {
  final MysqlService mysql = MysqlService(); // Instance of the Mysql class
  Map<String, dynamic>? clientDetails;
  bool isLoading = true; // To control the loading state

  @override
  void didUpdateWidget(covariant GeneralInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the selectedClient changes, reload the details
    if (oldWidget.selectedClient != widget.selectedClient) {
      _loadClientDetails();
    }
  }

  @override
  void initState() {
    super.initState();
    // Load the client details if the client is selected
    if (widget.selectedClient.isNotEmpty) {
      _loadClientDetails();
    }
  }

  // Fetch client details using the selected client name
  Future<void> _loadClientDetails() async {
    if (widget.selectedClient.isNotEmpty) {
      setState(() {
        isLoading = true;
      });

      var details = await mysql.getClientDetails(widget.selectedClient);

      setState(() {
        clientDetails = details;
        isLoading = false; // Stop loading once data is fetched
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If no client is selected or loading
    if (widget.selectedClient.isEmpty) {
      return Center(child: Text("Please select a client to view details."));
    }

    if (isLoading) {
      return Center(child: CircularProgressIndicator()); // Show loading spinner
    }

    if (clientDetails == null) {
      return Center(child: Text("No details available for this client."));
    }

    return ListView(
      padding: EdgeInsets.all(8),
      children: <Widget>[
        // General Info Section displaying client details
        Card(
          elevation: 5,
          margin: EdgeInsets.symmetric(vertical: 8),
          child: ExpansionTile(
            title: Text('Client Information'),
            subtitle: Text('Details of client ${widget.selectedClient}'),
            trailing: Icon(Icons.arrow_drop_down),
            children: <Widget>[
              ListTile(
                title: Text('Term: ${clientDetails!['term']}'),
              ),
              ListTile(
                title: Text('Short Address: ${clientDetails!['shortaddress']}'),
              ),
              ListTile(
                title: Text(
                    'Complete Address: ${clientDetails!['completeaddress']}'),
              ),
              ListTile(
                title: Text('Handler: ${clientDetails!['handler_name']}'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
