import 'dart:io';
import 'package:easy_learning/favorites/item.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
String favoriteTableName='favorite';
String historyTableName='history';
class DataBaseSql {
  final String idColumn='id';
  final String pathColumn='path';
  final String nameVideoColumn='name';
  final String timeVideoColumn='time';
  final String dateColumn='date';

  static Database? _database;

  Future<Database?> get database async {
    if (_database == null){
      _database = await initializedDatabase();
    }
    return _database;
  }
  Future<Database> initializedDatabase() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = directory.path + 'easylearning.db';

    var easyLearningDB = await openDatabase(path, version: 2, onCreate: createDatabase);
    return easyLearningDB;
  }
  Future createDatabase(Database db, int version) async {

    String createFavoriteTable='CREATE TABLE $favoriteTableName($idColumn INTEGER PRIMARY KEY AUTOINCREMENT,'
        '$nameVideoColumn TEXT,$pathColumn TEXT,$timeVideoColumn TEXT,$dateColumn TEXT )';

    String createHistoryTable='CREATE TABLE $historyTableName($idColumn INTEGER PRIMARY KEY AUTOINCREMENT,'
        '$nameVideoColumn TEXT,$pathColumn TEXT,$timeVideoColumn TEXT,$dateColumn TEXT )';

    await db.execute(createFavoriteTable);
    await db.execute(createHistoryTable);
    }

  Future<int> addItem(String table,Item item)async{
    var dbClint =await database;
    int result= await dbClint!.insert(table, item.toMap());
    return result;
  }
  Future<List> getAllItems(String table)async{
    var dbClint =await database;
    //String rwoQuery='SELECT * FROM $table';
    List result= await dbClint!.query(table);
    return result.toList();
  }

  Future<int?> getCount(String table)async{
    var dbClint =await database;
    String rwoQuery='SELECT COUNT(*) FROM $table';
    return Sqflite.firstIntValue(await dbClint!.rawQuery(rwoQuery));
  }

  Future<Item?> getOneItem(String table,String path)async{
    var dbClint =await database;
    //String rwoQuery='SELECT * FROM $table WHERE $pathColumn = $path';
    //var result= await dbClint!.rawQuery(rwoQuery);
    var result= await dbClint!.query(table,where: pathColumn,whereArgs: [path]);
    if(result.isEmpty)return null;
    return Item.fromMap(result.first);
  }

  Future<int> deleteItem(String table,int id)async{
    var dbClint =await database;
    int result= await dbClint!.delete(table,where: '$idColumn = ?',whereArgs: [id]);
    return result;
  }

  Future<int> deleteAll(String table)async{
    var dbClint =await database;
    int result= await dbClint!.delete(table);
    return result;
  }

  Future<int> updateItems(String table,Item item)async{
    var dbClint =await database;
    int result= await dbClint!.update(table,item.toMap(),where:'$idColumn = ?',whereArgs: [item.id]);
    return result;
  }

  Future<void> close()async{
    var dbClint = await database;
    await dbClint!.close();
  }
}