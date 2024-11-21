import 'package:client_info/sql/mysql.dart';
import 'package:mysql1/mysql1.dart';

class MysqlService {
  final Mysql mysql = Mysql();

  // Fetch user data based on ID
  Future<Map<String, dynamic>> getUserData(int userId) async {
    var conn = await mysql.getConnection();

    var results = await conn.query(
      'SELECT name, email, age FROM users WHERE id = ?',
      [userId],
    );

    Map<String, dynamic> userData = {};

    if (results.isNotEmpty) {
      var row = results.first;
      userData = {
        'name': row[0],
        'email': row[1],
        'age': row[2],
      };
    }

    await conn.close();
    return userData;
  }

  // Fetch all clients from the database
  Future<List<String>> getClients() async {
    var conn = await mysql.getConnection();
    var results =
        await conn.query('SELECT name FROM harlem_client.client ORDER BY name');
    List<String> clients = [];
    for (var row in results) {
      clients.add(row[0] as String); // Assuming 'name' is the first column
    }
    await conn.close();
    return clients;
  }

  // Fetch all products from the database
  Future<List<String>> getProducts() async {
    var conn = await mysql.getConnection();
    var results = await conn
        .query('SELECT name FROM harlem_products.product_main ORDER BY name');
    List<String> products = [];
    for (var row in results) {
      products.add(row[0] as String); // Assuming 'name' is the first column
    }
    await conn.close();
    return products;
  }

  Future<Map<String, dynamic>?> getClientDetails(String sClient) async {
    var conn = await mysql.getConnection();
    var results = await conn.query('''
    SELECT c.term, c.shortaddress, c.completeaddress, h.name 
    FROM harlem_client.client c
    LEFT JOIN harlem_client.handler h ON h.id = c.handler_id
    LEFT JOIN harlem_client.class cl ON cl.id = c.class_id
    LEFT JOIN harlem_client.account_type ct ON ct.id = c.account_type_id
    WHERE c.id = (
      SELECT id FROM harlem_client.client WHERE name = ?
    )
  ''', [sClient]);

    Map<String, dynamic>? clientDetails;
    if (results.isNotEmpty) {
      var row = results.first;
      clientDetails = {
        'term': row[0],
        'shortaddress': row[1],
        'completeaddress': row[2],
        'handler_name': row[3],
      };
    }

    await conn.close();
    return clientDetails;
  }

  Future<List<Map<String, dynamic>>> getInvoices(String clientName) async {
    var conn = await mysql.getConnection();
    String query = '''
    select id, ref, date, balance, order_id, amount, collection_date, due_date
    from harlem_caccounts.payable
    where client_id = (select id from harlem_client.client where name = ?)
    AND clear = false
    ORDER BY date, ref
    ''';

    // Execute the query and return the result
    var result = await conn.query(query, [clientName]);
    return result
        .map((row) => {
              'id': row[0],
              'ref': row[1],
              'date': row[2],
              'balance': row[3],
              'order_id': row[4],
              'amount': row[5],
              'collection_date': row[6],
              'due_date': row[7],
            })
        .toList();
  }

    // This method will fetch post date payments for the selected client
  Future<List<Map<String, dynamic>>> getPostDates(String selectedClient) async {
    try {
      // Open the database connection
      var conn = await mysql.getConnection();

      // Prepare the query to fetch post date payments
      String query = '''
        SELECT id, type, dateclear, amount 
        FROM harlem_caccounts.payments 
        WHERE client_id = (
          SELECT id 
          FROM harlem_client.client 
          WHERE name = ? 
        ) 
        AND valid = true 
        AND clear = false 
        ORDER BY dateclear;
      ''';

      // Execute the query and get the results
      var results = await conn.query(query, [selectedClient]);

      // Convert results into a List of Maps
      List<Map<String, dynamic>> postDates = [];
      for (var row in results) {
        postDates.add({
          'id': row[0],
          'type': row[1],
          'dateclear': row[2],
          'amount': row[3],
        });
      }

      // Close the connection
      await conn.close();

      return postDates;
    } catch (e) {
      print('Error fetching post dates: $e');
      return [];
    }
  }
}

