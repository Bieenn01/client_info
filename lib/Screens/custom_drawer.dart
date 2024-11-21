// import 'package:client_info/Screens/general_info.dart';
// import 'package:client_info/Screens/invoices.dart';
// import 'package:client_info/Screens/postdate.dart';
// import 'package:client_info/sql/mysql_services.dart';
// import 'package:flutter/material.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Client Info',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: MyHomePage(),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   @override
//   _MyHomePageState createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   final MysqlService mysql = MysqlService(); // Instance of the Mysql class

//   bool isSearching = false;
//   bool isClientSelected = false;
//   String selectedClient = '';
//   TextEditingController clientController = TextEditingController();
//   List<String> clientSuggestions = [];

//   int _selectedIndex = 0;

//   @override
//   void initState() {
//     super.initState();
//     _loadClients();
//   }

//   Future<void> _loadClients() async {
//     final clients = await mysql.getClients();
//     setState(() {
//       clientSuggestions = clients;
//     });
//   }

//   Future<List<String>> _fetchFilteredNames(
//       String query, List<String> suggestions) async {
//     return suggestions
//         .where((name) => name.toLowerCase().contains(query.toLowerCase()))
//         .toList();
//   }

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   final List<Widget> _pages = [
//     GeneralInfo(selectedClient: '',),
//     Invoices(selectedClient: '',),
//     PostDate(),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(toolbarHeight: 1),
//       body: Column(
//         children: [
//           Divider(),
//           // Search function UI
//           InputDecorator(
//             decoration: InputDecoration(
//               labelText: 'Client', // Label for the Client section
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.end,
//               children: [
//                 Row(
//                   children: [
//                     Expanded(
//                       child: GestureDetector(
//                         onTap: () {
//                           if (!isClientSelected) {
//                             setState(() {
//                               isSearching = true;
//                               selectedClient = '';
//                             });
//                           }
//                         },
//                         child: AbsorbPointer(
//                           absorbing:
//                               isClientSelected, // Disable search if client is selected
//                           child: Opacity(
//                             opacity: isClientSelected
//                                 ? 0.5
//                                 : 1.0, // Adjust opacity if client is selected
//                             child: isSearching
//                                 ? Autocomplete<String>(
//                                     optionsBuilder: (TextEditingValue
//                                         textEditingValue) async {
//                                       if (textEditingValue.text.isEmpty) {
//                                         return const Iterable<String>.empty();
//                                       }
//                                       final filteredNames =
//                                           await _fetchFilteredNames(
//                                         textEditingValue.text,
//                                         clientSuggestions,
//                                       );
//                                       return filteredNames;
//                                     },
//                                     displayStringForOption: (String option) =>
//                                         option,
//                                     fieldViewBuilder: (context, controller,
//                                         focusNode, onFieldSubmitted) {
//                                       return TextField(
//                                         controller: controller,
//                                         focusNode: focusNode,
//                                         decoration: InputDecoration(
//                                           hintText: 'Search Client...',
//                                           border: InputBorder.none,
//                                           contentPadding: EdgeInsets.symmetric(
//                                               horizontal: 16.0),
//                                         ),
//                                       );
//                                     },
//                                     onSelected: (String selection) {
//                                       setState(() {
//                                         selectedClient = selection;
//                                         isClientSelected = true;
//                                         isSearching = false;
//                                       });
//                                     },
//                                   )
//                                 : Row(
//                                     children: [
//                                       Icon(Icons.search,
//                                           color: Colors.black, size: 30),
//                                       SizedBox(width: 8),
//                                       Text(
//                                         selectedClient.isEmpty
//                                             ? ''
//                                             : selectedClient,
//                                         style: TextStyle(fontSize: 16),
//                                       ),
//                                     ],
//                                   ),
//                           ),
//                         ),
//                       ),
//                     ),
//                     IconButton(
//                       onPressed: () {
//                         setState(() {
//                           clientController.clear();
//                           selectedClient = '';
//                           isClientSelected = false;
//                           isSearching = false;
//                         });
//                       },
//                       icon: Icon(Icons.refresh_sharp, color: Colors.black),
//                       iconSize: 24,
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           // Divider between search and the rest of the content
//           Divider(),

//           // Drawer and content in another Scaffold below the search function
//           Expanded(
//             child: Scaffold(
//               appBar: AppBar(),
//               drawer: Drawer(
//                 child: ListView(
//                   padding: EdgeInsets.zero,
//                   children: <Widget>[
//                     ListTile(
//                       leading: Icon(Icons.home),
//                       title: Text('General Info'),
//                       onTap: () {
//                         _onItemTapped(0);
//                         Navigator.pop(context); // Close the drawer
//                       },
//                     ),
//                     ListTile(
//                       leading: Icon(Icons.person),
//                       title: Text('Open Invoices'),
//                       onTap: () {
//                         _onItemTapped(1);
//                         Navigator.pop(context); // Close the drawer
//                       },
//                     ),
//                     ListTile(
//                       leading: Icon(Icons.settings),
//                       title: Text('Post Date'),
//                       onTap: () {
//                         _onItemTapped(2);
//                         Navigator.pop(context); // Close the drawer
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//               body: _pages[_selectedIndex], // Display selected page content
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }


