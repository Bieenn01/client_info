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

  Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    var connection = await mysql.getConnection(); // Method to get DB connection
    var results = await connection.query("""
      SELECT 
        c.name, o.type, o.delivery, o.finishtime, o.remarks, o.packs, 
        o.created, o.saved, o.total, ml.name AS source_location, mlc.name AS complete_location 
      FROM harlem_clientorders.order o 
      LEFT JOIN harlem_inventory.mainlocation ml ON ml.id = o.source_id 
      LEFT JOIN harlem_inventory.mainlocation mlc ON mlc.id = o.complete_id 
      LEFT JOIN harlem_client.client c ON c.id = o.client_id 
      WHERE o.id = ?
    """, [orderId]);

    if (results.isNotEmpty) {
      var row = results.first;
      return {
        'client_name': row[0],
        'type': row[1],
        'delivery': row[2],
        'finishtime': row[3],
        'remarks': row[4],
        'packs': row[5],
        'created': row[6],
        'saved': row[7],
        'total': row[8],
        'source_location': row[9],
        'complete_location': row[10],
      };
    } else {
      throw Exception('Order not found');
    }
  }

  Future<List<Map<String, dynamic>>> getProductDetails(String orderId) async {
    var connection = await mysql.getConnection();
    try {
      var results = await connection.query('''
        SELECT p.name, o.order_quantity, o.alotted_quantity, o.served_quantity,
               i.contents_box, o.price_box, o.total 
        FROM harlem_clientorders.order os 
        LEFT JOIN harlem_clientorders.orderdetails o ON o.order_id = os.id
        LEFT JOIN harlem_inventory.inventory i ON i.id = o.inventory_id
        LEFT JOIN harlem_products.product_main p ON p.id = o.product_id
        WHERE o.deleted = false AND os.id = ?
        ORDER BY o.datetime
      ''', [orderId]);

      List<Map<String, dynamic>> productDetails = [];
      for (var row in results) {
        productDetails.add({
          'name': row[0],
          'order_quantity': row[1],
          'alotted_quantity': row[2],
          'served_quantity': row[3],
          'contents_box': row[4],
          'price_box': row[5],
          'total': row[6],
        });
      }

      return productDetails;
    } catch (e) {
      print('Error fetching product details: $e');
      rethrow;
    } finally {
      await connection.close();
    }
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

  Future<List<Map<String, dynamic>>> getTransactionDetails(
      String paymentId) async {
    try {
      var conn = await mysql.getConnection();

      String query = '''
        SELECT c.name, t.datetime, py.date, py.ref, py.amount, t.amount, py.order_id
        FROM harlem_caccounts.transaction t
        LEFT JOIN harlem_caccounts.payable py ON py.id = t.payable_id
        LEFT JOIN harlem_client.client c ON c.id = py.client_id
        WHERE t.payment_id = ?;
      ''';

      var results = await conn.query(query, [paymentId]);

      List<Map<String, dynamic>> transactions = [];
      for (var row in results) {
        transactions.add({
          'name': row[0],
          'datetime': row[1],
          'payable_date': row[2],
          'ref': row[3],
          'payable_amount': row[4],
          'transaction_amount': row[5],
          'order_id': row[6],
        });
      }

      return transactions;
    } catch (e) {
      print('Error fetching transaction details: $e');
      throw Exception('Failed to fetch transaction details');
    }
  }

   Future<Map<String, dynamic>> getPaymentDetails(String paymentId) async {
    try {

      var conn = await mysql.getConnection();
      String query = '''
        SELECT p.type, p.dateclear, p.datetime, p.amount
        FROM harlem_caccounts.payments p
        WHERE p.id = ?;
      ''';

      var result = await conn.query(query, [paymentId]);

      if (result.isNotEmpty) {
        var row = result.first;
        return {
          'type': row[0],
          'dateclear': row[1],
          'datetime': row[2],
          'amount': row[3],
        };
      } else {
        return {};
      }
    } catch (e) {
      print('Error fetching payment details: $e');
      throw Exception('Failed to fetch payment details');
    }
  }
}

