# SurrealDB.js Library Architecture Documentation

## Overview

This document describes the architecture and implementation details of the original [surrealdb.js](https://github.com/surrealdb/surrealdb.js) library, which serves as the reference for the Dart implementation.

## Project Structure

The surrealdb.js library is a monorepo organized using Bun and Turbo, containing multiple packages:

```
surrealdb.js/
├── packages/
│   ├── sdk/          # Core JavaScript/TypeScript SDK
│   ├── node/         # Node.js-specific engine (embedded database)
│   ├── wasm/         # WebAssembly engine (browser embedded)
│   └── tests/        # Test suite
├── demo/             # Demo applications
└── scripts/          # Build and publish scripts
```

## Core Architecture

### 1. Main Components

#### 1.1 Surreal Class (`src/api/surreal.ts`)
The main entry point for the SDK. Key responsibilities:
- **Connection Management**: Connect to remote or embedded SurrealDB instances
- **Engine Registration**: Support for multiple engine types (WebSocket, HTTP, Embedded)
- **Session Inheritance**: Extends `Session` class for authentication and namespace management
- **Query Interface**: Extends `Queryable` class for database operations

Key methods:
```typescript
class Surreal extends Queryable {
  constructor(options?: SurrealOptions)
  connect(url: string): Promise<void>
  close(): Promise<void>
  // Inherits: signin, signup, use, info, etc. from Session
  // Inherits: query, create, select, update, delete, etc. from Queryable
}
```

#### 1.2 Session Class (`src/api/session.ts`)
Handles authentication and session state management:
- **Authentication Methods**:
  - `signin(credentials)`: Authenticate with username/password or token
  - `signup(credentials)`: Create new user account
  - `authenticate(token)`: Use existing JWT token
  - `invalidate()`: Invalidate current session
- **Namespace/Database Selection**:
  - `use({ namespace, database })`: Switch context
- **Session Information**:
  - `info()`: Get current session/user information

#### 1.3 Queryable Class (`src/api/queryable.ts`)
Provides the query interface for database operations:

**CRUD Operations**:
- `create<T>(resource, data)`: Create new records
- `select<T>(resource)`: Query records
- `update<T>(resource)`: Update records  
- `merge<T>(resource, data)`: Merge data into records
- `patch<T>(resource, patches)`: Apply JSON patches
- `delete<T>(resource)`: Delete records

**Query Methods**:
- `query(sql, vars)`: Execute raw SurrealQL queries
- `queryRaw(sql, vars)`: Execute query returning raw results

**Live Queries**:
- `live<T>(table, diff?)`: Subscribe to real-time changes
- `kill(queryUuid)`: Stop a live query

**Relations**:
- `relate(from, relation, to, data)`: Create graph relations

**Transactions**:
- `transaction()`: Begin transaction scope

### 2. Engine System

The SDK uses an extensible engine system to support different connection types:

#### 2.1 Engine Interface (`src/engine/`)
All engines implement a common interface:
```typescript
interface Engine {
  connect(url: string): Promise<void>
  disconnect(): Promise<void>
  rpc(method: string, params: unknown[]): Promise<unknown>
  // Additional methods for live queries, transactions, etc.
}
```

#### 2.2 Engine Types

**Remote Engines**:
- **WebSocket Engine**: Default for `ws://` and `wss://` protocols
  - Real-time bidirectional communication
  - Supports live queries natively
  - JSON-RPC 2.0 protocol
  
- **HTTP Engine**: For `http://` and `https://` protocols
  - Request/response based
  - Live queries via polling or SSE
  - RESTful endpoints

**Embedded Engines**:
- **WASM Engine** (`@surrealdb/wasm`): Browser embedded database
  - Runs in WebAssembly
  - IndexedDB storage: `indxdb://demo`
  - In-memory: `mem://`
  
- **Node.js Engine** (`@surrealdb/node`): Server-side embedded
  - Native addon
  - RocksDB storage: `rocksdb://path/to/db`
  - SurrealKV storage: `surrealkv://path/to/db`
  - In-memory: `mem://`

### 3. Data Serialization

#### 3.1 CBOR Encoding (`src/cbor/`)
SurrealDB uses CBOR (Concise Binary Object Representation) for efficient data serialization:
- Custom CBOR tags for SurrealDB-specific types
- Bidirectional encoding/decoding
- Handles complex data structures

#### 3.2 Protocol Communication
- **JSON-RPC 2.0**: Used for WebSocket communication
- **HTTP REST**: Traditional REST endpoints
- **Binary Protocol**: CBOR-based for efficiency

### 4. Data Types (`src/types/` and `src/value/`)

SurrealDB provides specialized data types:

#### 4.1 Core Types
```typescript
// Record identifier
class RecordId<T = string> {
  constructor(table: string | Table, id: string | number | object)
  toString(): string
  toJSON(): string
}

// Table reference
class Table {
  constructor(name: string)
  toString(): string
}

// Duration
class Duration {
  constructor(value: string)
  // Supports: ns, us, ms, s, m, h, d, w, y
}

// UUID
class Uuid {
  constructor(value?: string)
  toString(): string
}

// Geometry types
class GeometryPoint {
  constructor(coordinates: [number, number])
}

class GeometryLine {
  constructor(coordinates: [number, number][])
}

// And more geometry types...
```

#### 4.2 Special Value Types
- **Future**: Represents future/computed values
- **Range**: Numeric or record ranges
- **Decimal**: High-precision decimals
- **Bound**: Boundary values (included/excluded)

### 5. Query Builder System (`src/query/`)

Provides type-safe query construction:
```typescript
// Builder methods return chainable query objects
const query = db
  .select<Person>(personTable)
  .where("age > 18")
  .limit(10);

// Execute query
const results = await query;
```

### 6. Controller System (`src/controller/`)

Manages internal state and coordination:
- **Connection State**: Track connection status
- **Request Queue**: Handle concurrent requests
- **Live Query Registry**: Manage active subscriptions
- **Error Recovery**: Reconnection logic

### 7. Error Handling (`src/errors.ts`)

Custom error classes for different scenarios:
```typescript
class SurrealDbError extends Error {}
class ConnectionError extends SurrealDbError {}
class QueryError extends SurrealDbError {}
class AuthenticationError extends SurrealDbError {}
class EngineError extends SurrealDbError {}
// etc.
```

## Key Features

### 1. Connection and Authentication

#### Connection Flow:
```typescript
const db = new Surreal();

// Connect to remote instance
await db.connect("wss://cloud.surrealdb.com");

// Or connect to embedded
await db.connect("mem://");

// Select namespace and database
await db.use({
  namespace: "test",
  database: "test"
});

// Authenticate
await db.signin({
  username: "root",
  password: "root",
});
```

#### Authentication Methods:
- **Root/Namespace/Database Users**: System-level authentication
- **Scope Users**: Application-level authentication with custom signup logic
- **Token-based**: JWT token authentication

### 2. Query Execution

#### Type-safe Query Builders:
```typescript
// Create
const created = await db.create<Person>(personTable, {
  name: "John",
  age: 30
});

// Select
const people = await db.select<Person>(personTable);

// Update with merge
await db.update<Person>(recordId).merge({ age: 31 });

// Delete
await db.delete(recordId);
```

#### Raw Queries:
```typescript
const results = await db.query(
  "SELECT * FROM person WHERE age > $minAge",
  { minAge: 18 }
);
```

### 3. Live Queries (Real-time Subscriptions)

WebSocket-based real-time data synchronization:
```typescript
// Subscribe to changes
const subscription = await db.live<Person>(personTable);

// Listen to events
for await (const { action, value } of subscription) {
  if (action === "CREATE") {
    console.log("New person:", value);
  } else if (action === "UPDATE") {
    console.log("Updated person:", value);
  } else if (action === "DELETE") {
    console.log("Deleted person:", value);
  }
}

// Cleanup
await subscription.close();
```

### 4. Transactions

Atomic operations support:
```typescript
const tx = await db.transaction();

try {
  await tx.create("account", { balance: 100 });
  await tx.update(accountId).merge({ balance: 200 });
  await tx.commit();
} catch (e) {
  await tx.cancel();
  throw e;
}
```

### 5. Graph Relations

Create and query graph relationships:
```typescript
// Create relation
await db.relate(
  new RecordId("person", "john"),
  "knows",
  new RecordId("person", "jane"),
  { since: "2020-01-01" }
);

// Query with graph traversal
const friends = await db.query(
  "SELECT * FROM person:john->knows->person"
);
```

## Protocol Details

### WebSocket JSON-RPC 2.0 Protocol

**Request Format**:
```json
{
  "id": "unique-request-id",
  "method": "create",
  "params": ["person", {"name": "John", "age": 30}]
}
```

**Response Format**:
```json
{
  "id": "unique-request-id",
  "result": {
    "id": "person:xyz",
    "name": "John",
    "age": 30
  }
}
```

**Error Format**:
```json
{
  "id": "unique-request-id",
  "error": {
    "code": -32000,
    "message": "Error message"
  }
}
```

### RPC Methods

Common RPC methods used by the SDK:
- `ping`: Check connection
- `use`: Set namespace/database
- `signup`: Create new user
- `signin`: Authenticate user
- `authenticate`: Use token
- `invalidate`: End session
- `create`: Create records
- `select`: Query records
- `update`: Update records
- `merge`: Merge data
- `patch`: Apply patches
- `delete`: Delete records
- `query`: Execute SurrealQL
- `live`: Start live query
- `kill`: Stop live query

## Implementation Patterns

### 1. Promise-based Async API
All operations return Promises for async/await support:
```typescript
await db.connect(url);
const result = await db.create(table, data);
```

### 2. Method Chaining
Query builders support fluent interface:
```typescript
const result = await db
  .select<Person>(table)
  .where("age > 18")
  .limit(10);
```

### 3. Type Safety
Heavy use of TypeScript generics for type inference:
```typescript
const person = await db.select<Person>(personTable);
// person has type Person[]
```

### 4. Event-driven Live Queries
Async iterators for streaming updates:
```typescript
for await (const event of subscription) {
  // Handle event
}
```

### 5. Error Handling
Custom error classes with detailed context:
```typescript
try {
  await db.query("INVALID SQL");
} catch (error) {
  if (error instanceof QueryError) {
    console.error("Query failed:", error.message);
  }
}
```

## Multi-Runtime Support

The SDK is designed to work across multiple JavaScript runtimes:

### Browser
- WebSocket and HTTP engines
- WASM embedded engine
- IndexedDB persistence

### Node.js
- WebSocket and HTTP engines  
- Native embedded engine
- RocksDB/SurrealKV persistence

### Deno
- Full compatibility
- Works with Deno's standard library

### Bun
- Native support
- Optimized performance

## Security Considerations

1. **Token Management**: Secure JWT token handling
2. **TLS/SSL**: Support for secure WebSocket (wss://) and HTTPS
3. **Input Validation**: Parameter sanitization for queries
4. **Error Messages**: Avoid leaking sensitive information
5. **Credential Storage**: No automatic credential persistence

## Performance Optimizations

1. **Connection Pooling**: Reuse WebSocket connections
2. **Request Batching**: Batch multiple operations
3. **CBOR Encoding**: Binary format for efficiency
4. **Lazy Initialization**: On-demand resource loading
5. **Streaming Results**: Process large datasets incrementally

## Migration from v1 to v2

Key changes in SDK v2:
- New engine system for embedded databases
- Improved TypeScript types
- Better query builder API
- Enhanced transaction support
- Simplified connection management

## References

- Official Documentation: https://surrealdb.com/docs/sdk/javascript
- GitHub Repository: https://github.com/surrealdb/surrealdb.js
- NPM Package: https://npmjs.com/package/surrealdb
- SurrealDB Protocol: https://surrealdb.com/docs/surrealdb/integration/rpc

## Summary

The surrealdb.js library provides a comprehensive, type-safe SDK for interacting with SurrealDB. Its architecture is based on:

1. **Extensible Engine System**: Support for remote and embedded databases
2. **Layered Class Design**: Session → Queryable → Surreal hierarchy
3. **Protocol Abstraction**: JSON-RPC over WebSocket/HTTP
4. **Type Safety**: Strong TypeScript typing throughout
5. **Real-time Support**: Native live query subscriptions
6. **Multi-runtime**: Works in browsers, Node.js, Deno, and Bun

This architecture provides a solid foundation for creating a Dart implementation that maintains feature parity while leveraging Dart's strengths in type safety and async programming.