// import 'package:client_info/formatdate.dart';
// import 'package:client_info/sql/mysql_services.dart';
// import 'package:flutter/material.dart';

// class Invoices extends StatefulWidget {
//   final String
//       selectedClient; // Pass the selected client to the invoices screen

//   Invoices({required this.selectedClient});

//   @override
//   _InvoicesState createState() => _InvoicesState();
// }

// class _InvoicesState extends State<Invoices> {
//   final MysqlService mysql = MysqlService(); // Instance of the Mysql class

//   bool isLoading = true; // To control loading state
//   List<Map<String, dynamic>> invoices = []; // List to hold fetched invoices

//   @override
//   void initState() {
//     super.initState();
//     if (widget.selectedClient.isNotEmpty) {
//       _loadInvoices();
//     }
//   }

//   @override
//   void didUpdateWidget(covariant Invoices oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     // If the selected client changes, reload the invoices
//     if (oldWidget.selectedClient != widget.selectedClient) {
//       _loadInvoices();
//     }
//   }

//   // Fetch invoices using the selected client's name
//   Future<void> _loadInvoices() async {
//     if (widget.selectedClient.isNotEmpty) {
//       setState(() {
//         isLoading = true;
//       });

//       try {
//         var invoiceData = await mysql.getInvoices(widget.selectedClient);

//         setState(() {
//           invoices = invoiceData;
//           isLoading = false;
//         });
//       } catch (e) {
//         setState(() {
//           isLoading = false;
//         });
//         // Show error message if an exception occurs
//         showDialog(
//           context: context,
//           builder: (context) => AlertDialog(
//             title: Text("Error"),
//             content: Text("Failed to load invoices. Please try again."),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                 },
//                 child: Text("OK"),
//               ),
//             ],
//           ),
//         );
//       }
//     } else {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (widget.selectedClient.isEmpty) {
//       return Center(child: Text("Please select a client to view invoices."));
//     }

//     if (isLoading) {
//       return Center(child: CircularProgressIndicator());
//     }

//     if (invoices.isEmpty) {
//       return Center(child: Text("No unpaid invoices found for this client."));
//     }

//     return ListView(
//       padding: EdgeInsets.all(8),
//       children: <Widget>[
//         // Invoices List
//         Card(
//           elevation: 5,
//           margin: EdgeInsets.symmetric(vertical: 8),
//           child: ExpansionTile(
//             title: Text('Invoices for ${widget.selectedClient}'),
//             subtitle: Text('Unpaid invoices'),
//             trailing: Icon(Icons.arrow_drop_down),
//             children: invoices.map((invoice) {
//               return ListTile(
//                 title: Text('Invoice Ref: ${invoice['ref']}'),
//                 subtitle: Text('Amount: \₱${invoice['amount']}'),
//                 trailing: Text('Due: ${formatDate(invoice['due_date'])}'),
//                 onTap: () {
//                   // Additional functionality, if required
//                 },
//               );
//             }).toList(),
//           ),
//         ),
//       ],
//     );
//   }
// }
