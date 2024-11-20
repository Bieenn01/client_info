import 'package:client_info/sql/mysql_services.dart';
import 'package:flutter/material.dart';

class Invoices extends StatefulWidget {
  @override
  _InvoicesState createState() => _InvoicesState();

}

class _InvoicesState extends State<Invoices> {
  final MysqlService mysql = MysqlService(); // Instance of the Mysql class

  bool isSearching = false;
  bool isClientSelected = false;
  String selectedClient = '';
  TextEditingController clientController = TextEditingController();
  String _searchQuery = '';
  List<String> clientSuggestions = [];

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    final clients = await mysql.getClients();
    setState(() {
      clientSuggestions = clients;
    });
  }

  Future<List<String>> _fetchFilteredNames(
      String query, List<String> suggestions) async {
    return suggestions
        .where((name) => name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(8),
      children: <Widget>[

        InputDecorator(
          decoration: InputDecoration(
            labelText: 'Client', // Label for the Client section
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (!isClientSelected) {
                          setState(() {
                            // Allow searching again if the client is not selected
                            isSearching = true;
                            _searchQuery = '';
                          });
                        }
                      },
                      child: AbsorbPointer(
                        absorbing:
                            isClientSelected, // Disable search if client is selected
                        child: Opacity(
                          opacity: isClientSelected
                              ? 0.5
                              : 1.0, // Adjust opacity if client is selected
                          child: isSearching
                              ? Autocomplete<String>(
                                  optionsBuilder: (TextEditingValue
                                      textEditingValue) async {
                                    if (textEditingValue.text.isEmpty) {
                                      return const Iterable<String>.empty();
                                    }

                                    final filteredNames =
                                        await _fetchFilteredNames(
                                            textEditingValue.text,
                                            clientSuggestions);
                                    final query =
                                        textEditingValue.text.toLowerCase();
                                    final suggestions =
                                        filteredNames.where((name) {
                                      final nameLower = name.toLowerCase();
                                      return nameLower.startsWith(query) ||
                                          nameLower.contains(query);
                                    }).toList();

                                    suggestions.sort((a, b) {
                                      final aLower = a.toLowerCase();
                                      final bLower = b.toLowerCase();
                                      if (aLower.startsWith(query) &&
                                          !bLower.startsWith(query)) {
                                        return -1;
                                      } else if (!aLower.startsWith(query) &&
                                          bLower.startsWith(query)) {
                                        return 1;
                                      }
                                      return aLower.compareTo(bLower);
                                    });

                                    return suggestions;
                                  },
                                  displayStringForOption: (String option) =>
                                      option,
                                  fieldViewBuilder: (context, controller,
                                      focusNode, onFieldSubmitted) {
                                    return TextField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      decoration: InputDecoration(
                                        hintText: 'Search Client...',
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 16.0),
                                      ),
                                    );
                                  },
                                  onSelected: (String selection) {
                                    setState(() {
                                      selectedClient = selection;
                                      isClientSelected =
                                          true; // Mark client as selected
                                      isSearching =
                                          false; // Stop searching once selected
                                    });
                                  },
                                )
                              : Row(
                                  children: [
                                    Icon(Icons.search,
                                        color: Colors.black, size: 30),
                                    SizedBox(width: 8),
                                    Text(
                                      selectedClient.isEmpty
                                          ? ''
                                          : selectedClient,
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        clientController.clear();
                        selectedClient = '';
                        isClientSelected = false; // Reset client selection
                        isSearching = false; // Reset search state
                      });
                    },
                    icon: Icon(Icons.refresh_sharp, color: Colors.black),
                    iconSize: 24,
                  ),
                ],
              ),
            ],
          ),
        ),
        Divider(),
        Card(
          elevation: 5,
          margin: EdgeInsets.symmetric(vertical: 8),
          child: ExpansionTile(
            title: Text('Invoices Section 1'),
            subtitle: Text('This is a description of Invoices Section 1.'),
            trailing: Icon(Icons.arrow_drop_down),
            children: <Widget>[
              ListTile(
                title: Text('Details for Invoices Section 1'),
              ),
              ListTile(
                title: Text('More Info for Invoices Section 1'),
              ),
            ],
          ),
        ),
        Card(
          elevation: 5,
          margin: EdgeInsets.symmetric(vertical: 8),
          child: ExpansionTile(
            title: Text('Invoices Section 2'),
            subtitle: Text('This is a description of Invoices Section 2.'),
            trailing: Icon(Icons.arrow_drop_down),
            children: <Widget>[
              ListTile(
                title: Text('Details for Invoices Section 2'),
              ),
              ListTile(
                title: Text('More Info for Invoices Section 2'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
