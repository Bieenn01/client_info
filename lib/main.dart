import 'package:client_info/Screens/general_info.dart';
import 'package:client_info/Screens/invoices.dart';
import 'package:client_info/Screens/postdate.dart';
import 'package:client_info/sql/mysql_services.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

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

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = [
    GeneralInfo(),
    Invoices(),
    PostDate(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Main Scaffold')),
      body: Stack(
        children: [
          // Main input field and client selection logic
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
                                              clientSuggestions);
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

          // Drawer and content, this is now handled by the main Scaffold, not a nested one.
          Positioned.fill(
            child: Column(
              children: [
                Expanded(
                  child: Scaffold(
                    backgroundColor: Colors.transparent,
                    drawer: Drawer(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: <Widget>[
                          Divider(),
                          ListTile(
                            leading: Icon(Icons.home),
                            title: Text('General Info'),
                            onTap: () {
                              _onItemTapped(0);
                              Navigator.pop(context); // Close the drawer
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.person),
                            title: Text('Open Invoices'),
                            onTap: () {
                              _onItemTapped(1);
                              Navigator.pop(context); // Close the drawer
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.settings),
                            title: Text('Post Date'),
                            onTap: () {
                              _onItemTapped(2);
                              Navigator.pop(context); // Close the drawer
                            },
                          ),
                        ],
                      ),
                    ),
                    body: Center(
                        child: Text(
                            'Page Content Here')), // Placeholder for actual page content
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



