import 'package:sqflite/sqflite.dart' as sql;
import 'package:flutter/foundation.dart';

class SQLHelper {
  //Tabella dati invio segnalazione
  static Future<void> createTables(sql.Database database) async {
    await database.execute("""CREATE TABLE IF NOT EXISTS sendingReportData(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        datetime STRING,
        address STRING,
        lat DECIMAL,
        lon DECIMAL,
        checkSendingReport INT,
        userID INT,
        intensitaOdore INT,
        durata INT,
        offensivita INT,
        tipoOdore INT,
        IDapp INT,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
      """);
  }

  static Future<void> createTablesUserData(sql.Database database) async {
    await database.execute("""CREATE TABLE userData(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        email STRING,
        userID INT
      )
      """);
  }

  //Update table
  static void onUpgrade(sql.Database database) {

      //database.execute("ALTER TABLE items ADD COLUMN user_id INT, ADD COLUMN intensita_odore INT, ADD COLUMN durata INT, ADD COLUMN offensivita INT, ADD COLUMN tipo_odore INT;");
    database.execute("ALTER TABLE sendingReportData ADD COLUMN IDapp INT;");
  }

// id: the id of a item
// title, description: name and description of your activity
// created_at: the time that the item was created. It will be automatically handled by SQLite

  static Future<sql.Database> db() async {
    return sql.openDatabase(
      'data_pozzuoli.db',
      version: 1,
      onCreate: (sql.Database database, int version) async {
       // await createTables(database);
        await createTablesUserData(database);
      },
    );
  }

  // Create new item (journal)
  static Future<int> createItem(String datetime, String address, double lat, double lon, int check_sending_report, int user_id, int intensita_odore, int durata, int offensivita, int tipo_odore, int id_app) async {
    final db = await SQLHelper.db();

    //bisogna salvare anche i dati dell intensita di odore ecc
    final data = {'datetime': datetime, 'address': address, 'lat': lat, 'lon': lon, 'checkSendingReport': check_sending_report, 'userID': user_id, 'intensitaOdore': intensita_odore, 'durata': durata, 'offensivita': offensivita, 'tipoOdore': tipo_odore, 'IDapp': id_app};
    final id = await db.insert('sendingReportData', data,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;
  }

  // Read all items (journals)
  static Future<List<Map<String, dynamic>>> getItems() async {
    final db = await SQLHelper.db();
    return db.query('sendingReportData', orderBy: "id");
  }

  // Read a single item by id
  // The app doesn't use this method but I put here in case you want to see it
  static Future<List<Map<String, dynamic>>> getItem(int id) async {
    final db = await SQLHelper.db();
    return db.query('sendingReportData', where: "id = ?", whereArgs: [id], limit: 1);
  }

  // Update an item by id
  static Future<int> updateItem(
      int id, String title, String? descrption) async {
    final db = await SQLHelper.db();

    final data = {
      'title': title,
      'description': descrption,
      'createdAt': DateTime.now().toString()
    };

    final result =
    await db.update('sendingReportData', data, where: "id = ?", whereArgs: [id]);
    return result;
  }

  static Future<int> update(
      String date) async {
    final db = await SQLHelper.db();

    final data = {
      'datetime': '17-03-2022 10:56:46'
    };

    final result =
    await db.update('sendingReportData', data, where: "datetime = ?", whereArgs: [date]);
    return result;
  }

  // Delete
  static Future<void> deleteItem(int id) async {
    final db = await SQLHelper.db();
    try {
      await db.delete("sendingReportData", where: "id = ?", whereArgs: [id]);
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
    }
  }

  static Future<void> deleteItem2() async {
    final db = await SQLHelper.db();
    try {
      await db.delete("sendingReportData");
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
    }
  }

  //Create datas of user logged
  static Future<int> createUserData(String email, int userId) async {
    final db = await SQLHelper.db();

    //bisogna salvare anche i dati dell intensita di odore ecc
    final data = {'email': email, 'userID': userId};
    final id = await db.insert('userData', data,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;
  }

  //Read datas from userData
  static Future<List<Map<String, dynamic>>> getUserData() async {
    final db = await SQLHelper.db();
    return db.query('userData', orderBy: "id");
  }

  //read check_sending_report by id_user e id_app
  static Future<List<Map<String, dynamic>>> getCheckSendingReportByID(userid) async {
    final db = await SQLHelper.db();
    //return db.query('sendingReportData', where: "userID = ? and IDapp = ?", whereArgs: [userid, id_app]);
    return db.query('sendingReportData', where: "userID = ?", whereArgs: [userid]);
  }


  static Future<void> deleteUserData(int id) async {
    final db = await SQLHelper.db();
    try {
      await db.delete("userData", where: "id = ?", whereArgs: [id]);
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
    }
  }


}