// ignore_for_file: avoid_print

import 'package:surrealdb/surrealdb.dart';

/// Example demonstrating basic usage of the SurrealDB Dart SDK
/// Note: This example uses print statements for demonstration purposes
void main() async {
  // Create a new SurrealDB instance
  final db = Surreal();

  try {
    // Connect to a SurrealDB instance
    print('Connecting to SurrealDB...');
    await db.connect('ws://localhost:8000/rpc');
    print('Connected successfully!');

    // Select namespace and database
    print('\nSelecting namespace and database...');
    await db.use(namespace: 'test', database: 'test');

    // Authenticate
    print('Authenticating...');
    await db.signin({
      'username': 'root',
      'password': 'root',
    });
    print('Authenticated successfully!');

    // Create a table reference
    final personTable = Table('person');

    // Create a new person record
    print('\nCreating a person record...');
    final created = await db.create(
      personTable,
      {
        'name': 'John Doe',
        'age': 30,
        'email': 'john@example.com',
      },
    );
    print('Created: $created');

    // Select all people
    print('\nSelecting all people...');
    final people = await db.select<List>(personTable);
    print('People: $people');

    // Create a person with a specific RecordId
    print('\nCreating person with specific ID...');
    final johnId = RecordId('person', 'john');
    final john = await db.create(
      johnId,
      {
        'name': 'John Smith',
        'age': 25,
        'email': 'johnsmith@example.com',
      },
    );
    print('Created John: $john');

    // Update using merge
    print('\nUpdating John\'s age...');
    final updated = await db.update(johnId).merge({
      'age': 26,
    });
    print('Updated: $updated');

    // Select a specific person
    print('\nSelecting John...');
    final selectedJohn = await db.select(johnId);
    print('John: $selectedJohn');

    // Execute a raw query
    print('\nExecuting raw query...');
    final queryResult = await db.query(
      'SELECT * FROM person WHERE age > \$minAge',
      {'minAge': 20},
    );
    print('Query result: ${queryResult.raw}');

    // Create a graph relation
    print('\nCreating a relation...');
    final janeId = RecordId('person', 'jane');
    await db.create(
      janeId,
      {
        'name': 'Jane Doe',
        'age': 28,
      },
    );

    final relation = await db.relate(
      johnId,
      'knows',
      janeId,
      {
        'since': '2020-01-01',
      },
    );
    print('Created relation: $relation');

    // Example with RecordId using List as id
    print('\nCreating person with List-based ID...');
    final compositeId = RecordId('person', ['user', '123']);
    final compositeUser = await db.create(
      compositeId,
      {
        'name': 'Composite User',
        'age': 35,
      },
    );
    print('Created with composite ID: $compositeUser');
    print('Composite ID string: $compositeId');

    // Delete a record
    print('\nDeleting a person...');
    final deleted = await db.delete(johnId);
    print('Deleted: $deleted');

    // Get session info
    print('\nGetting session info...');
    final info = await db.info();
    print('Session info: $info');
  } catch (e) {
    print('Error: $e');
  } finally {
    // Close the connection
    print('\nClosing connection...');
    await db.close();
    print('Connection closed.');
  }
}
