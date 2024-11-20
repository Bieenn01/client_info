import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Client Info App'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'General Info',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('General Info'),
              onTap: () {
                // Handle the navigation
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Open Invoices'),
              onTap: () {
                // Handle the navigation
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Post Date'),
              onTap: () {
                // Handle the navigation
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search functionality section
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Client',
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
                            // Placeholder for search functionality (you can add actual logic here)
                          },
                          child: AbsorbPointer(
                            absorbing: false,
                            child: Row(
                              children: [
                                Icon(Icons.search,
                                    color: Colors.black, size: 30),
                                SizedBox(width: 8),
                                Text(
                                  "Search Client",
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          // Reset search functionality
                        },
                        icon: Icon(Icons.refresh_sharp, color: Colors.black),
                        iconSize: 24,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Add more content below the search button
            Text(
              'Additional content can go here!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(10),
              color: Colors.blue.shade100,
              child: Text(
                'This is a container with some more content!',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
