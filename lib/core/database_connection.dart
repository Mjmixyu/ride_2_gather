// import 'package:mysql_client/mysql_client.dart';
//
// // this function creates a mySQL DB connection with the android-emulator as a host
// Future<MySQLConnection> createConnection() async {
//   final conn = await MySQLConnection.createConnection(
//     host: "10.0.2.2",
//     port: 42069,
//     userName: "root",
//     password: "",
//     databaseName: "ride2gather",
//     secure: false,
//   );
//   return conn;
// }
//
// Future<void> insertTestUser() async {
//   final conn = await createConnection();
//   await conn.connect();
//
//   // Insert dummy data
//   await conn.execute(
//     "INSERT INTO users (username, email, password_hash) VALUES (:username, :email, :password_hash)",
//     {
//       "username": "testuser",
//       "email": "testuser@example.com",
//       "password_hash": "1234567890abcdef",
//     },
//   );
//
//   print("✅ Test user inserted successfully");
//
//   await conn.close();
// }
