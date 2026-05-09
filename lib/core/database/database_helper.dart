import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "TaskPulse.db";
  static const _databaseVersion = 1;

  static const tableTasks = 'tasks';

  static const columnId = 'id';
  static const columnTitle = 'title';
  static const columnDescription = 'description';
  static const columnCategory = 'category';
  static const columnTags = 'tags';
  static const columnStatus = 'status';
  static const columnPriority = 'priority';
  static const columnDueDate = 'dueDate';
  static const columnCreatedAt = 'createdAt';
  static const columnUpdatedAt = 'updatedAt';

  // Make this a singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableTasks (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnTitle TEXT NOT NULL,
        $columnDescription TEXT,
        $columnCategory TEXT,
        $columnTags TEXT,
        $columnStatus TEXT NOT NULL DEFAULT 'in_progress',
        $columnPriority TEXT NOT NULL DEFAULT 'medium',
        $columnDueDate TEXT,
        $columnCreatedAt TEXT NOT NULL,
        $columnUpdatedAt TEXT NOT NULL
      )
    ''');
  }
}
