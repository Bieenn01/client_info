import 'package:client_info/Screens/general_info.dart';
import 'package:client_info/Screens/invoices.dart';
import 'package:client_info/Screens/postdate.dart';
import 'package:client_info/sql/mysql_services.dart';
import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final MysqlService mysql = MysqlService(); // Instance of the Mysql class

  bool isSearching = false;
  bool isClientSelected = false;
  String selectedClient = '';
  TextEditingController clientController = TextEditingController();
  List<String> clientSuggestions = [];

  int _selectedIndex = 0;

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Function to return the appropriate widget for the selected index
  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return GeneralInfo(selectedClient: selectedClient); // GeneralInfo page
      case 1:
        return Invoices(selectedClient: selectedClient); // Invoices page
      case 2:
        return PostDate(selectedClient: selectedClient,); // PostDate page
      default:
        return GeneralInfo(
            selectedClient: selectedClient); // Default to GeneralInfo
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 1, // Hides the app bar (optional)
      ),
      body: Column(
        children: [
          Divider(),
          // Search function UI
          InputDecorator(
            decoration: InputDecoration(
              labelText: 'Client', // Label for the Client section
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!isClientSelected) {
                            setState(() {
                              isSearching = true;
                              selectedClient = '';
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
                                        clientSuggestions,
                                      );
                                      return filteredNames;
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
                                        isClientSelected = true;
                                        isSearching = false;
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
                          // Clear the selected client and reset states
                          clientController.clear();
                          selectedClient = '';
                          isClientSelected = false;
                          isSearching = false;
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

          // Replace this section with the method _getSelectedPage()
          Expanded(child: _getSelectedPage()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'General Info',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Invoices',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Post Date',
          ),
        ],
      ),
    );
  }
}
