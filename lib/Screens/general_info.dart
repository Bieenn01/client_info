import 'package:client_info/sql/mysql_services.dart';
import 'package:flutter/material.dart';

// Assuming this method fetches the list of clients from the database
class GeneralInfo extends StatefulWidget {
  @override
  _GeneralInfoState createState() => _GeneralInfoState();
}

class _GeneralInfoState extends State<GeneralInfo> {
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
        // General Info Section 1 with InputDecorator for Client Selection
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
                                          } else if (!aLower
                                                  .startsWith(query) &&
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
                                            contentPadding:
                                                EdgeInsets.symmetric(
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
        // General Info Section 2 with ExpansionTile
        Card(
          elevation: 5,
          margin: EdgeInsets.symmetric(vertical: 8),
          child: ExpansionTile(
            title: Text('General Info Section 2'),
            subtitle: Text('This is a description of General Info Section 2.'),
            trailing: Icon(Icons.arrow_drop_down),
            children: <Widget>[
              ListTile(
                title: Text('Detail 1 for General Info Section 2'),
              ),
              ListTile(
                title: Text('Detail 2 for General Info Section 2'),
              ),
            ],
          ),
        ),

        // Optional: Add more sections as needed
        Card(
          elevation: 5,
          margin: EdgeInsets.symmetric(vertical: 8),
          child: ExpansionTile(
            title: Text('General Info Section 3'),
            subtitle: Text('This is a description of General Info Section 3.'),
            trailing: Icon(Icons.arrow_drop_down),
            children: <Widget>[
              ListTile(
                title: Text('Detail 1 for General Info Section 3'),
              ),
              ListTile(
                title: Text('Detail 2 for General Info Section 3'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
